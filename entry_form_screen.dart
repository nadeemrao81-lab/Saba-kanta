// lib/screens/entry_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/weigh_record.dart';
import '../database/database_helper.dart';
import '../printing/print_service.dart';
import 'records_list_screen.dart';

class EntryFormScreen extends StatefulWidget {
  final WeighRecord? existingRecord; // null = new, non-null = edit
  const EntryFormScreen({super.key, this.existingRecord});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  // Controllers
  final _partyNameCtrl = TextEditingController();
  final _commodityCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _firstWeightCtrl = TextEditingController();
  final _secondWeightCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  // Calculated fields
  double _netWeight = 0;
  double _totalAmount = 0;
  int _serialNo = 1;

  bool _isSaving = false;
  bool _isSaved = false;
  WeighRecord? _savedRecord;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.existingRecord != null) {
      final r = widget.existingRecord!;
      _partyNameCtrl.text = r.partyName;
      _commodityCtrl.text = r.commodity;
      _driverCtrl.text = r.driverName;
      _vehicleCtrl.text = r.vehicleNo;
      _firstWeightCtrl.text = r.firstWeight.toString();
      _secondWeightCtrl.text = r.secondWeight.toString();
      _rateCtrl.text = r.ratePerMaund.toString();
      _serialNo = r.serialNo;
      _isSaved = true;
      _savedRecord = r;
      _recalculate();
    } else {
      _serialNo = await _db.getNextSerialNo();
      setState(() {});
    }
  }

  void _recalculate() {
    final first = double.tryParse(_firstWeightCtrl.text) ?? 0;
    final second = double.tryParse(_secondWeightCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    setState(() {
      _netWeight = (first - second).clamp(0, double.infinity);
      _totalAmount = _netWeight * rate;
    });
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final record = WeighRecord(
      id: widget.existingRecord?.id,
      serialNo: _serialNo,
      partyName: _partyNameCtrl.text.trim().toUpperCase(),
      commodity: _commodityCtrl.text.trim().toUpperCase(),
      driverName: _driverCtrl.text.trim().toUpperCase(),
      vehicleNo: _vehicleCtrl.text.trim().toUpperCase(),
      firstWeight: double.tryParse(_firstWeightCtrl.text) ?? 0,
      secondWeight: double.tryParse(_secondWeightCtrl.text) ?? 0,
      ratePerMaund: double.tryParse(_rateCtrl.text) ?? 0,
      date: DateFormat('dd-MMM-yy').format(now),
      time: DateFormat('hh:mm a').format(now),
    );

    int id;
    if (widget.existingRecord != null) {
      await _db.updateRecord(record);
      id = record.id!;
    } else {
      id = await _db.insertRecord(record);
    }

    final saved = await _db.getRecord(id);
    setState(() {
      _isSaving = false;
      _isSaved = true;
      _savedRecord = saved;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingRecord != null
              ? 'Record Updated Successfully!'
              : 'Record Saved Successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      // Auto-print preview after save
      if (saved != null) {
        await PrintService.showPrintPreview(context, saved);
      }
    }
  }

  void _clearForm() {
    _partyNameCtrl.clear();
    _commodityCtrl.clear();
    _driverCtrl.clear();
    _vehicleCtrl.clear();
    _firstWeightCtrl.clear();
    _secondWeightCtrl.clear();
    _rateCtrl.clear();
    setState(() {
      _netWeight = 0;
      _totalAmount = 0;
      _isSaved = false;
      _savedRecord = null;
    });
    _init();
  }

  @override
  void dispose() {
    _partyNameCtrl.dispose();
    _commodityCtrl.dispose();
    _driverCtrl.dispose();
    _vehicleCtrl.dispose();
    _firstWeightCtrl.dispose();
    _secondWeightCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SABA ISLAMI COMPUTERIZED KANTA',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3),
            ),
            Text(
              'Kabirwala Khanewal • Ph: 0300-6883781',
              style: TextStyle(fontSize: 10, color: Colors.blue[100]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'All Records',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RecordsListScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── SERIAL NO BANNER ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A5C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('S.No:',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      _serialNo.toString().padLeft(8, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    if (_isSaved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('SAVED',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── PARTY NAME ────────────────────────────────────
              _buildCard([
                _buildField(
                  controller: _partyNameCtrl,
                  label: 'Party Name',
                  icon: Icons.person,
                  isRequired: true,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _commodityCtrl,
                  label: 'Commodity',
                  icon: Icons.agriculture,
                  hint: 'e.g. MANGO, WHEAT, RICE',
                  isRequired: true,
                  textCapitalization: TextCapitalization.characters,
                ),
              ]),
              const SizedBox(height: 10),

              // ── VEHICLE ───────────────────────────────────────
              _buildCard([
                _buildField(
                  controller: _driverCtrl,
                  label: 'Driver Name',
                  icon: Icons.person_pin,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _vehicleCtrl,
                  label: 'Vehicle No',
                  icon: Icons.local_shipping,
                  hint: 'e.g. RAKSHA / MHB-123',
                  textCapitalization: TextCapitalization.characters,
                ),
              ]),
              const SizedBox(height: 10),

              // ── WEIGHTS ───────────────────────────────────────
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: _buildWeightField(
                        controller: _firstWeightCtrl,
                        label: '1st Weight (Mnds)',
                        color: Colors.blue[700]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWeightField(
                        controller: _secondWeightCtrl,
                        label: '2nd Weight (Mnds)',
                        color: Colors.orange[700]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // NET WEIGHT (read-only, auto-calculated)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Weight (Maunds)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _netWeight.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // ── RATE & TOTAL ──────────────────────────────────
              _buildCard([
                _buildField(
                  controller: _rateCtrl,
                  label: 'Rate Per Maund (Rs.)',
                  icon: Icons.currency_rupee,
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  onChanged: (_) => _recalculate(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A5C).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF1A3A5C), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount (Rs.)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _totalAmount.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A5C),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // ── ACTION BUTTONS ────────────────────────────────
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRecord,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Icon(_isSaved ? Icons.update : Icons.save),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : _isSaved
                                ? 'Update'
                                : 'Save & Print',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.add),
                      label: const Text('New',
                          style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A3A5C),
                        side: const BorderSide(
                            color: Color(0xFF1A3A5C), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── PRINT BUTTONS (shown after save) ─────────────
              if (_isSaved && _savedRecord != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _printBtn(
                        icon: Icons.preview,
                        label: 'Preview',
                        color: Colors.purple,
                        onTap: () => PrintService.showPrintPreview(
                            context, _savedRecord!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _printBtn(
                        icon: Icons.print,
                        label: 'Print',
                        color: Colors.blue[700]!,
                        onTap: () => PrintService.printWithSystemDialog(
                            context, _savedRecord!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _printBtn(
                        icon: Icons.picture_as_pdf,
                        label: 'Export PDF',
                        color: Colors.red[700]!,
                        onTap: () =>
                            PrintService.exportToPdf(context, _savedRecord!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _printBtn(
                        icon: Icons.bluetooth,
                        label: 'BT Print',
                        color: Colors.indigo,
                        onTap: () => PrintService.printViaBluetooth(
                            context, _savedRecord!),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isRequired = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A3A5C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF1A3A5C), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      onChanged: (v) {
        _recalculate();
        onChanged?.call(v);
      },
    );
  }

  Widget _buildWeightField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
          style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: color),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 2),
            ),
            suffixText: 'M',
            suffixStyle: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
          onChanged: (_) => _recalculate(),
        ),
      ],
    );
  }

  Widget _printBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
