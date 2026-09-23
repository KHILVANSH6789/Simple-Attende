// ============================================================
// lib/core/models/group_model.dart
// ============================================================
import 'dart:convert';

class GroupModel {
  final String id;
  String name;
  final DateTime createdAt;
  List<String> categories;
  List<MemberModel> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.categories,
    required this.members,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'categories': categories,
        'members': members.map((m) => m.toJson()).toList(),
      };

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
        categories: List<String>.from(json['categories'] ?? ['Name']),
        members: (json['members'] as List<dynamic>? ?? [])
            .map((m) => MemberModel.fromJson(m))
            .toList(),
      );

  static List<GroupModel> listFromJson(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => GroupModel.fromJson(e)).toList();
  }

  static String listToJson(List<GroupModel> groups) {
    return jsonEncode(groups.map((g) => g.toJson()).toList());
  }
}

class MemberModel {
  final String id;
  Map<String, String> fields;

  MemberModel({
    required this.id,
    required this.fields,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fields': fields,
      };

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'],
        fields: Map<String, String>.from(json['fields'] ?? {}),
      );

  String get displayName => fields['Name'] ?? fields.values.firstOrNull ?? 'Unknown';

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
