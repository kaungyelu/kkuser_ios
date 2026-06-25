import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String deviceId;
  final String generatedKey;

  const VerificationScreen({
    super.key,
    required this.deviceId,
    required this.generatedKey,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _licenseController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = "";
  bool _isError = false;

  Future<bool> _isNetworkAvailable() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult.isNotEmpty && connectivityResult.first != ConnectivityResult.none;
  }

  Future<void> _checkLicenseOnline() async {
    String inputKey = _licenseController.text.trim();
    if (inputKey.isEmpty) {
      _showMsg("လိုင်စင်ကီး ထည့်သွင်းပါ", true);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Connecting to server...";
      _isError = false;
    });

    if (!await _isNetworkAvailable()) {
      _showMsg("အင်တာနက်ဖွင့်ပါ\nInternet connection required", true);
      return;
    }

    try {
      const supabaseUrl = "https://vldipmmskaagcrtutvhq.supabase.co";
      const supabaseKey = "sb_publishable_-e5cxrndOj_1hpDVUcgzGg_qZtVxoAX";
      
      String urlString = "$supabaseUrl/rest/v1/licenses?license_key=eq.$inputKey&select=status";
      
      final response = await http.get(
        Uri.parse(urlString),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        if (data.isEmpty) {
          _showMsg("လိုင်စင် ဝယ်ယူထားခြင်းမရှိပါ", true);
          return;
        }

        String status = data[0]['status'] ?? "";
        if (status == "ok") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("verified_license", inputKey);
          
          _showMsg("✅ License Verified Successfully!", false);
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            }
          });
        } else {
          _showMsg("လိုင်စင် သက်တမ်းကုန်ဆုံးနေပါသည်", true);
        }
      } else {
        _showMsg("Server Error: ${response.statusCode}", true);
      }
    } catch (e) {
      _showMsg("လိုင်းမကောင်းပါ\nConnection failed: ${e.toString()}", true);
    }
  }

  void _showMsg(String msg, bool isErr) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _statusMessage = msg;
      _isError = isErr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("License Verification"),
        backgroundColor: const Color(0xFF667EEA),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text("Your Device ID:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            SelectableText(widget.deviceId, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter License Key',
                hintText: 'Paste your license key here',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkLicenseOnline,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Verify & Activate", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 30),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _isError ? Colors.red : Colors.green,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}