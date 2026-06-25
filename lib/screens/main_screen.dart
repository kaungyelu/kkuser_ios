import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/name_database_helper.dart';
import 'dashboard_screen.dart';
import 'verification_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String deviceId = "Loading...";
  String calculatedKey = "Calculating...";
  final NameDatabaseHelper _nameDbHelper = NameDatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initializeAppFlow();
  }

  Future<void> _initializeAppFlow() async {
    await _ensureAdminExists();
    String rawId = await _getDeviceUUID();
    String generatedLicense = _calculateLicenseKey(rawId);

    if (mounted) {
      setState(() {
        deviceId = rawId;
        calculatedKey = generatedLicense;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    String verifiedLicense = prefs.getString("verified_license") ?? "";

    if (verifiedLicense == generatedLicense) {
      _navigateTo(const DashboardScreen());
    } else {
      _navigateTo(VerificationScreen(
        deviceId: deviceId,
        generatedKey: calculatedKey,
      ));
    }
  }

  Future<void> _ensureAdminExists() async {
    bool adminExists = await _nameDbHelper.checkAdminExists();
    if (!adminExists) {
      await _nameDbHelper.insertAdmin();
    }
  }

  Future<String> _getDeviceUUID() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "UNKNOWN_IOS_ID";
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }
    } catch (e) {
      return "ERROR_GETTING_ID";
    }
    return "UNKNOWN_PLATFORM";
  }

  String _calculateLicenseKey(String id) {
    if (id.length < 15) {
      id = "${id}0000000000000000";
    }
    String midPart = id.substring(5, 15);
    String combinedText = midPart + "kyl2016";
    var bytes = utf8.encode(combinedText);
    var digest = md5.convert(bytes);
    return digest.toString().toUpperCase();
  }

  void _navigateTo(Widget targetScreen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
            SizedBox(height: 20),
            Text(
              "Checking License Status...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}