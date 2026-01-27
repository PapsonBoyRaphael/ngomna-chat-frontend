import 'package:flutter/material.dart';

class ActionTile extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 35),
            const SizedBox(width: 10),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            fontFamily: 'Roboto',
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
