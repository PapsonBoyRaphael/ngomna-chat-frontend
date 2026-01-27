import 'package:flutter/material.dart';

class CreateGroupTopBar extends StatelessWidget {
  final bool isNextEnabled;
  final VoidCallback onCancel;
  final VoidCallback onNext;

  const CreateGroupTopBar({
    super.key,
    required this.isNextEnabled,
    required this.onCancel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 8),
      child: Column(
        children: [
          Row(
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
                onPressed: isNextEnabled ? onNext : null,
                child: Text(
                  'Done',
                  style: TextStyle(
                    color:
                        isNextEnabled ? const Color(0xFF4CAF50) : Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
