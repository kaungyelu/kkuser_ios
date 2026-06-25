import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_screen.dart';

void main() {
  // Flutter Engine အလုပ်လုပ်ပုံကို ကြိုတင်အခြေချခြင်း
  WidgetsFlutterBinding.ensureInitialized();
  
  // App ကို Portrait Mode (ဒေါင်လိုက်မျက်နှာပြင်) တစ်ခုတည်းဖြင့်ပဲ အသေသုံးနိုင်ရန် ပိတ်ထားခြင်း Logic
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKuser 2D',
      debugShowCheckedModeBanner: false, // ညာဘက်အပေါ်က Debug စာတန်းအနီလေးကို ဖျောက်ထားခြင်း
      
      // iOS / Material Design ၏ Themes အခြေခံအရောင်ကို သတ်မှတ်ခြင်း
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF667EEA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          primary: const Color(0xFF667EEA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      ),
      
      // App စတင်ပွင့်ပွင့်ချင်း အလုပ်လုပ်မည့် ပထမဆုံးမျက်နှာပြင် (လိုင်စင်စစ်ဆေးမည့်ဂိတ်)
      home: const MainScreen(),
    );
  }
}