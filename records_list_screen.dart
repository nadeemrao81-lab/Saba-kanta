// lib/screens/records_list_screen.dart

import 'package:flutter/material.dart';
import '../models/weigh_record.dart';
import '../database/database_helper.dart';
import '../printing/print_service.dart';
import 'entry_form_screen.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  final _db = DatabaseHelper();
  final _searchCtrl = TextEditingController();
  List<WeighRecord> _records = [];
  List<WeighRecord> _filtered = [];
  bool _isLoading = true;
  String _searchMode = 'party'; // 'party' or 'vehicle'

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _db.getAllRecords();
    setState(() {
      _records = records;
      _filtered = records;
      _isLoading = false;
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _filtered = _records);
      return;
    }
    List<WeighRecord> result;
    if (_searchMode == 'party') {
      result = await _db.searchByPartyName(query);
    } else {
      result = await _db.searchByVehicleNo(query);
    }
    setState(() => _filtered = result);
  }

  Future<void> _deleteRecord(WeighRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
            'Delete record #${record.formattedSerialNo} for ${record.partyName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && record.id != null) {
      await _db.deleteRecord(record.id!);
      _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Record deleted'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        title: const Text(
          'All Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                // Search mode toggle
                Row(
                  children: [
                    _searchModeBtn('By Party Name', 'party'),
                    const SizedBox(width: 8),
                    _searchModeBtn('By Vehicle No', 'vehicle'),
                  ],
                ),
                const SizedBox(height: 8),
                // Search field
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _searchMode == 'party'
                        ? 'Search party name...'
                        : 'Search vehicle no...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white54),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: _search,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A3A5C)))
          : _filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No records found',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${_filtered.length} record${_filtered.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            'Total: Rs. ${_filtered.fold(0.0, (s, r) => s + r.totalAmount).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5C),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) =>
                            _buildRecordCard(_filtered[i]),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const EntryFormScreen()),
          );
          _loadRecords();
        },
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _searchModeBtn(String label, String mode) {
    final selected = _searchMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchMode = mode;
          _searchCtrl.clear();
          _filtered = _records;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1A3A5C) : Colors.white70,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(WeighRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A5C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${record.formattedSerialNo}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.partyName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  record.date,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Info row
            Row(
              children: [
                _infoChip(Icons.agriculture, record.commodity),
                const SizedBox(width: 8),
                if (record.vehicleNo.isNotEmpty)
                  _infoChip(Icons.local_shipping, record.vehicleNo),
              ],
            ),
            const SizedBox(height: 8),
            // Weight row
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weightCol('1st Wt', record.firstWeight, Colors.blue),
                  _divider(),
                  _weightCol(
                      '2nd Wt', record.secondWeight, Colors.orange),
                  _divider(),
                  _weightCol('Net Wt', record.netWeight, Colors.green),
                  _divider(),
                  _weightCol('Total Rs.',
                      record.totalAmount, Colors.red,
                      isCurrency: true),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                _actionBtn(
                  icon: Icons.preview,
                  label: 'Preview',
                  color: Colors.purple,
                  onTap: () =>
                      PrintService.showPrintPreview(context, record),
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  icon: Icons.print,
                  label: 'Print',
                  color: Colors.blue[700]!,
                  onTap: () => PrintService.printWithSystemDialog(
                      context, record),
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  icon: Icons.edit,
                  label: 'Edit',
                  color: Colors.orange[700]!,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EntryFormScreen(existingRecord: record),
                      ),
                    );
                    _loadRecords();
                  },
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red[700]!,
                  onTap: () => _deleteRecord(record),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _weightCol(String label, double value, Color color,
      {bool isCurrency = false}) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          isCurrency
              ? value.toStringAsFixed(0)
              : value.toStringAsFixed(0),
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        if (!isCurrency)
          const Text('M',
              style: TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _divider() => Container(
      height: 30, width: 1, color: Colors.grey[300]);

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
