import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('نمودار واریزی‌ها و برداشت‌ها (به‌زودی)'),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('موجودی حساب‌ها به تفکیک بانک (به‌زودی)'),
            ),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('تعداد کاربران و وام‌های تسویه‌نشده (به‌زودی)'),
            ),
          ),
        ],
      ),
    );
  }
}


