import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/new_chat_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/contact_repository.dart';
import 'package:ngomna_chat/views/widgets/contacts/action_tile.dart';
import 'package:ngomna_chat/views/widgets/contacts/frequent_contact_tile.dart';
import 'package:ngomna_chat/views/widgets/contacts/contact_tile.dart';
import 'package:ngomna_chat/views/widgets/common/section_title.dart';
import 'package:ngomna_chat/views/widgets/chat/category_chip.dart';
import 'package:ngomna_chat/views/widgets/common/bottom_nav.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewChatViewModel(ContactRepository())..loadContacts(),
      child: const _NewChatContent(),
    );
  }
}

class _NewChatContent extends StatelessWidget {
  const _NewChatContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            _buildDepartmentFilters(),
            Expanded(
              child: Consumer<NewChatViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 10,
                    ),
                    children: [
                      _buildActions(context),
                      const SizedBox(height: 15),
                      const SectionTitle(title: 'Frequent conversations'),
                      const SizedBox(height: 15),
                      _buildFrequentContacts(context, viewModel),
                      const SizedBox(height: 18),
                      const SectionTitle(title: 'My service'),
                      _buildContacts(context, viewModel),
                    ],
                  );
                },
              ),
            ),
            const BottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 46, 20, 8),
      child: Container(
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
                onChanged: (query) {
                  context.read<NewChatViewModel>().searchContacts(query);
                },
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
      ),
    );
  }

  Widget _buildDepartmentFilters() {
    return Consumer<NewChatViewModel>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: Department.values.map((dept) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CategoryChip(
                    label: _getDepartmentLabel(dept),
                    isSelected: viewModel.selectedDepartment == dept,
                    onTap: () => viewModel.setDepartmentFilter(dept),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        ActionTile(
          icon: AppAssets.broadcast,
          title: 'New broadcast',
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.selectContacts,
              arguments: {'mode': 'broadcast'},
            );
          },
        ),
        ActionTile(
          icon: AppAssets.group,
          title: 'New group',
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.selectContacts,
              arguments: {'mode': 'group'},
            );
          },
        ),
      ],
    );
  }

  Widget _buildFrequentContacts(
    BuildContext context,
    NewChatViewModel viewModel,
  ) {
    return Column(
      children: viewModel.frequentContacts.map((contact) {
        return FrequentContactTile(
          contact: contact,
          isGroup: contact.name.contains('GROUP') ||
              contact.name.contains('PROJECT'),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.chat,
              arguments: {
                'chatId': contact.id,
                'user': User(
                  id: contact.id,
                  matricule: contact.id,
                  nom: contact.name.split(' ').first,
                  prenom: contact.name.split(' ').length > 1
                      ? contact.name.split(' ').sublist(1).join(' ')
                      : '',
                  avatarUrl: contact.avatarUrl,
                  isOnline: contact.isOnline,
                ),
              },
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildContacts(BuildContext context, NewChatViewModel viewModel) {
    return Column(
      children: viewModel.filteredContacts.map((contact) {
        return ContactTile(
          contact: contact,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.chat,
              arguments: {
                'chatId': contact.id,
                'user': User(
                  id: contact.id,
                  matricule: contact.id,
                  nom: contact.name.split(' ').first,
                  prenom: contact.name.split(' ').length > 1
                      ? contact.name.split(' ').sublist(1).join(' ')
                      : '',
                  avatarUrl: contact.avatarUrl,
                  isOnline: contact.isOnline,
                ),
              },
            );
          },
        );
      }).toList(),
    );
  }

  String _getDepartmentLabel(Department dept) {
    switch (dept) {
      case Department.all:
        return 'All';
      case Department.dgb:
        return 'DGB';
      case Department.dgd:
        return 'DGD';
      case Department.dgi:
        return 'DGI';
      case Department.dgt:
        return 'DGT';
      case Department.headOfBudgetService:
        return 'Head of Budget Service';
      case Department.customPostSupervisor:
        return 'Custom Post Supervisor';
    }
  }
}
