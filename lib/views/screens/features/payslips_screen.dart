import 'package:flutter/material.dart';

class PayslipsScreen extends StatelessWidget {
  const PayslipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslips'),
      ),
      body: const Center(
        child: Text('Payslips Screen'),
      ),
    );
  }
}
