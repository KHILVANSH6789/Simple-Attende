// ============================================================
// lib/screens/group/tabs/calendar_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/services/sound_service.dart';

class CalendarTab extends StatefulWidget {
  final GroupModel group;
  const CalendarTab({super.key, required this.group});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  // Member filter: null = All Members, or member id
  String? _selectedMemberId;

  // Period filter for single-member view: 'Weekly', 'Monthly', 'Yearly'
  String _selectedPeriod = 'Weekly';

  Future<void> _dialPhone(String phone) async {
    FeedbackService.tap(context);
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    final attendance = context.watch<AttendanceProvider>();
    final gp = context.watch<GroupsProvider>();
    final group = gp.getGroupById(widget.group.id) ?? widget.group;

    final selectedMember = _selectedMemberId != null
        ? group.members.where((m) => m.id == _selectedMemberId).firstOrNull
        : null;

    final datesWithData = _selectedMemberId == null
        ? attendance.getDatesWithData(group.id)
        : attendance.getDatesWithDataForMember(group.id, _selectedMemberId!);

    // Build day records for selected day
    final selectedStr = _dateFormat.format(_selectedDay);
    final dayRecords = attendance.getDayRecords(group.id, selectedStr);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Member Filter Bar ────────────────────────────────────
          _buildMemberFilterBar(group, colors),

          // ── If Single Member: Period Stats Card ──────────────────
          if (selectedMember != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _buildMemberPeriodCard(
                group,
                selectedMember,
                attendance,
                colors,
              ),
            ),
          ],

          // ── Calendar Container ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.cardBorder),
              ),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) {
                  FeedbackService.tap(context);
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  setState(() {
                    _focusedDay = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  defaultTextStyle:
                      TextStyle(color: colors.textPrimary, fontSize: 14),
                  weekendTextStyle:
                      TextStyle(color: colors.textSecondary, fontSize: 14),
                  selectedDecoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                      color: colors.accent, fontWeight: FontWeight.w700),
                  selectedTextStyle: TextStyle(
                      color: colors.onAccent, fontWeight: FontWeight.w700),
                  outsideTextStyle: TextStyle(
                      color: colors.textMuted.withValues(alpha: 0.4)),
                  markerDecoration: BoxDecoration(
                    color: colors.accentSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded,
                      color: colors.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded,
                      color: colors.textSecondary),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle:
                      TextStyle(color: colors.textMuted, fontSize: 12),
                  weekendStyle:
                      TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final dateStr = _dateFormat.format(day);
                    final hasData = datesWithData
                        .any((d) => _dateFormat.format(d) == dateStr);
                    if (!hasData) return const SizedBox.shrink();

                    Color markerColor;

                    if (selectedMember != null) {
                      // Status of this single member
                      final rec = attendance.getRecordForDate(
                          group.id, selectedMember.id, dateStr);
                      if (rec.status == AttendanceStatus.present) {
                        markerColor = colors.presentColor;
                      } else if (rec.status == AttendanceStatus.absent) {
                        markerColor = colors.absentColor;
                      } else {
                        return const SizedBox.shrink();
                      }
                    } else {
                      // Overview for all members
                      final recs = attendance.getDayRecords(group.id, dateStr);
                      int p = 0, a = 0;
                      for (final m in group.members) {
                        final status =
                            recs[m.id]?.status ?? AttendanceStatus.unset;
                        if (status == AttendanceStatus.present) p++;
                        if (status == AttendanceStatus.absent) a++;
                      }
                      if (group.members.isEmpty) {
                        markerColor = colors.textMuted;
                      } else if (p == group.members.length) {
                        markerColor = colors.presentColor;
                      } else if (a == group.members.length) {
                        markerColor = colors.absentColor;
                      } else {
                        markerColor = Colors.orange;
                      }
                    }

                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Selected Day Section ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: colors.accent),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(_selectedDay),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── When Single Member is selected: Single Member Day Detail ─
                if (selectedMember != null) ...[
                  _buildSingleMemberDayDetail(
                    group,
                    selectedMember,
                    attendance,
                    selectedStr,
                    colors,
                  ),
                  const SizedBox(height: 16),
                  _buildMemberPeriodHistory(
                    group,
                    selectedMember,
                    attendance,
                    colors,
                  ),
                ] else ...[
                  // ── When All Members: Group Summary Cards & List ──────
                  _buildAllMembersDayDetail(
                    group,
                    dayRecords,
                    colors,
                  ),
                ],

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Member Filter Horizontal Bar ──────────────────────────────
  Widget _buildMemberFilterBar(GroupModel group, dynamic colors) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          // "All Members" chip
          _FilterChip(
            label: 'All Members (${group.members.length})',
            icon: Icons.groups_rounded,
            isSelected: _selectedMemberId == null,
            colors: colors,
            onTap: () {
              FeedbackService.tap(context);
              setState(() => _selectedMemberId = null);
            },
          ),
          const SizedBox(width: 8),
          // Each member chip
          ...group.members.map((m) {
            final isSelected = _selectedMemberId == m.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: m.displayName,
                icon: Icons.person_rounded,
                isSelected: isSelected,
                colors: colors,
                onTap: () {
                  FeedbackService.tap(context);
                  setState(() => _selectedMemberId = m.id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Single Member Period Card (Weekly / Monthly / Yearly) ──────
  Widget _buildMemberPeriodCard(GroupModel group, MemberModel member,
      AttendanceProvider attendance, dynamic colors) {
    final stats = attendance.getMemberPeriodStats(
      group.id,
      member.id,
      _focusedDay,
      _selectedPeriod,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Member info + Quick Call
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
                      member.displayName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (member.phoneNumber != null)
                      Text(
                        member.phoneNumber!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (member.phoneNumber != null)
                IconButton(
                  icon: const Icon(Icons.phone_in_talk_rounded,
                      color: Colors.greenAccent, size: 22),
                  tooltip: 'Call ${member.displayName}',
                  onPressed: () => _dialPhone(member.phoneNumber!),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Period Toggle: Weekly | Monthly | Yearly
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                final isSelected = _selectedPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FeedbackService.tap(context);
                      setState(() => _selectedPeriod = period);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isSelected ? colors.onAccent : colors.textMuted,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _DaySummaryCard(
                count: stats['present'] as int,
                label: 'Present',
                color: colors.presentColor,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _DaySummaryCard(
                count: stats['absent'] as int,
                label: 'Absent',
                color: colors.absentColor,
                colors: colors,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stats['rate']}%',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Attendance',
                        style: TextStyle(
                          color: colors.accent.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Single Member Detail on Selected Day ──────────────────────
  Widget _buildSingleMemberDayDetail(
    GroupModel group,
    MemberModel member,
    AttendanceProvider attendance,
    String selectedStr,
    dynamic colors,
  ) {
    final rec = attendance.getRecordForDate(group.id, member.id, selectedStr);
    final status = rec.status;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case AttendanceStatus.present:
        statusColor = colors.presentColor;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Present';
        break;
      case AttendanceStatus.absent:
        statusColor = colors.absentColor;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Absent';
        break;
      case AttendanceStatus.unset:
        statusColor = colors.textMuted;
        statusIcon = Icons.radio_button_unchecked_rounded;
        statusLabel = 'Not Recorded';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status != AttendanceStatus.unset
              ? statusColor.withValues(alpha: 0.3)
              : colors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (rec.time != null)
                  Text(
                    'Recorded at ${rec.time}',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (status == AttendanceStatus.absent &&
              member.phoneNumber != null) ...[
            ElevatedButton.icon(
              onPressed: () => _dialPhone(member.phoneNumber!),
              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
              label: const Text('Call Member'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── History for Single Member in Selected Period ──────────────
  Widget _buildMemberPeriodHistory(GroupModel group, MemberModel member,
      AttendanceProvider attendance, dynamic colors) {
    final stats = attendance.getMemberPeriodStats(
      group.id,
      member.id,
      _focusedDay,
      _selectedPeriod,
    );
    final records =
        stats['records'] as Map<String, AttendanceRecord>? ?? {};

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No records found for this $_selectedPeriod period.',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    // Sort descending by date
    final sortedKeys = records.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedPeriod Attendance History',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...sortedKeys.map((dateStr) {
          final rec = records[dateStr]!;
          final isPresent = rec.status == AttendanceStatus.present;
          final color = isPresent ? colors.presentColor : colors.absentColor;

          DateTime? parsedDate;
          try {
            parsedDate = _dateFormat.parse(dateStr);
          } catch (_) {}

          final displayDate = parsedDate != null
              ? DateFormat('EEE, MMM d, y').format(parsedDate)
              : dateStr;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  isPresent
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayDate,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (rec.time != null) ...[
                  Text(
                    ' • ${rec.time}',
                    style:
                        TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ],
                if (!isPresent && member.phoneNumber != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _dialPhone(member.phoneNumber!),
                    child: const Icon(Icons.phone_in_talk_rounded,
                        size: 16, color: Colors.greenAccent),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── All Members Day Detail ────────────────────────────────────
  Widget _buildAllMembersDayDetail(
    GroupModel group,
    Map<String, AttendanceRecord> dayRecords,
    dynamic colors,
  ) {
    int present = 0, absent = 0, unset = 0;
    for (final m in group.members) {
      final rec = dayRecords[m.id];
      switch (rec?.status ?? AttendanceStatus.unset) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.unset:
          unset++;
          break;
      }
    }
    final total = group.members.length;

    return Column(
      children: [
        if (total > 0) ...[
          Row(
            children: [
              _DaySummaryCard(
                count: present,
                label: 'Present',
                color: colors.presentColor,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _DaySummaryCard(
                count: absent,
                label: 'Absent',
                color: colors.absentColor,
                colors: colors,
              ),
              const SizedBox(width: 8),
              _DaySummaryCard(
                count: unset,
                label: 'Not Set',
                color: colors.textMuted,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        if (group.members.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No members in this group.',
                style: TextStyle(color: colors.textMuted),
              ),
            ),
          )
        else
          Column(
            children: group.members.map((member) {
              final rec = dayRecords[member.id];
              final status = rec?.status ?? AttendanceStatus.unset;
              Color statusColor;
              IconData statusIcon;
              String statusLabel;
              switch (status) {
                case AttendanceStatus.present:
                  statusColor = colors.presentColor;
                  statusIcon = Icons.check_circle_rounded;
                  statusLabel = 'Present';
                  break;
                case AttendanceStatus.absent:
                  statusColor = colors.absentColor;
                  statusIcon = Icons.cancel_rounded;
                  statusLabel = 'Absent';
                  break;
                case AttendanceStatus.unset:
                  statusColor = colors.textMuted;
                  statusIcon = Icons.radio_button_unchecked_rounded;
                  statusLabel = 'Not Set';
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status != AttendanceStatus.unset
                        ? statusColor.withValues(alpha: 0.3)
                        : colors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          member.initials,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          if (member.phoneNumber != null)
                            Text(
                              member.phoneNumber!,
                              style: TextStyle(
                                  color: colors.textMuted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    if (rec?.time != null) ...[
                      Text(
                        '  •  ${rec!.time}',
                        style: TextStyle(
                            color: colors.textMuted, fontSize: 11),
                      ),
                    ],
                    if (status == AttendanceStatus.absent &&
                        member.phoneNumber != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.phone_in_talk_rounded,
                            size: 18, color: Colors.greenAccent),
                        tooltip: 'Call ${member.displayName}',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _dialPhone(member.phoneNumber!),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ── Filter Chip Widget ─────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final dynamic colors;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent
              : colors.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accent : colors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.onAccent : colors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.onAccent : colors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Card Widget ────────────────────────────────────────
class _DaySummaryCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final dynamic colors;

  const _DaySummaryCard({
    required this.count,
    required this.label,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
