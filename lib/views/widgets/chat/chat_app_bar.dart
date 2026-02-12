import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/user_model.dart';
import 'package:intl/intl.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User user;
  final VoidCallback onBack;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final String? customTitle;
  final String? customSubtitle;
  final String? customAvatar;
  final bool showCallButtons;

  /// Indique si c'est un groupe (affiche le nombre de membres)
  final bool isGroup;

  /// Nombre de membres en ligne (pour les groupes)
  final int? onlineCount;

  /// Nombre total de participants (pour les groupes)
  final int? totalParticipants;

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
    this.isGroup = false,
    this.onlineCount,
    this.totalParticipants,
  });

  @override
  Size get preferredSize => const Size.fromHeight(78);

  /// Formate le "dernière connexion" de manière conviviale
  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Hors ligne';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Vu il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Vu il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Vu hier à ${DateFormat.Hm().format(lastSeen)}';
    } else if (difference.inDays < 7) {
      return 'Vu ${DateFormat.EEEE().format(lastSeen)} à ${DateFormat.Hm().format(lastSeen)}';
    } else {
      return 'Vu le ${DateFormat.yMMMd().format(lastSeen)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = customTitle ?? user.fullName;
    final String subtitle;

    if (customSubtitle != null) {
      subtitle = customSubtitle!;
    } else if (isGroup) {
      // Pour les groupes, afficher le nombre de membres en ligne
      final online = onlineCount ?? 0;
      final total = totalParticipants ?? 0;
      subtitle = '$total membres${online > 0 ? ', $online en ligne' : ''}';
    } else {
      // Pour les chats personnels
      subtitle = user.isOnline ? 'En ligne' : _formatLastSeen(user.lastSeen);
    }

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          backgroundColor: const Color(0xFFEDEDED),
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
                color: const Color(0xFF4CAF50), // Vert pour en ligne
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
