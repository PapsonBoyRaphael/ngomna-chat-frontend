import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';

class SelectableContactTile extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isGroup;

  const SelectableContactTile({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.onTap,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: _buildAvatar(),
          title: Text(
            contact.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isGroup ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Roboto',
            ),
          ),
          trailing: _buildCheckbox(),
        ),
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
          radius: 22,
          backgroundImage: AssetImage(
            (contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty)
                ? contact.avatarUrl!
                : 'assets/avatars/default_avatar.png',
          ),
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

  Widget _buildCheckbox() {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade400,
          width: 2,
        ),
        color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
