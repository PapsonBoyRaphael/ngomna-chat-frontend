import 'package:flutter/material.dart';
import 'package:ngomna_chat/views/screens/auth/welcome_screen.dart';
import 'package:ngomna_chat/views/screens/auth/enter_matricule_screen.dart';
import 'package:ngomna_chat/views/screens/chat/chat_list_screen.dart';
import 'package:ngomna_chat/views/screens/home/ngomna_first_screen.dart';
import 'package:ngomna_chat/views/screens/auth/select_post_screen.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';
import 'package:ngomna_chat/views/screens/groups/create_group_screen.dart';
import 'package:ngomna_chat/views/screens/features/payslips_screen.dart';
import 'package:ngomna_chat/views/screens/features/census_screen.dart';
import 'package:ngomna_chat/views/screens/features/information_screen.dart';
import 'package:ngomna_chat/views/screens/features/dgi_screen.dart';
import 'package:ngomna_chat/views/screens/chat/chat_broadcast_screen.dart';
import 'package:ngomna_chat/views/screens/chat/new_chat_screen.dart';
import 'package:ngomna_chat/views/screens/chat/chat_group_screen.dart';
import 'package:ngomna_chat/screens/select_contact_screen.dart';

class AppRoutes {
  // Auth
  static const String welcome = '/';
  static const String enterMatricule = '/enter-matricule';
  static const String selectPost = '/select-post';

  // Home
  static const String home = '/home';

  // Features
  static const String payslips = '/payslips';
  static const String census = '/census';
  static const String information = '/information';
  static const String dgi = '/dgi';

  // Chat
  static const String chatList = '/chat-list';
  static const String chat = '/chat';
  static const String chatBroadcast = '/chat-broadcast';
  static const String newChat = '/new-chat';
  static const String chatGroup = '/chat-group';

  static const String selectContacts = '/select-contacts';
  static const String createGroup = '/create-group';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      welcome: (context) => const WelcomeScreen(),
      enterMatricule: (context) => const EnterMatriculeScreen(),
      selectPost: (context) => const SelectPostScreen(),
      home: (context) => const NgomnaFirstScreen(),
      chatList: (context) => const ChatListScreen(),
      selectContacts: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map?;
        final mode = args?['mode'] == 'broadcast'
            ? SelectMode.broadcast
            : SelectMode.group;
        return SelectContactsScreen(mode: mode);
      },
      createGroup: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map?;
        final selectedContacts = args?['selectedContacts'] as List<Contact>?;
        return CreateGroupScreen(selectedContacts: selectedContacts ?? []);
      },
      payslips: (context) => const PayslipsScreen(),
      census: (context) => const CensusScreen(),
      information: (context) => const InformationScreen(),
      dgi: (context) => const DgiScreen(),
      chatBroadcast: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ChatBroadcastScreen(
          broadcastId: args['broadcastId'],
          broadcastName: args['broadcastName'] ?? 'Broadcast',
        );
      },
      newChat: (context) => const NewChatScreen(),
      chatGroup: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return ChatGroupScreen(
          groupId: args['groupId'],
          groupName: args['groupName'],
          groupAvatar: args['groupAvatar'],
        );
      },
    };
  }
}
