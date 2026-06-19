// lib/printing/receipt_generator.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/weigh_record.dart';

class ReceiptGenerator {
  static Future<Uint8List> generateReceipt(WeighRecord record) async {
    final pdf = pw.Document();

    // A5 size: 148mm × 210mm
    const pageFormat = PdfPageFormat(
      148 * PdfPageFormat.mm,
      210 * PdfPageFormat.mm,
      marginAll: 10 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── HEADER ──────────────────────────────────────────
              pw.Text(
                'SABA ISLAMI COMPUTERIZED KANTA',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown700,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Kabirwala Khanewal . Ph . No. 0300-6883781 .',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.black),
              pw.SizedBox(height: 6),

              // ── FIELDS TABLE ─────────────────────────────────────
              _buildFieldRow('S.No', record.formattedSerialNo),
              pw.SizedBox(height: 3),
              _buildFieldRow('Party Name', record.partyName),
              pw.SizedBox(height: 3),
              _buildFieldRow('Commodity', record.commodity),
              pw.SizedBox(height: 3),
              _buildFieldRow('Driver', record.driverName),
              pw.SizedBox(height: 3),
              _buildFieldRow('Vehicle No', record.vehicleNo),
              pw.SizedBox(height: 10),

              // ── DATE & TIME (right side) ─────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Date',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(record.date,
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Time',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(record.time,
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── WEIGHT SECTION ───────────────────────────────────
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('1st Weight',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          '${record.firstWeight.toStringAsFixed(0)} M',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('2nd Weight',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          '${record.secondWeight.toStringAsFixed(0)}',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Net Weight',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          '${record.netWeight.toStringAsFixed(0)} M',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── PRICE / RATE / TOTAL ─────────────────────────────
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Text('Price  Rs. ',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    record.ratePerMaund.toStringAsFixed(0),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Spacer(),
                  pw.Text('Mnds 40 Kg.',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.Spacer(),
                  pw.Text('Kgs',
                      style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Text('Total Amount  Rs. ',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    record.totalAmount.toStringAsFixed(2),
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 6),

              // ── FOOTER ──────────────────────────────────────────
              pw.Text(
                'Thank You - شکریہ',
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildFieldRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 70,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        pw.Text(
          value.isEmpty ? '-' : value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
