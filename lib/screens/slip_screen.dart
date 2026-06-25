import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../database/sale_database_helper.dart';
import '../database/name_database_helper.dart';
import 'slip_view_screen.dart';

class SlipScreen extends StatefulWidget {
  final String timeStr;

  const SlipScreen({super.key, required this.timeStr});

  @override
  State<SlipScreen> createState() => _SlipScreenState();
}

class _SlipScreenState extends State<SlipScreen> {
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
      ByteData data = await rootBundle.load("assets/web/slip.bal");
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
        _decryptedHtml = "<html><body><h2>Slip Load Error</h2><p>${e.toString()}</p></body></html>";
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
        title: const Text("ဘောက်ချာဖြတ်ပိုင်းများ"),
        backgroundColor: const Color(0xFF9B2C2C),
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
                
                controller.addJavaScriptHandler(handlerName: 'loadUsers', callback: (args) async {
                  return await _nameDbHelper.getAllUsersAsJson();
                });

                controller.addJavaScriptHandler(handlerName: 'getSlipCount', callback: (args) async {
                  return await _saleDbHelper.getSlipCount("$_selectedDate $_selectedTime");
                });

                controller.addJavaScriptHandler(handlerName: 'getTotalAmount', callback: (args) async {
                  return await _saleDbHelper.getTotalAmountByKey("$_selectedDate $_selectedTime");
                });

                controller.addJavaScriptHandler(handlerName: 'getSalesData', callback: (args) async {
                  final sales = await _saleDbHelper.getSalesByKey("$_selectedDate $_selectedTime");
                  return jsonEncode(sales);
                });

                controller.addJavaScriptHandler(handlerName: 'deleteSale', callback: (args) async {
                  if (args.isNotEmpty) {
                    return await _saleDbHelper.deleteSale(int.parse(args[0].toString()));
                  }
                  return false;
                });

                // updateSale (ဘောက်ချာပြင်ဆင်ခြင်း စနစ်)
                controller.addJavaScriptHandler(handlerName: 'updateSale', callback: (args) async {
                  if (args.length >= 2) {
                    try {
                      int saleId = int.parse(args[0].toString());
                      Map<String, dynamic> json = jsonDecode(args[1].toString());
                      bool success = await _saleDbHelper.updateSale(
                        saleId,
                        json['name'],
                        json['com'] ?? 0,
                        json['za'] ?? 0,
                        json['numbers'].toString(),
                        json['bets'].toString(),
                        double.parse(json['total_amount'].toString()),
                      );
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ ပြင်ဆင်ပြီးပါပြီ"), backgroundColor: Colors.green),
                        );
                      }
                      return success;
                    } catch (e) {
                      return false;
                    }
                  }
                  return false;
                });

                // openSlipViewActivity (SlipViewScreen သို့ ကူးပြောင်းခြင်း)
                controller.addJavaScriptHandler(handlerName: 'openSlipViewActivity', callback: (args) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SlipViewScreen(timeStr: widget.timeStr)),
                  );
                });

                controller.addJavaScriptHandler(handlerName: 'finishActivity', callback: (args) {
                  Navigator.pop(context);
                });
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(source: """
                  if (typeof initSlipData === 'function') {
                    initSlipData('$_selectedDate', '$_selectedTime');
                  }
                """);
              },
            ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B2C2C))),
                  SizedBox(height: 15),
                  Text("Loading Slip Interface...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}