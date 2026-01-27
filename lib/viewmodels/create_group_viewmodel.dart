import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';

class CreateGroupViewModel extends ChangeNotifier {
  final List<Contact> selectedContacts;
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController =
      TextEditingController();
  String get groupId => _groupId;
  late final String _groupId;

  CreateGroupViewModel(List<Contact> selectedContacts)
      : selectedContacts = selectedContacts {
    _groupId = _generateGroupId();
  }

  String _generateGroupId() {
    // Logic to generate a unique group ID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool get isDoneEnabled =>
      groupNameController.text.isNotEmpty &&
      groupDescriptionController.text.isNotEmpty;

  @override
  void dispose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.dispose();
  }
}
