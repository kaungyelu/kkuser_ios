import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../database/sale_database_helper.dart';

class BuyScreen extends StatefulWidget {
  final String timeStr;

  const BuyScreen({super.key, required this.timeStr});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final SaleDatabaseHelper _saleDbHelper = SaleDatabaseHelper();
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
      ByteData data = await rootBundle.load("assets/web/buy.bal");
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
        _decryptedHtml = "<html><body><h2>Buy Load Error</h2><p>${e.toString()}</p></body></html>";
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
        title: const Text("အဝယ်မျက်နှာပြင်"),
        backgroundColor: const Color(0xFF2B6CB0),
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
                
                controller.addJavaScriptHandler(handlerName: 'getSalesData', callback: (args) async {
                  final sales = await _saleDbHelper.getSalesByKey("$_selectedDate $_selectedTime");
                  return jsonEncode(sales);
                });

                controller.addJavaScriptHandler(handlerName: 'finishActivity', callback: (args) {
                  Navigator.pop(context);
                });
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(source: """
                  if (typeof initBuyData === 'function') {
                    initBuyData('$_selectedDate', '$_selectedTime');
                  }
                """);
              },
            ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2B6CB0))),
                  SizedBox(height: 15),
                  Text("Loading Buy Interface...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}