// ============================================================
// lib/providers/groups_provider.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/models/group_model.dart';
import '../core/storage/local_storage.dart';

class GroupsProvider extends ChangeNotifier {
  List<GroupModel> _groups = [];
  final _uuid = const Uuid();

  GroupsProvider() {
    _groups = LocalStorage.getGroups();
  }

  List<GroupModel> get groups => List.unmodifiable(_groups);

  GroupModel? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<GroupModel> createGroup(String name) async {
    final group = GroupModel(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      categories: ['Name', 'Age', 'Phone', 'Address'],
      members: [],
    );
    _groups.add(group);
    await _save();
    notifyListeners();
    return group;
  }

  Future<void> updateGroupName(String groupId, String name) async {
    final g = _groups.firstWhere((g) => g.id == groupId);
    g.name = name;
    await _save();
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    await _save();
    notifyListeners();
  }

  Future<void> addCategory(String groupId, String category) async {
    final g = _groups.firstWhere((g) => g.id == groupId);
    if (!g.categories.contains(category)) {
      g.categories.add(category);
      await _save();
      notifyListeners();
    }
  }

  Future<void> removeCategory(String groupId, String category) async {
    final g = _groups.firstWhere((g) => g.id == groupId);
    g.categories.remove(category);
    // Remove field from all members
    for (final m in g.members) {
      m.fields.remove(category);
    }
    await _save();
    notifyListeners();
  }

  Future<MemberModel> addMember(
      String groupId, Map<String, String> fields) async {
    final g = _groups.firstWhere((g) => g.id == groupId);
    final member = MemberModel(id: _uuid.v4(), fields: fields);
    g.members.add(member);
    await _save();
    notifyListeners();
    return member;
  }

  Future<void> updateMember(
      String groupId, String memberId, Map<String, String> fields) async {
    final g = _groups.firstWhere((g) => g.id == groupId);
    final m = g.members.firstWhere((m) => m.id == memberId);
    m.fields = fields;
    await _save();
    notifyListeners();
  }

  Future<void> deleteMember(String groupId, String memberId) async {
    final g = _groups.firstWhere((g) => g.id == groupId);
    g.members.removeWhere((m) => m.id == memberId);
    await _save();
    notifyListeners();
  }

  Future<int> importGroups(List<GroupModel> imported, {bool replace = false}) async {
    if (replace) {
      _groups = imported;
    } else {
      for (final ig in imported) {
        final existingIndex = _groups.indexWhere((g) => g.id == ig.id);
        if (existingIndex >= 0) {
          final existing = _groups[existingIndex];
          existing.name = ig.name;
          for (final cat in ig.categories) {
            if (!existing.categories.contains(cat)) existing.categories.add(cat);
          }
          for (final im in ig.members) {
            final mIndex = existing.members.indexWhere((m) => m.id == im.id);
            if (mIndex >= 0) {
              existing.members[mIndex] = im;
            } else {
              existing.members.add(im);
            }
          }
        } else {
          _groups.add(ig);
        }
      }
    }
    await _save();
    notifyListeners();
    return imported.length;
  }

  Future<void> reload() async {
    _groups = LocalStorage.getGroups();
    notifyListeners();
  }

  Future<void> _save() async {
    await LocalStorage.saveGroups(_groups);
  }
}
