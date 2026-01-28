import 'package:ngomna_chat/data/models/group_info_model.dart';
import 'package:ngomna_chat/data/services/api_service.dart';

class GroupRepository {
  final ApiService _apiService;

  GroupRepository(this._apiService);

  Future<GroupInfo> createGroup(GroupInfo groupInfo) async {
    // Simuler la création d'un groupe
    await Future.delayed(const Duration(seconds: 1));

    // Mock: retourner le groupe avec un ID généré
    return GroupInfo(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: groupInfo.name,
      description: groupInfo.description,
      avatarUrl: groupInfo.avatarUrl ?? 'assets/avatars/group.png',
      members: groupInfo.members,
      createdAt: DateTime.now(),
    );

    // Production: Appel API
    // final response = await _apiService.post('/groups', groupInfo.toJson());
    // return GroupInfo.fromJson(response);
  }

  Future<void> updateGroup(String groupId, GroupInfo groupInfo) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // await _apiService.put('/groups/$groupId', groupInfo.toJson());
  }

  Future<void> addMembersToGroup(String groupId, List<String> memberIds) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // await _apiService.post('/groups/$groupId/members', {'member_ids': memberIds});
  }
}
