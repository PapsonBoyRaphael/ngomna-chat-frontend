import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/screens/chat/chat_list_screen.dart';
import 'package:ngomna_chat/views/screens/home/ngomna_first_screen.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.chatList);
            },
            icon: Image.asset('assets/icons/chat.png', width: 52),
            iconSize: 52,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 28, // Rayon pour un effet circulaire
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.home);
            },
            icon: Image.asset('assets/icons/home.png', width: 32),
            iconSize: 32,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 28,
          ),
          IconButton(
            onPressed: () {},
            icon: Image.asset('assets/icons/sparkle.png', width: 50),
            iconSize: 50,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 28,
          ),
        ],
      ),
    );
  }
}
