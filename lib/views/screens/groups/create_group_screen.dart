import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/create_group_viewmodel.dart';
import 'package:ngomna_chat/views/widgets/groups/group_info_input.dart';
import 'package:ngomna_chat/views/widgets/groups/group_member_tile.dart';
import 'package:ngomna_chat/views/widgets/common/section_title.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';
import 'package:ngomna_chat/views/screens/chat/chat_group_screen.dart';

class CreateGroupScreen extends StatelessWidget {
  final List<Contact> selectedContacts;

  const CreateGroupScreen({
    super.key,
    required this.selectedContacts,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateGroupViewModel(selectedContacts),
      child: const _CreateGroupContent(),
    );
  }
}

class _CreateGroupContent extends StatelessWidget {
  const _CreateGroupContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateGroupViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: viewModel.isDoneEnabled
                ? () => _onDone(context, viewModel)
                : null,
            child: Text(
              'Done',
              style: TextStyle(
                color: viewModel.isDoneEnabled
                    ? const Color(0xFF4CAF50)
                    : Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                      'assets/icons/group.png',
                      width: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GroupInfoInput(
                      controller: viewModel.groupNameController,
                      hintText: 'Enter group name',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30.0, 0, 30, 30),
              child: GroupInfoInput(
                controller: viewModel.groupDescriptionController,
                hintText: 'Enter group description',
                maxLines: 3,
              ),
            ),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: SectionTitle(
                    title:
                        '${viewModel.selectedContacts.length} members selected',
                  ),
                ),
                const SizedBox(height: 10),
                ...viewModel.selectedContacts.map((contact) {
                  return GroupMemberTile(
                    name: contact.name,
                    avatar: contact.avatarUrl,
                    isGroup: false,
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onDone(BuildContext context, CreateGroupViewModel viewModel) {
    // Navigate to the group chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatGroupScreen(
          groupId: viewModel.groupId,
          groupName: viewModel.groupNameController.text,
          groupAvatar: 'assets/icons/group.png',
        ),
      ),
    );
  }
}
