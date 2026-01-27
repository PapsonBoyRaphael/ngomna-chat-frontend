import 'package:flutter/material.dart';

class GroupMemberTile extends StatelessWidget {
  final String name;
  final String avatar;
  final bool isGroup;
  final bool isOnline;

  const GroupMemberTile({
    super.key,
    required this.name,
    required this.avatar,
    this.isGroup = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage(avatar),
              ),
              if (isOnline)
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
          ),
          title: Text(
            name,
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
