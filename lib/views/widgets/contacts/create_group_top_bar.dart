import 'package:flutter/material.dart';

class CreateGroupTopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDoneEnabled;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  const CreateGroupTopBar({
    super.key,
    required this.isDoneEnabled,
    required this.onCancel,
    required this.onDone,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 2),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: isDoneEnabled ? onDone : null,
            child: Text(
              'Done',
              style: TextStyle(
                color: isDoneEnabled ? const Color(0xFF4CAF50) : Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
