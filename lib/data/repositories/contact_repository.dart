import 'package:ngomna_chat/data/models/contact_model.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';

class ContactRepository {
  // Mock data pour les contacts
  Future<List<Contact>> getAllContacts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Contact(
        id: '1',
        name: 'Mrs. Aichatou Bello',
        avatarUrl: AppAssets.avatar,
        department: 'DGB',
        post: 'Head of Budget Service',
        isOnline: true,
        isFrequent: false,
        lastMessage: 'ok done ...',
        lastMessageTime: '1 hr',
      ),
      Contact(
        id: '2',
        name: 'Mr. Tanyi Defosso',
        avatarUrl: AppAssets.avatar,
        department: 'DGD',
        post: 'Custom Post Supervisor',
        isOnline: false,
        isFrequent: true,
      ),
      Contact(
        id: '3',
        name: 'Mrs. Mengue Sabine',
        avatarUrl: AppAssets.avatar,
        department: 'DGB',
        post: 'Budget Analyst',
        isOnline: true,
        isFrequent: true,
      ),
      // Ajoutez plus de contacts...
    ];
  }

  Future<List<Contact>> getFrequentContacts() async {
    final allContacts = await getAllContacts();
    return allContacts.where((c) => c.isFrequent).toList();
  }

  Future<List<Contact>> getContactsByDepartment(String department) async {
    final allContacts = await getAllContacts();
    return allContacts.where((c) => c.department == department).toList();
  }

  Future<List<Contact>> searchContacts(String query) async {
    final allContacts = await getAllContacts();
    return allContacts
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
