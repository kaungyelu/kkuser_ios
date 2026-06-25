import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/time_database_helper.dart';
import '../database/sale_database_helper.dart';
import 'a_screen.dart';
import 'main_screen.dart';
import 'dashboard_screen.dart';

class SetScreen extends StatefulWidget {
  const SetScreen({super.key});

  @override
  State<SetScreen> createState() => _SetScreenState();
}

class _SetScreenState extends State<SetScreen> {
  final TimeDatabaseHelper _timeDbHelper = TimeDatabaseHelper();
  final SaleDatabaseHelper _saleDbHelper = SaleDatabaseHelper();

  bool _inputBoxVisible = false;
  bool _isLoading = false;
  String _errorMessage = "";
  String _successMessage = "";

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  List<Map<String, dynamic>> _timesData = [];
  final Set<int> _selectedItems = {};
  bool _isSelectAllChecked = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _loadTimesFromDatabase();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadTimesFromDatabase() async {
    final data = await _timeDbHelper.getAllTimes();
    setState(() {
      _timesData = data;
      _isSelectAllChecked = _selectedItems.isNotEmpty && _selectedItems.length == _timesData.length;
    });
  }

  Future<bool> _isNetworkAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    // connectivity_plus 6.x ဗားရှင်းတွင် List ပြန်ပေးသဖြင့် အောက်ပါအတိုင်းစစ်ပါသည်
    return connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;
  }

  Future<void> _saveTimeEntry() async {
    String dateValue = _dateController.text.trim();
    String timeValue = _timeController.text.trim().toUpperCase();

    setState(() {
      _errorMessage = "";
      _successMessage = "";
    });

    if (dateValue.isEmpty || timeValue.isEmpty) {
      _showError("အားလုံး ဖြည့်စွက်ပေးပါ");
      return;
    }

    if (!timeValue.endsWith("AM") && !timeValue.endsWith("PM")) {
      _showError('အချိန်ကို AM/PM ပုံစံဖြင့် ထည့်ပါ (e.g., "10:30 AM")');
      return;
    }

    bool success = await _timeDbHelper.insertTime(dateValue, timeValue);
    if (success) {
      _showSuccess("ပွဲစဉ်အချိန်ကို အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ။");
      setState(() {
        _inputBoxVisible = false;
        _timeController.clear();
      });
      _loadTimesFromDatabase();
    } else {
      _showError("သိမ်းဆည်းရာတွင် အမှားဖြစ်နေပါသည်။");
    }
  }

  Future<bool> _verifyLicenseWithSupabase() async {
    if (!await _isNetworkAvailable()) {
      _showError("အင်တာနက်ဖွင့်ပါ\nInternet connection required for deletion");
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    String licenseKey = prefs.getString("verified_license") ?? "";

    if (licenseKey.isEmpty) {
      _handleLicenseFailure();
      return false;
    }

    setState(() => _isLoading = true);

    try {
      const supabaseUrl = "https://vldipmmskaagcrtutvhq.supabase.co";
      const supabaseKey = "sb_publishable_-e5cxrndOj_1hpDVUcgzGg_qZtVxoAX";
      String urlString = "$supabaseUrl/rest/v1/licenses?license_key=eq.$licenseKey&select=status";

      final response = await http.get(
        Uri.parse(urlString),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['status'] == 'ok') {
          return true;
        }
      }
      _handleLicenseFailure();
      return false;
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("လိုင်းမကောင်းပါ\nServer connection failed");
      return false;
    }
  }

  void _handleLicenseFailure() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    }
  }

  void _startSingleDelete(Map<String, dynamic> item) async {
    bool isLicenseValid = await _verifyLicenseWithSupabase();
    if (!isLicenseValid) return;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text('Are you sure you want to delete "${item['date']} ${item['time']}"?\nThis will also delete all related sales data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              String key = "${item['date']} ${item['time']}";
              
              await _saleDbHelper.deleteSalesByKey(key);
              await _timeDbHelper.deleteTime(item['id']);
              
              _selectedItems.remove(item['id']);
              _showSuccess("ဖျက်သိမ်းခြင်း အောင်မြင်ပါသည်။");
              _loadTimesFromDatabase();
              
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
              });
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _startBulkDelete() async {
    if (_selectedItems.isEmpty) return;

    bool isLicenseValid = await _verifyLicenseWithSupabase();
    if (!isLicenseValid) return;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Bulk Delete"),
        content: Text('Are you sure you want to delete ${_selectedItems.length} selected entries and all their related sales data?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              for (var item in _timesData) {
                if (_selectedItems.contains(item['id'])) {
                  String key = "${item['date']} ${item['time']}";
                  await _saleDbHelper.deleteSalesByKey(key);
                  await _timeDbHelper.deleteTime(item['id']);
                }
              }

              _selectedItems.clear();
              _showSuccess("ရွေးချယ်ထားသော ပွဲစဉ်များအားလုံး ဖျက်ပြီးပါပြီ။");
              _loadTimesFromDatabase();

              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
              });
            },
            child: const Text("Bulk Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _handleSelectAll(bool? checked) {
    if (checked == null) return;
    setState(() {
      _isSelectAllChecked = checked;
      if (_isSelectAllChecked) {
        for (var item in _timesData) {
          _selectedItems.add(item['id']);
        }
      } else {
        _selectedItems.clear();
      }
    });
  }

  void _showError(String msg) => setState(() => _errorMessage = msg);
  void _showSuccess(String msg) => setState(() => _successMessage = msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ပွဲစဉ်များ စီမံထိန်းချုပ်ရေး"),
        backgroundColor: const Color(0xFF667EEA),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA))))
        : Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Time", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA)),
                  onPressed: () => setState(() => _inputBoxVisible = !_inputBoxVisible),
                ),
                const SizedBox(height: 10),

                if (_inputBoxVisible)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          TextField(controller: _dateController, decoration: const InputDecoration(labelText: "ရက်စွဲ (DD/MM/YYYY)")),
                          TextField(controller: _timeController, decoration: const InputDecoration(labelText: "အချိန် (e.g., 04:30 PM)")),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _saveTimeEntry,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("Save Entry", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  ),

                if (_errorMessage.isNotEmpty) Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                if (_successMessage.isNotEmpty) Text(_successMessage, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 10),

                if (_timesData.isNotEmpty)
                  Row(
                    children: [
                      Checkbox(value: _isSelectAllChecked, onChanged: _handleSelectAll),
                      const Text("Select All"),
                      const Spacer(),
                      Text("${_selectedItems.length} Selected", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _selectedItems.isEmpty ? null : _startBulkDelete,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("Bulk Delete", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),

                Expanded(
                  child: _timesData.isEmpty
                    ? const Center(child: Text("မည်သည့်ပွဲစဉ်မျှ မရှိသေးပါ"))
                    : ListView.builder(
                        itemCount: _timesData.length,
                        itemBuilder: (context, index) {
                          final item = _timesData[index];
                          bool isChecked = _selectedItems.contains(item['id']);
                          String displayStr = "${item['date']} - ${item['time']}";

                          return Card(
                            elevation: 2,
                            child: ListTile(
                              leading: Checkbox(
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedItems.add(item['id']);
                                    } else {
                                      _selectedItems.remove(item['id']);
                                    }
                                    _isSelectAllChecked = _selectedItems.length == _timesData.length;
                                  });
                                },
                              ),
                              title: Text(displayStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _startSingleDelete(item),
                              ),
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => AScreen(selectedTimeStr: displayStr)),
                                );
                              },
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
    );
  }
}