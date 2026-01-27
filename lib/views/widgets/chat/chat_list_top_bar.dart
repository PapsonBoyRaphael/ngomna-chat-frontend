import 'package:flutter/material.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';

class ChatListTopBar extends StatelessWidget {
  final VoidCallback onNewChat;
  final ValueChanged<String> onSearch;

  const ChatListTopBar({
    super.key,
    required this.onNewChat,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(AppAssets.meatballs, width: 26),
              const Spacer(),
              const Text(
                'Chats',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onNewChat,
                child: Image.asset(AppAssets.plus, width: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearch,
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Image.asset(AppAssets.search, width: 20),
        ],
      ),
    );
  }
}
