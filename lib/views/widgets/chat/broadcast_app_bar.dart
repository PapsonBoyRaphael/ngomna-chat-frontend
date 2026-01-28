import 'package:flutter/material.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';
import 'package:ngomna_chat/core/constants/app_fonts.dart';

class BroadcastAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String broadcastName;
  final VoidCallback onBack;
  final int recipientCount;

  const BroadcastAppBar({
    super.key,
    required this.broadcastName,
    required this.onBack,
    required this.recipientCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) {
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
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.transparent,
              child: Image.asset(
                AppAssets.broadcast,
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    broadcastName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Broadcasting to ${recipientCount} contacts',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
