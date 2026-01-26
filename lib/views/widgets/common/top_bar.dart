import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Image.asset('assets/icons/menu.png', width: 35),
          ),
          GestureDetector(
            onTap: () {},
            child: Image.asset('assets/icons/notification.png', width: 35),
          ),
          GestureDetector(
            onTap: () {},
            child: Image.asset('assets/icons/settings.png', width: 35),
          ),
        ],
      ),
    );
  }
}
