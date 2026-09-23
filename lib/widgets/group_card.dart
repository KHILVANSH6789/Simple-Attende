// ============================================================
// lib/widgets/group_card.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/models/group_model.dart';
import '../providers/attendance_provider.dart';

class GroupCard extends StatefulWidget {
  final GroupModel group;
  final dynamic colors;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GroupCard({
    super.key,
    required this.group,
    required this.colors,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _elevAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final group = widget.group;
    final attendance = context.watch<AttendanceProvider>();
    final memberIds = group.members.map((m) => m.id).toList();
    final summary = attendance.getTodaySummary(group.id, memberIds);
    final total = group.members.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) {
          _hoverController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _hoverController.reverse(),
        child: AnimatedBuilder(
          animation: _elevAnim,
          builder: (context, child) => Transform.scale(
            scale: 1.0 - (_elevAnim.value * 0.02),
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Group avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.accent, colors.accentSecondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            group.name.isNotEmpty
                                ? group.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$total member${total == 1 ? '' : 's'} • Created ${DateFormat('MMM d').format(group.createdAt)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: colors.textMuted, size: 20),
                        color: colors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (v) {
                          if (v == 'delete') widget.onDelete();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                Text('Delete Group',
                                    style: TextStyle(
                                        color: Colors.redAccent, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (total > 0) ...[
                    const SizedBox(height: 14),
                    // Attendance progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: total > 0 ? (summary['present']! / total) : 0,
                        backgroundColor: colors.unsetColor.withOpacity(0.3),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.presentColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Today's stats
                    Row(
                      children: [
                        _StatChip(
                          label: '${summary['present']} Present',
                          color: colors.presentColor,
                          bgColor: colors.presentColor.withOpacity(0.12),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: '${summary['absent']} Absent',
                          color: colors.absentColor,
                          bgColor: colors.absentColor.withOpacity(0.12),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: '${summary['unset']} Not Set',
                          color: colors.textMuted,
                          bgColor: colors.unsetColor.withOpacity(0.12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
