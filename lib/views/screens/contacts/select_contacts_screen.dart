import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngomna_chat/viewmodels/select_contacts_viewmodel.dart';
import 'package:ngomna_chat/data/repositories/contact_repository.dart';
import 'package:ngomna_chat/views/widgets/contacts/selectable_contact_tile.dart';
import 'package:ngomna_chat/views/widgets/contacts/select_contacts_top_bar.dart';
import 'package:ngomna_chat/views/widgets/common/section_title.dart';
import 'package:ngomna_chat/core/routes/app_routes.dart';

class SelectContactsScreen extends StatelessWidget {
  final SelectMode mode;

  const SelectContactsScreen({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectContactsViewModel(
        ContactRepository(),
        mode,
      )..loadContacts(),
      child: _SelectContactsContent(mode: mode),
    );
  }
}

class _SelectContactsContent extends StatelessWidget {
  final SelectMode mode;

  const _SelectContactsContent({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<SelectContactsViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            children: [
              SelectContactsTopBar(
                mode: mode,
                isNextEnabled: viewModel.hasSelection,
                onCancel: () => Navigator.pop(context),
                onNext: () => _handleNext(context, viewModel),
                onSearch: (query) => viewModel.searchContacts(query),
              ),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContactsList(context, viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactsList(
    BuildContext context,
    SelectContactsViewModel viewModel,
  ) {
    // Séparer les contacts fréquents et du service
    final frequentContacts =
        viewModel.filteredContacts.where((c) => c.isFrequent).toList();
    final serviceContacts =
        viewModel.filteredContacts.where((c) => !c.isFrequent).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      children: [
        const SizedBox(height: 15),

        // Frequent conversations
        if (frequentContacts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: SectionTitle(title: 'Frequent conversations'),
          ),
          const SizedBox(height: 10),
          ...frequentContacts.map((contact) {
            return SelectableContactTile(
              contact: contact,
              isSelected: viewModel.isContactSelected(contact.id),
              isGroup: contact.name.contains('GROUP') ||
                  contact.name.contains('PROJECT'),
              onTap: () => viewModel.toggleContact(contact.id),
            );
          }),
          const SizedBox(height: 20),
        ],

        // My service
        if (serviceContacts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: SectionTitle(title: 'My service'),
          ),
          const SizedBox(height: 10),
          ...serviceContacts.map((contact) {
            return SelectableContactTile(
              contact: contact,
              isSelected: viewModel.isContactSelected(contact.id),
              onTap: () => viewModel.toggleContact(contact.id),
            );
          }),
        ],
      ],
    );
  }

  void _handleNext(
    BuildContext context,
    SelectContactsViewModel viewModel,
  ) {
    if (!viewModel.hasSelection) return;

    if (mode == SelectMode.broadcast) {
      // Créer directement le broadcast et aller au chat
      Navigator.pushNamed(
        context,
        AppRoutes.chatBroadcast,
        arguments: {
          'broadcastId': 'new_broadcast',
          'broadcastName': 'New Broadcast', // Ajoutez un nom par défaut
          'selectedContacts': viewModel.selectedContacts,
        },
      );
    } else {
      // Aller à l'écran de création de groupe
      Navigator.pushNamed(
        context,
        AppRoutes.createGroup,
        arguments: {
          'selectedContacts': viewModel.selectedContacts,
        },
      );
    }
  }
}
