// ============================================================
// lib/screens/group/tabs/members_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../core/models/group_model.dart';
import '../../../core/services/sound_service.dart';

class MembersTab extends StatefulWidget {
  final GroupModel group;
  const MembersTab({super.key, required this.group});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _playClick() {
    FeedbackService.tap(context);
  }

  void _playSave() {
    FeedbackService.save(context);
  }

  List<MemberModel> get _filteredMembers {
    if (_searchQuery.isEmpty) return widget.group.members;
    return widget.group.members
        .where((m) => m.fields.values
            .any((v) => v.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  void _showAddMemberDialog({MemberModel? existing}) {
    _playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberFormSheet(
        group: widget.group,
        existing: existing,
        onSave: _playSave,
      ),
    );
  }

  void _showCategoryManager() {
    _playClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryManagerSheet(group: widget.group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    final groups = context.watch<GroupsProvider>();
    // Re-read the group from provider (it may have changed)
    final group = groups.getGroupById(widget.group.id) ?? widget.group;

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: colors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: colors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Category manager
              _ToolBtn(
                icon: Icons.tune_rounded,
                colors: colors,
                tooltip: 'Manage Categories',
                onTap: _showCategoryManager,
              ),
              const SizedBox(width: 8),
              // Add member
              _ToolBtn(
                icon: Icons.person_add_rounded,
                colors: colors,
                tooltip: 'Add Member',
                isAccent: true,
                onTap: () => _showAddMemberDialog(),
              ),
            ],
          ),
        ),

        // Category chips
        if (group.categories.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: group.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  group.categories[i],
                  style: TextStyle(
                      color: colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

        const SizedBox(height: 6),

        // Member list
        Expanded(
          child: group.members.isEmpty
              ? _EmptyMembers(colors: colors, onAdd: () => _showAddMemberDialog())
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = _filteredMembers[index];
                    return _MemberCard(
                      member: member,
                      group: group,
                      colors: colors,
                      onEdit: () => _showAddMemberDialog(existing: member),
                      onDelete: () {
                        _playClick();
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Member'),
                            content: Text(
                                'Remove ${member.displayName} from this group?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context
                                      .read<GroupsProvider>()
                                      .deleteMember(group.id, member.id);
                                },
                                child: const Text('Delete',
                                    style:
                                        TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Member Card ───────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final GroupModel group;
  final dynamic colors;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.group,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.accent, colors.accentSecondary],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Fields
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final cat in group.categories)
                    if (member.fields[cat] != null &&
                        member.fields[cat]!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Text(
                              '$cat: ',
                              style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: Text(
                                member.fields[cat]!,
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(Icons.edit_rounded,
                      color: colors.accent, size: 20),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline_rounded,
                      color: colors.absentColor, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Form Bottom Sheet ───────────────────────────────────
class _MemberFormSheet extends StatefulWidget {
  final GroupModel group;
  final MemberModel? existing;
  final VoidCallback onSave;

  const _MemberFormSheet({
    required this.group,
    this.existing,
    required this.onSave,
  });

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final cat in widget.group.categories)
        cat: TextEditingController(
            text: widget.existing?.fields[cat] ?? '')
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FeedbackService.save(context);
    final fields = {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim()
    };
    final gp = context.read<GroupsProvider>();
    if (widget.existing != null) {
      await gp.updateMember(widget.group.id, widget.existing!.id, fields);
    } else {
      await gp.addMember(widget.group.id, fields);
    }
    widget.onSave();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing != null ? 'Edit Member' : 'Add Member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final cat in widget.group.categories) ...[
                TextFormField(
                  controller: _controllers[cat],
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: cat,
                    prefixIcon: Icon(_categoryIcon(cat)),
                  ),
                  validator: cat == 'Name'
                      ? (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        }
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                      widget.existing != null ? 'Update Member' : 'Add Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'name':
        return Icons.person_rounded;
      case 'age':
        return Icons.cake_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'address':
        return Icons.location_on_rounded;
      case 'email':
        return Icons.email_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

// ── Category Manager ───────────────────────────────────────────
class _CategoryManagerSheet extends StatefulWidget {
  final GroupModel group;
  const _CategoryManagerSheet({required this.group});

  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  final _newCatController = TextEditingController();

  @override
  void dispose() {
    _newCatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    final gp = context.watch<GroupsProvider>();
    final group = gp.getGroupById(widget.group.id) ?? widget.group;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Manage Categories',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add or remove fields for member data.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            // Existing categories
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.categories.map((cat) {
                final isProtected = cat == 'Name';
                return Chip(
                  label: Text(cat),
                  deleteIcon: isProtected
                      ? null
                      : Icon(Icons.close_rounded, size: 16),
                  onDeleted: isProtected
                      ? null
                      : () => context
                          .read<GroupsProvider>()
                          .removeCategory(group.id, cat),
                  backgroundColor: colors.accent.withOpacity(0.1),
                  side: BorderSide(color: colors.accent.withOpacity(0.3)),
                  labelStyle:
                      TextStyle(color: colors.accent, fontSize: 13),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Add new category
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCatController,
                    decoration: const InputDecoration(
                      labelText: 'New Category',
                      hintText: 'e.g. Email, Room No.',
                      prefixIcon: Icon(Icons.add_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final cat = _newCatController.text.trim();
                    if (cat.isNotEmpty) {
                      context
                          .read<GroupsProvider>()
                          .addCategory(group.id, cat);
                      _newCatController.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tool Button ────────────────────────────────────────────────
class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final dynamic colors;
  final String tooltip;
  final bool isAccent;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.colors,
    required this.tooltip,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isAccent
                ? colors.accent
                : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Icon(
            icon,
            color: isAccent ? colors.onAccent : colors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyMembers extends StatelessWidget {
  final dynamic colors;
  final VoidCallback onAdd;

  const _EmptyMembers({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.group_add_rounded, size: 40, color: colors.accent),
          ),
          const SizedBox(height: 16),
          Text('No members yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('Add your first member to start tracking attendance.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Member'),
          ),
        ],
      ),
    );
  }
}
