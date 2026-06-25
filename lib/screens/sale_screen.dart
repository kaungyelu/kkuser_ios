import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../database/sale_database_helper.dart';
import '../database/name_database_helper.dart';

class SaleScreen extends StatefulWidget {
  final String timeStr; // Dashboard ကသယ်လာပြီး AScreen ကတစ်ဆင့် ပို့ပေးလိုက်သော "date - time" စာသား

  const SaleScreen({super.key, required this.timeStr});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final SaleDatabaseHelper _saleDbHelper = SaleDatabaseHelper();
  final NameDatabaseHelper _nameDbHelper = NameDatabaseHelper();
  
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String _decryptedHtml = "";
  
  String _selectedDate = "";
  String _selectedTime = "";
  
  static const String _encryptionKey = "kyl2016";

  @override
  void initState() {
    super.initState();
    _parseDateTime();
    _loadAndDecryptBalFile();
  }

  // Android ကဲ့သို့ " - " ကိုဖြတ်ပြီး Date နှင့် Time ခွဲထုတ်ခြင်း Logic
  void _parseDateTime() {
    if (widget.timeStr.contains(" - ")) {
      List<String> parts = widget.timeStr.split(" - ");
      if (parts.length >= 2) {
        _selectedDate = parts[0].trim();
        _selectedTime = parts[1].trim();
      }
    }
  }

  // မူရင်း Android က XOR Cipher Decryption Algorithm အတိအကျ
  Future<void> _loadAndDecryptBalFile() async {
    try {
      // assets/web/sale.bal ဖိုင်ကို Bytes အဖြစ်ဖတ်ခြင်း
      ByteData data = await rootBundle.load("assets/web/sale.bal");
      Uint8List balBytes = data.buffer.asUint8List();
      List<int> keyBytes = utf8.encode(_encryptionKey);
      List<int> decryptedBytes = [];

      // Method 1: Android တုန်းကအတိုင်း 16-byte BAL Header ကိုကျော်ပြီး ဖြည်ခြင်း
      if (balBytes.length > 16) {
        for (int i = 16; i < balBytes.length; i++) {
          decryptedBytes.add(balBytes[i] ^ keyBytes[(i - 16) % keyBytes.length]);
        }
        _decryptedHtml = utf8.decode(decryptedBytes, allowMalformed: true);
      }

      // 16-byte ကျော်လို့ အဆင်မပြေပါက တစ်ဖိုင်လုံးကို တိုက်ရိုက် XOR ဖြည်ခြင်း (Fallback Method)
      if (!_decryptedHtml.contains("<!DOCTYPE html>")) {
        decryptedBytes = [];
        for (int i = 0; i < balBytes.length; i++) {
          decryptedBytes.add(balBytes[i] ^ keyBytes[i % keyBytes.length]);
        }
        _decryptedHtml = utf8.decode(decryptedBytes, allowMalformed: true);
      }

      // Android အတိုင်း HTML ထဲက getUrlParams နှင့် Initialization Functions များကို Inject လုပ်ပြီး အစားထိုးပြင်ဆင်ခြင်း
      _injectAndroidBridgeFixes();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _decryptedHtml = "<html><body><h2>Sale Load Error</h2><p>${e.toString()}</p></body></html>";
        _isLoading = false;
      });
    }
  }

  void _injectAndroidBridgeFixes() {
    // JavaScript က Native ခေါ်တဲ့နေရာမှာ Android.function() အစား window.flutter_inappwebview.callHandler() ကို ပြောင်းသုံးနိုင်ရန် HTML ကို အစားထိုးခြင်း
    _decryptedHtml = _decryptedHtml.replaceFirst(
      "function getUrlParams() {",
      """function getUrlParams() {
          const params = {};
          params.date = '$_selectedDate';
          params.time = '$_selectedTime';
          params.key = '$_selectedDate $_selectedTime';
          return params;
      }
      function _dummy() {"""
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("အရောင်းမျက်နှာပြင်"),
        backgroundColor: const Color(0xFF4C51BF),
      ),
      body: Stack(
        children: [
          if (!_isLoading)
            InAppWebView(
              initialData: InAppWebViewInitialData(
                data: _decryptedHtml,
                mimeType: "text/html",
                encoding: "utf-8",
                baseUrl: WebUri("file:///android_asset/"),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                
                // ====================================================
                // JAVASCRIPT HANDLERS (Android JavascriptInterface နေရာ)
                // ====================================================

                // ၁။ getSelectedDate
                controller.addJavaScriptHandler(handlerName: 'getSelectedDate', callback: (args) {
                  return _selectedDate;
                });

                // ၂။ getSelectedTime
                controller.addJavaScriptHandler(handlerName: 'getSelectedTime', callback: (args) {
                  return _selectedTime;
                });

                // ၃။ loadUsers (Name Database မှ လူစာရင်းကို JSON အဖြစ် လှမ်းပေးခြင်း)
                controller.addJavaScriptHandler(handlerName: 'loadUsers', callback: (args) async {
                  return await _nameDbHelper.getAllUsersAsJson();
                });

                // ၄။ saveSale (HTML က ပို့လိုက်သော JSON ကို Native SQLite ထဲ သိမ်းခြင်း)
                controller.addJavaScriptHandler(handlerName: 'saveSale', callback: (args) async {
                  if (args.isNotEmpty) {
                    try {
                      Map<String, dynamic> json = jsonDecode(args[0]);
                      bool success = await _saleDbHelper.saveSale(
                        json['key'],
                        json['name'],
                        json['com'],
                        json['za'],
                        json['numbers'].toString(),
                        json['bets'].toString(),
                        double.parse(json['total_amount'].toString()),
                      );
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ သိမ်းဆည်းပြီးပါပြီ"), backgroundColor: Colors.green),
                        );
                      }
                      return success;
                    } catch (e) {
                      return false;
                    }
                  }
                  return false;
                });

                // ၅။ getSalesData (လက်ရှိပွဲစဉ်၏ အရောင်းစာရင်းများကို HTML သို့ ပြန်ပေးခြင်း)
                controller.addJavaScriptHandler(handlerName: 'getSalesData', callback: (args) async {
                  final sales = await _saleDbHelper.getSalesByKey("$_selectedDate $_selectedTime");
                  return jsonEncode(sales);
                });

                // ၆။ deleteSale (စာရင်းဖျက်ခြင်း)
                controller.addJavaScriptHandler(handlerName: 'deleteSale', callback: (args) async {
                  if (args.isNotEmpty) {
                    int id = int.parse(args[0].toString());
                    return await _saleDbHelper.deleteSale(id);
                  }
                  return false;
                });

                // ၇။ finishActivity (Activity ပိတ်ပြီး ပြန်ထွက်ခြင်း)
                controller.addJavaScriptHandler(handlerName: 'finishActivity', callback: (args) {
                  Navigator.pop(context);
                });
              },
              onLoadStop: (controller, url) async {
                // DOM တက်လာပါက HTML ထဲက initSaleData() ကို လှမ်းခေါ်ပြီး Date/Time တွန်းထည့်ပေးခြင်း
                await controller.evaluateJavascript(source: """
                  if (typeof initSaleData === 'function') {
                    initSaleData('$_selectedDate', '$_selectedTime');
                  }
                  if (document.getElementById('activeTimeDisplay')) {
                    document.getElementById('activeTimeDisplay').textContent = '$_selectedDate $_selectedTime';
                  }
                """);
              },
            ),
          
          // Loader Page
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C51BF))),
                  SizedBox(height: 15),
                  Text("Loading Sale Interface...", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}