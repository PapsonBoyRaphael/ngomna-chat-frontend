import 'package:flutter/material.dart';

class CensusScreen extends StatelessWidget {
  const CensusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Census'),
      ),
      body: const Center(
        child: Text('Census Screen'),
      ),
    );
  }
}
