import 'package:flutter/material.dart';

class DateSeparator extends StatelessWidget {
  final String text;

  const DateSeparator({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
