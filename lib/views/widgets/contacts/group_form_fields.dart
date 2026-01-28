import 'package:flutter/material.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';

class GroupFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const GroupFormFields({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Group Name Section
        Padding(
          padding: const EdgeInsets.fromLTRB(30.0, 10, 30, 10),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 226, 231, 249),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Image.asset(
                  AppAssets.group,
                  width: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter group name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF4CAF50),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Group Description Section
        Padding(
          padding: const EdgeInsets.fromLTRB(30.0, 0, 30, 30),
          child: TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter group description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF4CAF50),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
