import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/time_database_helper.dart';

class AddTimeScreen extends StatefulWidget {
  const AddTimeScreen({super.key});

  @override
  State<AddTimeScreen> createState() => _AddTimeScreenState();
}

class _AddTimeScreenState extends State<AddTimeScreen> {
  final TimeDatabaseHelper _timeDbHelper = TimeDatabaseHelper();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Date Picker ပြသခြင်း လုပ်ဆောင်ချက်
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF667EEA)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Time Picker ပြသခြင်း လုပ်ဆောင်ချက်
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF667EEA)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // ဒေတာဘေ့စ်ထဲသို့ သိမ်းဆည်းခြင်း စနစ်
  Future<void> _saveTimeData() async {
    // နေ့စွဲကို yyyy-MM-dd ပုံစံပြောင်းခြင်း
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    // အချိန်ကို HH:mm ပုံစံပြောင်းခြင်း (ဥပမာ- 16:30, 09:15)
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
    String formattedTime = DateFormat('HH:mm').format(dt);

    bool success = await _timeDbHelper.insertTime(formattedDate, formattedTime);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ပွဲစဉ်အချိန် ထည့်သွင်းအောင်မြင်ပါသည်"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Dashboard သို့ ပြန်သွားရန်
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("အမှားအယွင်းရှိနေပါသည်"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
    String timeStr = DateFormat('hh:mm a').format(dt); // UI တွင် လူကြည့်ကောင်းအောင် AM/PM ပြပေးခြင်း

    return Scaffold(
      appBar: AppBar(
        title: const Text("ပွဲစဉ်အသစ် ထည့်သွင်းရန်"),
        backgroundColor: const Color(0xFF667EEA),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Date Selector Card
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFF667EEA)),
                title: const Text("နေ့စွဲ ရွေးချယ်ရန်"),
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(height: 15),
            
            // Time Selector Card
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Color(0xFF667EEA)),
                title: const Text("အချိန် ရွေးချယ်ရန်"),
                subtitle: Text(timeStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 30),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveTimeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("ပွဲစဉ် သိမ်းဆည်းမည်", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}