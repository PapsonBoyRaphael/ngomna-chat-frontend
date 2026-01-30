import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/create_group_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/group_repository.dart';
import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';
import 'package:ngomna_chat/views/widgets/contacts/group_form_fields.dart';
import 'package:ngomna_chat/views/widgets/contacts/create_group_top_bar.dart';
import 'package:ngomna_chat/views/widgets/contacts/member_list_item.dart';
import 'package:ngomna_chat/views/widgets/common/section_title.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';

class CreateGroupScreen extends StatelessWidget {
  final List<Contact> selectedContacts;

  const CreateGroupScreen({
    super.key,
    required this.selectedContacts,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateGroupViewModel(
        GroupRepository(ApiService()),
        selectedContacts,
      ),
      child: _CreateGroupContent(selectedContacts: selectedContacts),
    );
  }
}

class _CreateGroupContent extends StatefulWidget {
  final List<Contact> selectedContacts;

  const _CreateGroupContent({required this.selectedContacts});

  @override
  State<_CreateGroupContent> createState() => _CreateGroupContentState();
}

class _CreateGroupContentState extends State<_CreateGroupContent> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateViewModel);
    _descriptionController.addListener(_updateViewModel);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateViewModel() {
    final viewModel = context.read<CreateGroupViewModel>();
    viewModel.setGroupName(_nameController.text);
    viewModel.setGroupDescription(_descriptionController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer<CreateGroupViewModel>(
          builder: (context, viewModel, _) {
            return CreateGroupTopBar(
              isDoneEnabled: viewModel.isDoneEnabled,
              onCancel: () => Navigator.pop(context),
              onDone: () => _handleCreateGroup(context, viewModel),
            );
          },
        ),
      ),
      body: Consumer<CreateGroupViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isCreating) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                GroupFormFields(
                  nameController: _nameController,
                  descriptionController: _descriptionController,
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
                        title: '${viewModel.memberCount} members selected',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...widget.selectedContacts.map((contact) {
                      return MemberListItem(
                        contact: contact,
                        isGroup: contact.name.contains('GROUP') ||
                            contact.name.contains('PROJECT'),
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCreateGroup(
    BuildContext context,
    CreateGroupViewModel viewModel,
  ) async {
    if (!viewModel.isDoneEnabled) return;

    final createdGroup = await viewModel.createGroup();

    if (createdGroup != null && mounted) {
      // Naviguer vers le chat du groupe créé
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.chatGroup,
        (route) => route.settings.name == AppRoutes.chatList,
        arguments: {
          'groupId': createdGroup.id,
          'groupName': createdGroup.name,
          'groupAvatar': createdGroup.avatarUrl,
        },
      );
    } else if (viewModel.error != null && mounted) {
      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${viewModel.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
