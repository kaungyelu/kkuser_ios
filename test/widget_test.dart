import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart'; // စာလုံးပေါင်းအမှန် ပြင်ဆင်ထားပါသည်
import 'package:kkuser_ios/main.dart'; // အစ်ကို့ ပရောဂျက်အမည် kkuser_ios အတိုင်း ပြန်ပြင်ထားပါသည်

void main() {
  testWidgets('Counter advancement smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Checking License Status...'), findsOneWidget);
  });
}