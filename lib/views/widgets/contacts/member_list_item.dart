import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';

class MemberListItem extends StatelessWidget {
  final Contact contact;
  final bool isGroup;

  const MemberListItem({
    super.key,
    required this.contact,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage(contact.avatarUrl),
          ),
          title: Text(
            contact.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isGroup ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Roboto',
            ),
          ),
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
}
