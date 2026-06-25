import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../database/time_database_helper.dart';
import '../database/sale_database_helper.dart';
import '../database/name_database_helper.dart';

class ResultScreen extends StatefulWidget {
  final String timeStr;

  const ResultScreen({super.key, required this.timeStr});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TimeDatabaseHelper _timeDbHelper = TimeDatabaseHelper();
  final SaleDatabaseHelper _saleDbHelper = SaleDatabaseHelper();
  final NameDatabaseHelper _nameDbHelper = NameDatabaseHelper();

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

  void _parseDateTime() {
    if (widget.timeStr.contains(" - ")) {
      List<String> parts = widget.timeStr.split(" - ");
      if (parts.length >= 2) {
        _selectedDate = parts[0].trim();
        _selectedTime = parts[1].trim();
      }
    }
  }

  Future<void> _loadAndDecryptBalFile() async {
    try {
      ByteData data = await rootBundle.load("assets/web/result.bal");
      Uint8List balBytes = data.buffer.asUint8List();
      List<int> keyBytes = utf8.encode(_encryptionKey);
      List<int> decryptedBytes = [];

      if (balBytes.length > 16) {
        for (int i = 16; i < balBytes.length; i++) {
          decryptedBytes.add(balBytes[i] ^ keyBytes[(i - 16) % keyBytes.length]);
        }
        _decryptedHtml = utf8.decode(decryptedBytes, allowMalformed: true);
      }

      if (!_decryptedHtml.contains("<!DOCTYPE html>")) {
        decryptedBytes = [];
        for (int i = 0; i < balBytes.length; i++) {
          decryptedBytes.add(balBytes[i] ^ keyBytes[i % keyBytes.length]);
        }
        _decryptedHtml = utf8.decode(decryptedBytes, allowMalformed: true);
      }

      _injectUrlParamsFix();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _decryptedHtml = "<html><body><h2>Result Load Error</h2><p>${e.toString()}</p></body></html>";
        _isLoading = false;
      });
    }
  }

  void _injectUrlParamsFix() {
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
        title: const Text("ရလဒ်ထည့်သွင်းရန်"),
        backgroundColor: const Color(0xFFB7791F),
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
                controller.addJavaScriptHandler(handlerName: 'getSelectedDate', callback: (args) => _selectedDate);
                controller.addJavaScriptHandler(handlerName: 'getSelectedTime', callback: (args) => _selectedTime);
                
                // getTimesByDateAndTime
                controller.addJavaScriptHandler(handlerName: 'getTimesByDateAndTime', callback: (args) async {
                  final data = await _timeDbHelper.getTimeByDateTime(_selectedDate, _selectedTime);
                  return jsonEncode(data);
                });

                // getAllTimes
                controller.addJavaScriptHandler(handlerName: 'getAllTimes', callback: (args) async {
                  final data = await _timeDbHelper.getAllTimes();
                  return jsonEncode(data);
                });

                // updatePno (Upsert Logic အသုံးပြုခြင်း)
                controller.addJavaScriptHandler(handlerName: 'updatePno', callback: (args) async {
                  if (args.length >= 3) {
                    String date = args[0].toString();
                    String time = args[1].toString();
                    String pno = args[2].toString();
                    bool success = await _timeDbHelper.updatePno(date, time, pno);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PNO သိမ်းဆည်းပြီးပါပြီ"), backgroundColor: Colors.green),
                      );
                    }
                    return success;
                  }
                  return false;
                });

                // getSalesByKey
                controller.addJavaScriptHandler(handlerName: 'getSalesByKey', callback: (args) async {
                  if (args.isNotEmpty) {
                    final sales = await _saleDbHelper.getSalesByKey(args[0].toString());
                    return jsonEncode(sales);
                  }
                  return "[]";
                });

                // getAllNames
                controller.addJavaScriptHandler(handlerName: 'getAllNames', callback: (args) async {
                  final names = await _nameDbHelper.getAllNames();
                  return jsonEncode(names);
                });

                controller.addJavaScriptHandler(handlerName: 'finishActivity', callback: (args) {
                  Navigator.pop(context);
                });
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(source: """
                  if (typeof initResultData === 'function') {
                    initResultData('$_selectedDate', '$_selectedTime');
                  }
                """);
              },
            ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB7791F))),
                  SizedBox(height: 15),
                  Text("Loading Result Interface...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}