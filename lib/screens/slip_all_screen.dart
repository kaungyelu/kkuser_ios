import 'package:flutter/material.dart';
import '../database/sale_database_helper.dart';

class SlipAllScreen extends StatefulWidget {
  final String timeStr;

  const SlipAllScreen({super.key, required this.timeStr});

  @override
  State<SlipAllScreen> createState() => _SlipAllScreenState();
}

class _SlipAllScreenState extends State<SlipAllScreen> {
  final SaleDatabaseHelper _saleDbHelper = SaleDatabaseHelper();
  
  double _totalAmountSum = 0.0;
  int _totalSlipsCount = 0;
  bool _isLoading = true;
  String _selectedKey = "";

  @override
  void initState() {
    super.initState();
    _parseKey();
    _calculateGrandTotal();
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

  // မူရင်းအလုပ်လုပ်ပုံအတိုင်း စုစုပေါင်းထိုးကြေးပမာဏအားလုံးကို ဆွဲထုတ်တွက်ချက်ခြင်း Logic
  Future<void> _calculateGrandTotal() async {
    setState(() => _isLoading = true);
    
    double totalAmount = await _saleDbHelper.getTotalAmountByKey(_selectedKey);
    int slipCount = await _saleDbHelper.getSlipCount(_selectedKey);
    
    setState(() {
      _totalAmountSum = totalAmount;
      _totalSlipsCount = slipCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("စုစုပေါင်း စာရင်းချုပ်ကြည့်ရန်"),
        backgroundColor: const Color(0xFF2D3748),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D3748))))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.timeStr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 30),
                  
                  // Slip Count Card
                  Card(
                    elevation: 3,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text("ဘောက်ချာ စုစုပေါင်း အရေအတွက်", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 10),
                          Text(
                            "$_totalSlipsCount စောင်",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Grand Total Amount Card
                  Card(
                    elevation: 4,
                    color: const Color(0xFFEDF2F7),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        children: [
                          const Text("စုစုပေါင်း အဝယ်/အရောင်း ထိုးကြေးငွေ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black54)),
                          const SizedBox(height: 12),
                          Text(
                            "${_totalAmountSum.toStringAsFixed(0)} ကျပ်",
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Refresh Button
                  ElevatedButton.icon(
                    onPressed: _calculateGrandTotal,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("စာရင်း ပြန်လည်တွက်ချက်မည်", style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3748),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}