import 'package:flutter/material.dart';
import 'package:ngomna_chat/viewmodels/select_contacts_viewmodel.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';

class SelectContactsTopBar extends StatelessWidget {
  final SelectMode mode;
  final bool isNextEnabled;
  final VoidCallback onCancel;
  final VoidCallback onNext;
  final ValueChanged<String> onSearch;

  const SelectContactsTopBar({
    super.key,
    required this.mode,
    required this.isNextEnabled,
    required this.onCancel,
    required this.onNext,
    required this.onSearch,
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
                  'Next',
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
          const SizedBox(height: 15),
          Text(
            mode == SelectMode.broadcast ? 'New broadcast' : 'New group',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 179, 179, 179),
            ),
          ),
          const SizedBox(height: 30),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearch,
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Image.asset(AppAssets.search, width: 20),
        ],
      ),
    );
  }
}
