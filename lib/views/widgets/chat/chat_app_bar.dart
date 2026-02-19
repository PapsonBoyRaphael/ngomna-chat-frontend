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
  final List<String>? typingUsers;

  /// Indique si c'est un groupe (affiche le nombre de membres)
  final bool isGroup;

  /// Nombre de membres en ligne (pour les groupes)
  final int? onlineCount;

  /// Nombre total de participants (pour les groupes)
  final int? totalParticipants;

  /// Indique si c'est une diffusion (broadcast)
  final bool isBroadcast;

  /// Override de présence pour les chats personnels
  final bool? isOnlineOverride;
  final DateTime? lastSeenOverride;

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
    this.typingUsers,
    this.isGroup = false,
    this.onlineCount,
    this.totalParticipants,
    this.isBroadcast = false,
    this.isOnlineOverride,
    this.lastSeenOverride,
  });

  @override
  Size get preferredSize => const Size.fromHeight(78);

  /// Formate le "dernière connexion" de manière conviviale
  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Hors ligne';

    print('🕐 [ChatAppBar._formatLastSeen] Calcul du "dernière vu":');
    print('   - lastSeen reçu: $lastSeen');
    print('   - lastSeen.isUtc: ${lastSeen.isUtc}');

    // Convertir en heure locale si la date est en UTC
    final localLastSeen = lastSeen.isUtc ? lastSeen.toLocal() : lastSeen;
    print('   - localLastSeen après conversion: $localLastSeen');

    final now = DateTime.now();
    print('   - now (heure actuelle): $now');

    final difference = now.difference(localLastSeen);
    print(
        '   - difference: ${difference.inSeconds} secondes (${difference.inMinutes} minutes, ${difference.inHours} heures)');

    if (difference.inMinutes < 1) {
      print('   ➡️ Résultat: "À l\'instant"');
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      print('   ➡️ Résultat: "Vu il y a ${difference.inMinutes} min"');
      return 'Vu il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      print('   ➡️ Résultat: "Vu il y a ${difference.inHours}h"');
      return 'Vu il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Vu hier à ${DateFormat.Hm().format(localLastSeen)}';
    } else if (difference.inDays < 7) {
      return 'Vu ${DateFormat.EEEE().format(localLastSeen)} à ${DateFormat.Hm().format(localLastSeen)}';
    } else {
      return 'Vu le ${DateFormat.yMMMd().format(localLastSeen)}';
    }
  }

  String _formatTyping(List<String> names, {required bool showNames}) {
    if (names.isEmpty) return '';
    if (!showNames) {
      return 'En train d\'écrire...';
    }
    if (names.length == 1) {
      return '${names.first} écrit...';
    }
    if (names.length == 2) {
      return '${names[0]} et ${names[1]} écrivent...';
    }
    final othersCount = names.length - 2;
    return '${names[0]}, ${names[1]} et $othersCount autres écrivent...';
  }

  @override
  Widget build(BuildContext context) {
    final title = customTitle ?? user.fullName;
    final String subtitle;
    final Color subtitleColor;

    final effectiveIsOnline = isOnlineOverride ?? user.isOnline;
    final effectiveLastSeen = lastSeenOverride ?? user.lastSeen;
    final hasTyping = typingUsers != null && typingUsers!.isNotEmpty;

    if (hasTyping) {
      subtitle = _formatTyping(typingUsers!, showNames: isGroup);
      subtitleColor = const Color(0xFF4CAF50);
    } else if (customSubtitle != null) {
      subtitle = customSubtitle!;
      subtitleColor = const Color(0xFF9E9E9E);
    } else if (isGroup) {
      // Pour les groupes, afficher le nombre de membres en ligne
      final online = onlineCount ?? 0;
      final total = totalParticipants ?? 0;
      subtitle = '$total membres${online > 0 ? ', $online en ligne' : ''}';
      subtitleColor = const Color(0xFF9E9E9E);
    } else {
      // Pour les chats personnels
      subtitle =
          effectiveIsOnline ? 'En ligne' : _formatLastSeen(effectiveLastSeen);
      subtitleColor = const Color(0xFF9E9E9E);
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
            _buildAvatar(avatarUrl, isOnline: effectiveIsOnline),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
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

  Widget _buildAvatar(String? avatarUrl, {required bool isOnline}) {
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
        if (isOnline && !isGroup && !isBroadcast)
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
