import 'package:flutter/material.dart';

class DgiScreen extends StatelessWidget {
  const DgiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DGI'),
      ),
      body: const Center(
        child: Text('DGI Screen'),
      ),
    );
  }
}
