import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final bool showDivider;

  const ContactTile({
    super.key,
    required this.contact,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _buildAvatar(),
          title: Text(
            contact.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
              fontFamily: 'Roboto',
            ),
          ),
          subtitle: contact.lastMessage != null
              ? Text(
                  contact.lastMessage!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Roboto',
                  ),
                )
              : null,
          trailing: contact.lastMessageTime != null
              ? Text(
                  contact.lastMessageTime!,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                  ),
                )
              : null,
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            color: Colors.grey,
            thickness: 1,
            indent: 25,
            endIndent: 25,
          ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(
            (contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty)
                ? contact.avatarUrl!
                : 'assets/avatars/default_avatar.png',
          ),
          radius: 22,
        ),
        if (contact.isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
