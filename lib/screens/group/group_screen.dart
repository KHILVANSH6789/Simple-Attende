// ============================================================
// lib/screens/group/group_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/groups_provider.dart';
import '../../core/models/group_model.dart';
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
  final AudioPlayer _clickPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clickPlayer.dispose();
    super.dispose();
  }

  Future<void> _playClick() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.soundEnabled) {
      await _clickPlayer.play(AssetSource('audio/Button_Click.mp3'));
    }
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
        ],
      ),
    );
  }
}
