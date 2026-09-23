// ============================================================
// lib/screens/group/tabs/attendance_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/attendance_model.dart';

class AttendanceTab extends StatefulWidget {
  final GroupModel group;
  const AttendanceTab({super.key, required this.group});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final AudioPlayer _clickPlayer = AudioPlayer();

  @override
  void dispose() {
    _searchController.dispose();
    _clickPlayer.dispose();
    super.dispose();
  }

  Future<void> _playClick() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.soundEnabled) {
      await _clickPlayer.play(AssetSource('audio/Button_Click.mp3'));
    }
  }

  List<MemberModel> get _filteredMembers {
    if (_searchQuery.isEmpty) return widget.group.members;
    return widget.group.members.where((m) {
      return m.fields.values.any((v) =>
          v.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    final attendance = context.watch<AttendanceProvider>();
    final members = widget.group.members;
    final summary = attendance.getTodaySummary(
        widget.group.id, members.map((m) => m.id).toList());

    return Column(
      children: [
        // Date + Summary Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Attendance',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colors.textPrimary,
                                  ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                    // Quick actions
                    Row(
                      children: [
                        _QuickBtn(
                          label: 'All ✓',
                          color: colors.presentColor,
                          onTap: () {
                            _playClick();
                            attendance.markAll(
                              widget.group.id,
                              members.map((m) => m.id).toList(),
                              AttendanceStatus.present,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _QuickBtn(
                          label: 'All ✗',
                          color: colors.absentColor,
                          onTap: () {
                            _playClick();
                            attendance.markAll(
                              widget.group.id,
                              members.map((m) => m.id).toList(),
                              AttendanceStatus.absent,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Summary row
                Row(
                  children: [
                    _SummaryBadge(
                        count: summary['present']!,
                        label: 'Present',
                        color: colors.presentColor),
                    const SizedBox(width: 10),
                    _SummaryBadge(
                        count: summary['absent']!,
                        label: 'Absent',
                        color: colors.absentColor),
                    const SizedBox(width: 10),
                    _SummaryBadge(
                        count: summary['unset']!,
                        label: 'Not Set',
                        color: colors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: colors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // Members list
        Expanded(
          child: members.isEmpty
              ? _EmptyMembers(colors: colors)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = _filteredMembers[index];
                    final record =
                        attendance.getRecord(widget.group.id, member.id);
                    return _MemberAttendanceTile(
                      member: member,
                      record: record,
                      colors: colors,
                      onStatusChange: (status) {
                        _playClick();
                        attendance.setStatus(
                            widget.group.id, member.id, status);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MemberAttendanceTile extends StatelessWidget {
  final MemberModel member;
  final AttendanceRecord record;
  final dynamic colors;
  final Function(AttendanceStatus) onStatusChange;

  const _MemberAttendanceTile({
    required this.member,
    required this.record,
    required this.colors,
    required this.onStatusChange,
  });

  Color get _statusColor {
    switch (record.status) {
      case AttendanceStatus.present:
        return colors.presentColor;
      case AttendanceStatus.absent:
        return colors.absentColor;
      case AttendanceStatus.unset:
        return colors.unsetColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: record.status != AttendanceStatus.unset
              ? _statusColor.withOpacity(0.4)
              : colors.cardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _statusColor.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  member.initials,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (member.fields.length > 1)
                    Text(
                      member.fields.entries
                          .where((e) => e.key != 'Name')
                          .take(2)
                          .map((e) => e.value)
                          .join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (record.time != null)
                    Text(
                      'Marked at ${record.time}',
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Toggle buttons
            Row(
              children: [
                _AttendanceBtn(
                  icon: Icons.check_rounded,
                  isActive: record.status == AttendanceStatus.present,
                  activeColor: colors.presentColor,
                  inactiveColor: colors.surfaceVariant,
                  onTap: () => onStatusChange(
                      record.status == AttendanceStatus.present
                          ? AttendanceStatus.unset
                          : AttendanceStatus.present),
                ),
                const SizedBox(width: 6),
                _AttendanceBtn(
                  icon: Icons.close_rounded,
                  isActive: record.status == AttendanceStatus.absent,
                  activeColor: colors.absentColor,
                  inactiveColor: colors.surfaceVariant,
                  onTap: () => onStatusChange(
                      record.status == AttendanceStatus.absent
                          ? AttendanceStatus.unset
                          : AttendanceStatus.absent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _AttendanceBtn({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey,
          size: 18,
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryBadge(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  final dynamic colors;
  const _EmptyMembers({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_alt_1_rounded, size: 56, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No members yet',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add members in the Members tab.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
