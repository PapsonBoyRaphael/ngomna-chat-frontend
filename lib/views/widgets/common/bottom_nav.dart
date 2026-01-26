import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/screens/chat/chat_list_screen.dart';
import 'package:ngomna_chat/views/screens/home/home_screen.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.chatList);
            },
            child: Image.asset('assets/icons/chat.png', width: 52),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.home);
            },
            child: Image.asset('assets/icons/home.png', width: 32),
          ),
          GestureDetector(
            onTap: () {},
            child: Image.asset('assets/icons/sparkle.png', width: 50),
          ),
        ],
      ),
    );
  }
}
