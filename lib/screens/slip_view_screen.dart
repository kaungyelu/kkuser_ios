import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/sale_database_helper.dart';
import 'slip_all_screen.dart';

class SlipViewScreen extends StatefulWidget {
  final String timeStr;

  const SlipViewScreen({super.key, required this.timeStr});

  @override
  State<SlipViewScreen> createState() => _SlipViewScreenState();
}

class _SlipViewScreenState extends State<SlipViewScreen> {
  final SaleDatabaseHelper _saleDbHelper = SaleDatabaseHelper();
  
  List<Map<String, dynamic>> _allSales = [];
  List<Map<String, dynamic>> _filteredSales = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedKey = "";

  @override
  void initState() {
    super.initState();
    _parseKey();
    _loadSalesData();
  }

  void _parseKey() {
    if (widget.timeStr.contains(" - ")) {
      List<String> parts = widget.timeStr.split(" - ");
      if (parts.length >= 2) {
        _selectedKey = "${parts[0].trim()} ${parts[1].trim()}";
      }
    } else {
      _selectedKey = widget.timeStr.trim();
    }
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    final data = await _saleDbHelper.getSalesByKey(_selectedKey);
    setState(() {
      _allSales = data;
      _filteredSales = data;
      _isLoading = false;
    });
  }

  // မူရင်းအတိုင်း Live ရှာဖွေပေးမည့် စနစ် (ဝယ်သူအမည် သို့မဟုတ် ဂဏန်းစာသားဖြင့် ရှာနိုင်ပါသည်)
  void _filterSales(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredSales = _allSales;
      } else {
        _filteredSales = _allSales.where((sale) {
          String name = (sale['name'] ?? "").toString().toLowerCase();
          String numbers = (sale['numbers'] ?? "").toString().toLowerCase();
          String id = (sale['id'] ?? "").toString();
          
          return name.contains(_searchQuery) || 
                 numbers.contains(_searchQuery) || 
                 id == _searchQuery;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ဘောက်ချာများ ရှာဖွေရန်"),
        backgroundColor: const Color(0xFF4A5568),
        actions: [
          // ဘောက်ချာအားလုံး စာရင်းချုပ်ကြည့်ရန် ခလုတ်
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SlipAllScreen(timeStr: widget.timeStr),
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: _filterSales,
              decoration: InputDecoration(
                labelText: "အမည် သို့မဟုတ် ဂဏန်းဖြင့် ရှာရန်...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          
          // Table Header
          Container(
            color: const Color(0xFF4A5568),
            padding: const EdgeInsets.all(10),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("စဉ်", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text("အမည်", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text("နံပါတ် / ထိုးကြေး", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("စုစုပေါင်း", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          
          // Data List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A5568))))
                : _filteredSales.isEmpty
                    ? const Center(child: Text("မည်သည့်ဘောက်ချာမျှ မတွေ့ပါ", style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.builder(
                        itemCount: _filteredSales.length,
                        itemBuilder: (context, index) {
                          final item = _filteredSales[index];
                          
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 1, child: Text("${index + 1}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))),
                                Expanded(flex: 2, child: Text(item['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("နံပါတ်: ${item['numbers']}", style: const TextStyle(color: Colors.blueAccent, fontSize: 13)),
                                      Text("ထိုးကြေး: ${item['bets']}", style: const TextStyle(color: Colors.green, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    double.parse(item['total_amount'].toString()).toStringAsFixed(0),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}