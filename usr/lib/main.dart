import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const TaliKhataApp());
}

class TaliKhataApp extends StatelessWidget {
  const TaliKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'টালি খাতা',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansBengali',
      ),
      home: const TaliKhataHome(),
    );
  }
}

class LedgerEntry {
  final String date;
  final String type; // 'credit' or 'debit'
  final double amount;
  final String note;

  LedgerEntry({
    required this.date,
    required this.type,
    required this.amount,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'type': type,
        'amount': amount,
        'note': note,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        date: json['date'],
        type: json['type'],
        amount: json['amount'].toDouble(),
        note: json['note'],
      );
}

class TaliKhataHome extends StatefulWidget {
  const TaliKhataHome({super.key});

  @override
  State<TaliKhataHome> createState() => _TaliKhataHomeState();
}

class _TaliKhataHomeState extends State<TaliKhataHome> {
  List<LedgerEntry> ledger = [];
  String selectedType = 'credit';
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  double balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ledgerJson = prefs.getString('taliKhata');
    if (ledgerJson != null) {
      final List<dynamic> decoded = json.decode(ledgerJson);
      setState(() {
        ledger = decoded.map((item) => LedgerEntry.fromJson(item)).toList();
        _updateBalance();
      });
    }
  }

  Future<void> _saveLedger() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(ledger.map((e) => e.toJson()).toList());
    await prefs.setString('taliKhata', encoded);
  }

  void _updateBalance() {
    balance = ledger.fold(0.0, (sum, entry) {
      return entry.type == 'credit' ? sum + entry.amount : sum - entry.amount;
    });
  }

  void _addEntry() {
    final String amountText = amountController.text.trim();
    final String note = noteController.text.trim();

    if (amountText.isEmpty) {
      _showAlert('সঠিক পরিমাণ দিন! (সংখ্যা লিখুন)');
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showAlert('সঠিক পরিমাণ দিন! (সংখ্যা লিখুন)');
      return;
    }

    final String date = DateFormat('dd/MM/yyyy', 'bn').format(DateTime.now());

    setState(() {
      ledger.insert(
        0,
        LedgerEntry(
          date: date,
          type: selectedType,
          amount: amount,
          note: note,
        ),
      );
      _updateBalance();
    });

    _saveLedger();
    amountController.clear();
    noteController.clear();
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  void _exportCSV() {
    if (ledger.isEmpty) {
      _showAlert('কোনো এন্ট্রি নেই!');
      return;
    }

    // For web/mobile export functionality, you'd need additional packages
    // like csv or file_saver. For now, showing a placeholder message.
    _showAlert('CSV এক্সপোর্ট ফিচার শীঘ্রই আসছে!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf0f8ff), Color(0xFFe6f3ff)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '📓 টালি খাতা',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e3a8a),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Type selector
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFf9fafb),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFdddddd), width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      items: const [
                        DropdownMenuItem(
                          value: 'credit',
                          child: Text('💰 পেলাম (+)'),
                        ),
                        DropdownMenuItem(
                          value: 'debit',
                          child: Text('💸 দিলাম (-)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Amount input
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'টাকার পরিমাণ লিখুন (যেমন: 500)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFdddddd), width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onSubmitted: (_) => _addEntry(),
                  ),
                  const SizedBox(height: 8),
                  // Note input
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'বিবরণ লিখুন (যেমন: দোকান থেকে কেনাকাটা)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFdddddd), width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Add button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10b981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: _addEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '➕ এন্ট্রি যোগ করুন',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Balance display
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf3f4f6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'মোট ব্যালেন্স: ৳ ${NumberFormat('#,##0.00', 'bn').format(balance)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? const Color(0xFF059669) : const Color(0xFFdc2626),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ledger table
                  if (ledger.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFe5e7eb)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      '📅 তারিখ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      '🔄 প্রকার',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      '💵 পরিমাণ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      '📝 বিবরণ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Table rows
                          ...ledger.map((entry) {
                            return Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFe5e7eb)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        entry.date,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        entry.type == 'credit' ? '💰 পেলাম' : '💸 দিলাম',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        '৳ ${NumberFormat('#,##0', 'bn').format(entry.amount)}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        entry.note.isEmpty ? '-' : entry.note,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Export button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8b5cf6), Color(0xFF7c3aed)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: _exportCSV,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '📤 CSV এক্সপোর্ট করুন (Excel-এ খুলুন)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ডেটা আপনার মোবাইলে সেভ থাকবে। ব্রাউজার বন্ধ করলেও ঠিক আছে!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}