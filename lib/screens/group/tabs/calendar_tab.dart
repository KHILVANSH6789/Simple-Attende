// ============================================================
// lib/screens/group/tabs/calendar_tab.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/attendance_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    final attendance = context.watch<AttendanceProvider>();
    final gp = context.watch<GroupsProvider>();
    final group = gp.getGroupById(widget.group.id) ?? widget.group;

    final datesWithData = attendance.getDatesWithData(group.id);

    // Build day records for selected day
    final selectedStr = _dateFormat.format(_selectedDay);
    final dayRecords = attendance.getDayRecords(group.id, selectedStr);

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

    return SingleChildScrollView(
      child: Column(
        children: [
          // Calendar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  _focusedDay = focused;
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
                    color: colors.accent.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle:
                      TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
                  selectedTextStyle: TextStyle(
                      color: colors.onAccent, fontWeight: FontWeight.w700),
                  outsideTextStyle:
                      TextStyle(color: colors.textMuted.withOpacity(0.4)),
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
                  leftChevronIcon:
                      Icon(Icons.chevron_left_rounded, color: colors.textSecondary),
                  rightChevronIcon: Icon(
                      Icons.chevron_right_rounded, color: colors.textSecondary),
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

                    final recs = attendance.getDayRecords(group.id, dateStr);
                    int p = 0, a = 0;
                    for (final m in group.members) {
                      final status =
                          recs[m.id]?.status ?? AttendanceStatus.unset;
                      if (status == AttendanceStatus.present) p++;
                      if (status == AttendanceStatus.absent) a++;
                    }
                    Color markerColor;
                    if (total == 0) {
                      markerColor = colors.textMuted;
                    } else if (p == total) {
                      markerColor = colors.presentColor;
                    } else if (a == total) {
                      markerColor = colors.absentColor;
                    } else {
                      markerColor = Colors.orange;
                    }

                    return Positioned(
                      bottom: 2,
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

          const SizedBox(height: 12),

          // Selected day summary
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
                // Summary cards
                if (total > 0) ...[
                  Row(
                    children: [
                      _DaySummaryCard(
                          count: present,
                          label: 'Present',
                          color: colors.presentColor,
                          colors: colors),
                      const SizedBox(width: 8),
                      _DaySummaryCard(
                          count: absent,
                          label: 'Absent',
                          color: colors.absentColor,
                          colors: colors),
                      const SizedBox(width: 8),
                      _DaySummaryCard(
                          count: unset,
                          label: 'Not Set',
                          color: colors.textMuted,
                          colors: colors),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Member detail list for selected day
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
                      final status =
                          rec?.status ?? AttendanceStatus.unset;
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
                                ? statusColor.withOpacity(0.3)
                                : colors.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
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
                              child: Text(
                                member.displayName,
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
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
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
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
