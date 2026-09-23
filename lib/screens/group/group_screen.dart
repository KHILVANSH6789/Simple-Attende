import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/groups_provider.dart';
import '../../core/models/group_model.dart';
import '../../core/services/sound_service.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/members_tab.dart';
import 'tabs/calendar_tab.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;
  const GroupScreen({super.key, required this.groupId});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _playClick() {
    FeedbackService.tap(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = settings.colors;
    final groups = context.watch<GroupsProvider>();
    final group = groups.getGroupById(widget.groupId);

    if (group == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 60, color: colors.textMuted),
              const SizedBox(height: 16),
              Text('Group not found',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.background, colors.backgroundGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _GroupHeader(
                group: group,
                colors: colors,
                onBack: () {
                  _playClick();
                  Navigator.pop(context);
                },
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: colors.onAccent,
                  unselectedLabelColor: colors.textMuted,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  onTap: (_) => _playClick(),
                  tabs: const [
                    Tab(text: 'Attendance'),
                    Tab(text: 'Members'),
                    Tab(text: 'Calendar'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    AttendanceTab(group: group),
                    MembersTab(group: group),
                    CalendarTab(group: group),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Group Header ───────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final GroupModel group;
  final dynamic colors;
  final VoidCallback onBack;

  const _GroupHeader({
    required this.group,
    required this.colors,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Group avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.accent, colors.accentSecondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                group.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: colors.textMuted),
            tooltip: 'Rename Group',
            onPressed: () => _showRenameDialog(context),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    FeedbackService.tap(context);
    final controller = TextEditingController(text: group.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Group',
            style: Theme.of(context).textTheme.titleLarge),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              prefixIcon: Icon(Icons.edit_rounded),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter a name';
              if (v.trim().length < 2) return 'Name too short';
              return null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                FeedbackService.save(context);
                context
                    .read<GroupsProvider>()
                    .updateGroupName(group.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                FeedbackService.save(context);
                context
                    .read<GroupsProvider>()
                    .updateGroupName(group.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
