import 'package:ngomna_chat/data/models/contact_model.dart';

class GroupInfo {
  final String? id;
  final String name;
  final String description;
  final String? avatarUrl;
  final List<Contact> members;
  final DateTime? createdAt;

  GroupInfo({
    this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.members,
    this.createdAt,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      members:
          (json['members'] as List).map((m) => Contact.fromJson(m)).toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'members': members.map((m) => m.id).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
