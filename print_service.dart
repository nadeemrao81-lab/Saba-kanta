// lib/printing/print_service.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../models/weigh_record.dart';
import 'receipt_generator.dart';

class PrintService {
  // ── SYSTEM PRINT (HP LaserJet, Canon LBP via Android print service) ──
  static Future<void> printWithSystemDialog(
      BuildContext context, WeighRecord record) async {
    final pdfBytes = await ReceiptGenerator.generateReceipt(record);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Receipt_${record.formattedSerialNo}',
      format: const PdfPageFormat(
        148 * PdfPageFormat.mm,
        210 * PdfPageFormat.mm,
      ),
    );
  }

  // ── PRINT PREVIEW ────────────────────────────────────────────────────
  static Future<void> showPrintPreview(
      BuildContext context, WeighRecord record) async {
    final pdfBytes = await ReceiptGenerator.generateReceipt(record);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes, record: record),
      ),
    );
  }

  // ── EXPORT TO PDF ────────────────────────────────────────────────────
  static Future<void> exportToPdf(
      BuildContext context, WeighRecord record) async {
    final pdfBytes = await ReceiptGenerator.generateReceipt(record);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'SABA_KANTA_${record.formattedSerialNo}.pdf',
    );
  }

  // ── BLUETOOTH PRINT ──────────────────────────────────────────────────
  // ESC/POS raw bytes for thermal/bluetooth printers
  static Future<void> printViaBluetooth(
      BuildContext context, WeighRecord record) async {
    // Note: Bluetooth printing requires flutter_bluetooth_serial
    // Show dialog to select device
    showDialog(
      context: context,
      builder: (_) => BluetoothPrintDialog(record: record),
    );
  }
}

// ── PDF PREVIEW SCREEN ────────────────────────────────────────────────
class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final WeighRecord record;

  const PdfPreviewScreen(
      {super.key, required this.pdfBytes, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${record.formattedSerialNo}'),
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (_) async => pdfBytes,
                name: 'Receipt_${record.formattedSerialNo}',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share/Export PDF',
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'SABA_KANTA_${record.formattedSerialNo}.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: const PdfPageFormat(
          148 * PdfPageFormat.mm,
          210 * PdfPageFormat.mm,
        ),
      ),
    );
  }
}

// ── BLUETOOTH PRINT DIALOG ────────────────────────────────────────────
class BluetoothPrintDialog extends StatefulWidget {
  final WeighRecord record;
  const BluetoothPrintDialog({super.key, required this.record});

  @override
  State<BluetoothPrintDialog> createState() => _BluetoothPrintDialogState();
}

class _BluetoothPrintDialogState extends State<BluetoothPrintDialog> {
  bool _isScanning = false;
  final List<Map<String, String>> _devices = [];
  String _status = 'Tap Scan to find Bluetooth printers';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bluetooth, color: Color(0xFF1A3A5C)),
          const SizedBox(width: 8),
          const Text('Bluetooth Printer'),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status,
                style:
                    const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            if (_devices.isEmpty && !_isScanning)
              const Text('No devices found',
                  style: TextStyle(color: Colors.grey))
            else
              ...(_devices.map((d) => ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(d['name'] ?? 'Unknown'),
                    subtitle: Text(d['address'] ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Sending to ${d['name']}...')),
                      );
                    },
                  ))),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isScanning
              ? null
              : () async {
                  setState(() {
                    _isScanning = true;
                    _status = 'Scanning...';
                    _devices.clear();
                  });
                  // Simulate scan - in real app use flutter_bluetooth_serial
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() {
                    _isScanning = false;
                    _status = 'Scan complete. Select a printer:';
                    // Real implementation: populate from Bluetooth scan
                  });
                },
          icon: _isScanning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.search),
          label: Text(_isScanning ? 'Scanning...' : 'Scan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3A5C),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
