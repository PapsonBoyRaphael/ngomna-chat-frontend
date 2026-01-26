import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/screens/auth/welcome_screen.dart';
import 'package:ngomna_chat/views/screens/auth/enter_matricule_screen.dart';
import 'package:ngomna_chat/views/screens/chat/chat_list_screen.dart';
import 'package:ngomna_chat/views/screens/home/home_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String enterMatricule = '/enter-matricule';
  static const String chatList = '/chat-list';
  static const String home = '/home';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      welcome: (context) => const WelcomeScreen(),
      enterMatricule: (context) => const EnterMatriculeScreen(),
      chatList: (context) => const ChatListScreen(),
      home: (context) => const HomeScreen(),
    };
  }
}
