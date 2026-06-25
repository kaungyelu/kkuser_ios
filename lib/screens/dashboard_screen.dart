import 'package:flutter/material.dart';
import '../database/time_database_helper.dart';
import 'add_time_screen.dart';
import 'a_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TimeDatabaseHelper _timeDbHelper = TimeDatabaseHelper();
  List<Map<String, dynamic>> _timesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // ဒေတာဘေ့စ်မှ ပွဲစဉ်အချိန်များ ဆွဲထုတ်ခြင်း
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final data = await _timeDbHelper.getAllTimes();
    setState(() {
      _timesList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ပွဲစဉ်ဇယား (Dashboard)"),
        backgroundColor: const Color(0xFF667EEA),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA))))
          : _timesList.isEmpty
              ? const Center(
                  child: Text(
                    "မည်သည့်ပွဲစဉ်မျှ မရှိသေးပါ။\nညာဘက်အောက်က '+' ကိုနှိပ်ပြီး အချိန်အသစ်ထည့်ပါဗျာ။",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _timesList.length,
                  itemBuilder: (context, index) {
                    final item = _timesList[index];
                    String displayStr = "${item['date']}  -  ${item['time']}";
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: Color(0xFF667EEA), size: 28),
                        title: Text(
                          displayStr,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          // ပွဲစဉ်ကို နှိပ်လိုက်ပါက နေ့စွဲနှင့် အချိန်ကို သယ်ဆောင်ပြီး Menu (A_Screen) သို့ သွားခြင်း
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AScreen(selectedTimeStr: displayStr),
                            ),
                          ).then((_) => _loadDashboardData()); // ပြန်လာလျှင် ဒေတာပြန် Refresh လုပ်ရန်
                        },
                      ),
                    );
                  },
                ),
      // အချိန်အသစ်ထည့်မည့် အပေါင်းခလုတ် (FAB)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF667EEA),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTimeScreen()),
          ).then((_) => _loadDashboardData()); // ပြန်လာလျှင် ဒေတာပြန် Refresh လုပ်ရန်
        },
      ),
    );
  }
}