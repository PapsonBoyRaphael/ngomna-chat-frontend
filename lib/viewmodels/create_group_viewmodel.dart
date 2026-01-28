import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/contact_model.dart';
import 'package:ngomna_chat/data/models/group_info_model.dart';
import 'package:ngomna_chat/data/repositories/group_repository.dart';

class CreateGroupViewModel extends ChangeNotifier {
  final GroupRepository _repository;
  final List<Contact> selectedMembers;

  String _groupName = '';
  String _groupDescription = '';
  bool _isCreating = false;
  String? _error;

  String get groupName => _groupName;
  String get groupDescription => _groupDescription;
  bool get isCreating => _isCreating;
  String? get error => _error;
  bool get isDoneEnabled =>
      _groupName.trim().isNotEmpty && _groupDescription.trim().isNotEmpty;
  int get memberCount => selectedMembers.length;

  CreateGroupViewModel(this._repository, this.selectedMembers);

  void setGroupName(String name) {
    _groupName = name;
    notifyListeners();
  }

  void setGroupDescription(String description) {
    _groupDescription = description;
    notifyListeners();
  }

  Future<GroupInfo?> createGroup() async {
    if (!isDoneEnabled) return null;

    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final groupInfo = GroupInfo(
        name: _groupName.trim(),
        description: _groupDescription.trim(),
        members: selectedMembers,
      );

      final createdGroup = await _repository.createGroup(groupInfo);

      _isCreating = false;
      notifyListeners();

      return createdGroup;
    } catch (e) {
      _error = e.toString();
      _isCreating = false;
      notifyListeners();
      return null;
    }
  }
}
