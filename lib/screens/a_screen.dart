import 'package:flutter/material.dart';
import 'sale_screen.dart';
import 'buy_screen.dart';
import 'ledger_screen.dart';
import 'result_screen.dart';
import 'week_screen.dart';
import 'name_screen.dart';
import 'slip_screen.dart';
import 'slip_view_screen.dart';

class AScreen extends StatelessWidget {
  final String selectedTimeStr; // Dashboard က သယ်လာမယ့် နေ့စွဲနှင့် အချိန်စာသား

  const AScreen({super.key, required this.selectedTimeStr});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTimeStr),
        backgroundColor: const Color(0xFF667EEA),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF7FAFC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // တစ်တန်းလျှင် ခလုတ် ၂ ခုစီပြမည်
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2, // ခလုတ်များ၏ အချိုးအစား
          children: [
            _buildAnimatedMenuButton(context, "၁။ အရောင်း", Icons.shopping_cart, const Color(0xFF4C51BF), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SaleScreen(timeStr: selectedTimeStr)));
            }),
            _buildAnimatedMenuButton(context, "၂။ အဝယ်", Icons.account_balance_wallet, const Color(0xFF2B6CB0), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => BuyScreen(timeStr: selectedTimeStr)));
            }),
            _buildAnimatedMenuButton(context, "၃။ စာရင်းချုပ်", Icons.assignment, const Color(0xFF2C5282), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LedgerScreen(timeStr: selectedTimeStr)));
            }),
            _buildAnimatedMenuButton(context, "၄။ ရလဒ်ထည့်ရန်", Icons.star, const Color(0xFFB7791F), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ResultScreen(timeStr: selectedTimeStr)));
            }),
            _buildAnimatedMenuButton(context, "၅။ အပတ်စဉ်ဇယား", Icons.date_range, const Color(0xFF2F855A), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => WeekScreen(timeStr: selectedTimeStr)));
            }),
            _buildAnimatedMenuButton(context, "၆။ ဝယ်သူစာရင်း", Icons.people, const Color(0xFFC53030), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NameScreen()));
            }),
            _buildAnimatedMenuButton(context, "၇။ ဘောက်ချာဖြတ်", Icons.receipt, const Color(0xFF9B2C2C), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SlipScreen(timeStr: selectedTimeStr)));
            }),
            _buildAnimatedMenuButton(context, "၈။ ဘောက်ချာရှာရန်", Icons.search, const Color(0xFF4A5568), () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SlipViewScreen(timeStr: selectedTimeStr)));
            }),
          ],
        ),
      ),
    );
  }

  // မူရင်း Android ကဲ့သို့ Touch လိုက်လျှင် အကျုံ့အဆန့်ဖြစ်စေမည့် Custom Widget (Scale Effect)
  Widget _buildAnimatedMenuButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return _MenuScaleAnimator(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Touch Effect ထိန်းချုပ်ပေးမည့် Custom Stateful Widget
class _MenuScaleAnimator extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _MenuScaleAnimator({required this.child, required this.onTap});

  @override
  State<_MenuScaleAnimator> createState() => _MenuScaleAnimatorState();
}

class _MenuScaleAnimatorState extends State<_MenuScaleAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animation Duration ကို Android ထုံးစံအတိုင်း ခပ်သွက်သွက် ၁၀၀ မီလီစက္ကန့် သတ်မှတ်ပါသည်
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    // နှိပ်လိုက်လျှင် မူရင်းအရွယ်အစား၏ ၉၂ ရာခိုင်နှုန်း (0.92) သို့ ကျုံ့သွားမည်
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(), // လက်ဖိလိုက်လျှင် ကျုံ့မည်
      onTapUp: (_) {
        _controller.reverse(); // လက်လွှတ်လိုက်လျှင် မူရင်းအတိုင်းပြန်ဖြစ်ပြီး Pushed လုပ်မည်
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(), // ဖိရင်းနှင့် ဘေးသို့လွဲသွားပါက ပြန်ပွပွင့်စေမည်
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}