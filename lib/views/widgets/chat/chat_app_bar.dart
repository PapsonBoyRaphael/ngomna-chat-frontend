import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User user;
  final VoidCallback onBack;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final String? customTitle;
  final String? customSubtitle;
  final String? customAvatar;
  final bool showCallButtons;

  const ChatAppBar({
    super.key,
    required this.user,
    required this.onBack,
    required this.onCall,
    required this.onVideoCall,
    this.customTitle,
    this.customSubtitle,
    this.customAvatar,
    this.showCallButtons = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) {
    final title = customTitle ?? user.fullName;
    final subtitle = customSubtitle ?? (user.isOnline ? 'Online' : 'Offline');
    final avatarUrl = customAvatar ?? user.avatarUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: const Icon(Icons.arrow_back_ios, size: 18),
            ),
            const SizedBox(width: 8),
            _buildAvatar(avatarUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            if (showCallButtons) ...[
              GestureDetector(
                onTap: onCall,
                child: const Icon(Icons.call, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onVideoCall,
                child: const Icon(Icons.videocam, color: Color(0xFF4CAF50)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: AssetImage(
            (avatarUrl != null && avatarUrl.isNotEmpty)
                ? avatarUrl
                : 'assets/avatars/default_avatar.png',
          ),
        ),
        if (user.isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
