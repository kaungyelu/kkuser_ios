import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../database/time_database_helper.dart';
import '../database/sale_database_helper.dart';
import '../database/name_database_helper.dart';

class WeekScreen extends StatefulWidget {
  final String timeStr;

  const WeekScreen({super.key, required this.timeStr});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final TimeDatabaseHelper _timeDbHelper = TimeDatabaseHelper();
  final SaleDatabaseHelper _saleDbHelper = SaleDatabaseHelper();
  final NameDatabaseHelper _nameDbHelper = NameDatabaseHelper();

  bool _isLoading = true;
  String _decryptedHtml = "";
  static const String _encryptionKey = "kyl2016";

  @override
  void initState() {
    super.initState();
    _loadAndDecryptBalFile();
  }

  Future<void> _loadAndDecryptBalFile() async {
    try {
      ByteData data = await rootBundle.load("assets/web/week.bal");
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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _decryptedHtml = "<html><body><h2>Week Report Load Error</h2><p>${e.toString()}</p></body></html>";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("အပတ်စဉ် အစီရင်ခံစာချုပ်"),
        backgroundColor: const Color(0xFF2F855A),
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
                // getAllTimes
                controller.addJavaScriptHandler(handlerName: 'getAllTimes', callback: (args) async {
                  final data = await _timeDbHelper.getAllTimes();
                  return jsonEncode(data);
                });

                // getAllNames
                controller.addJavaScriptHandler(handlerName: 'getAllNames', callback: (args) async {
                  final names = await _nameDbHelper.getAllNames();
                  return jsonEncode(names);
                });

                // getSalesByKey
                controller.addJavaScriptHandler(handlerName: 'getSalesByKey', callback: (args) async {
                  if (args.isNotEmpty) {
                    final sales = await _saleDbHelper.getSalesByKey(args[0].toString());
                    return jsonEncode(sales);
                  }
                  return "[]";
                });

                // getSalesForMultipleKeys (ပွဲစဉ်ပေါင်းစုံကို Loop ပတ်ပြီး စာရင်းချုပ်ထုတ်ပေးခြင်း Logic အပြည့်အစုံ)
                controller.addJavaScriptHandler(handlerName: 'getSalesForMultipleKeys', callback: (args) async {
                  if (args.isNotEmpty) {
                    try {
                      List<dynamic> keysArray = jsonDecode(args[0].toString());
                      List<dynamic> allSales = [];

                      for (var key in keysArray) {
                        final sales = await _saleDbHelper.getSalesByKey(key.toString());
                        allSales.addAll(sales);
                      }
                      return jsonEncode(allSales);
                    } catch (e) {
                      return "[]";
                    }
                  }
                  return "[]";
                });

                controller.addJavaScriptHandler(handlerName: 'finishActivity', callback: (args) {
                  Navigator.pop(context);
                });
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(source: """
                  if (typeof initWeekData === 'function') {
                    initWeekData();
                  }
                """);
              },
            ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F855A))),
                  SizedBox(height: 15),
                  Text("Loading Week Report Interface...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}