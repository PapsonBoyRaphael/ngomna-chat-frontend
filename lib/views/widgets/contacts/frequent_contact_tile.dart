import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';

class FrequentContactTile extends StatelessWidget {
  final Contact contact;
  final bool isGroup;
  final VoidCallback onTap;

  const FrequentContactTile({
    super.key,
    required this.contact,
    this.isGroup = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: AssetImage(
            (contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty)
                ? contact.avatarUrl!
                : 'assets/avatars/default_avatar.png',
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: isGroup ? FontWeight.w500 : FontWeight.w400,
            fontFamily: 'Roboto',
            fontSize: 17,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
