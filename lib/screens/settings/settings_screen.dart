// ============================================================
// lib/screens/settings/settings_screen.dart
// ============================================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/group_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _updateStatus = '';
  bool _checkingUpdate = false;
  final AudioPlayer _clickPlayer = AudioPlayer();

  static const String _currentVersion = '1.0.0';
  static const String _githubUser = 'KHILVANSH6789';
  static const String _githubRepo = 'Simple-Attende';

  @override
  void dispose() {
    _clickPlayer.dispose();
    super.dispose();
  }

  Future<void> _playClick() async {
    final s = Provider.of<SettingsProvider>(context, listen: false);
    if (s.soundEnabled) await _clickPlayer.play(AssetSource('audio/Button_Click.mp3'));
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingUpdate = true;
      _updateStatus = '';
    });
    try {
      final response = await http
          .get(Uri.parse(
              'https://api.github.com/repos/$_githubUser/$_githubRepo/releases/latest'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        // Parse version from response
        final tag = RegExp(r'"tag_name":"([^"]+)"')
            .firstMatch(response.body)
            ?.group(1)
            ?.replaceAll('v', '') ?? '';
        if (tag.isNotEmpty && tag != _currentVersion) {
          setState(() => _updateStatus = '🎉 New version v$tag available!');
        } else {
          setState(() => _updateStatus = '✓ You\'re on the latest version.');
        }
      } else {
        setState(() => _updateStatus = 'Could not check for updates.');
      }
    } catch (e) {
      setState(() => _updateStatus = 'Check your internet connection.');
    } finally {
      setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _exportGroup(GroupModel group) async {
    _playClick();
    final attendance = context.read<AttendanceProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final csv = attendance.exportGroupCsv(
        group.id, group.name, group.members, dateStr);
    try {
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/attendance_${group.name}_$dateStr.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance - ${group.name} - $dateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = settings.colors;
    final groups = context.watch<GroupsProvider>().groups;

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
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () {
                    _playClick();
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: colors.textPrimary, size: 20),
                  ),
                ),
                title: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                      ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Theme ──────────────────────────────────────
                    _SectionHeader(
                        title: 'Appearance', icon: Icons.palette_rounded, colors: colors),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      colors: colors,
                      child: Column(
                        children: AppThemeType.values.map((t) {
                          return _ThemeTile(
                            type: t,
                            isSelected: settings.themeType == t,
                            colors: colors,
                            onTap: () {
                              _playClick();
                              settings.setTheme(t);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Sound ──────────────────────────────────────
                    _SectionHeader(
                        title: 'Sound', icon: Icons.volume_up_rounded, colors: colors),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      colors: colors,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sound Effects',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: colors.textPrimary)),
                              Text('Button clicks, saves, and intro',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: colors.textMuted)),
                            ],
                          ),
                          Switch(
                            value: settings.soundEnabled,
                            onChanged: (v) {
                              settings.setSoundEnabled(v);
                            },
                            activeColor: colors.accent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Export ──────────────────────────────────────
                    _SectionHeader(
                        title: 'Export Data',
                        icon: Icons.file_download_rounded,
                        colors: colors),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      colors: colors,
                      child: groups.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No groups to export.',
                                style: TextStyle(color: colors.textMuted),
                              ),
                            )
                          : Column(
                              children: groups.asMap().entries.map((entry) {
                                final i = entry.key;
                                final g = entry.value;
                                return Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                            colors.accent,
                                            colors.accentSecondary
                                          ]),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            g.name[0].toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                      title: Text(g.name,
                                          style: TextStyle(
                                              color: colors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(
                                          '${g.members.length} members',
                                          style: TextStyle(
                                              color: colors.textMuted,
                                              fontSize: 12)),
                                      trailing: TextButton.icon(
                                        onPressed: () => _exportGroup(g),
                                        icon: Icon(Icons.ios_share_rounded,
                                            size: 16, color: colors.accent),
                                        label: Text('CSV',
                                            style: TextStyle(
                                                color: colors.accent,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    if (i < groups.length - 1)
                                      Divider(
                                          color: colors.divider, height: 1),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // ── Update ──────────────────────────────────────
                    _SectionHeader(
                        title: 'Updates',
                        icon: Icons.system_update_alt_rounded,
                        colors: colors),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Auto-Update',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(color: colors.textPrimary)),
                                  Text('Current version: v$_currentVersion',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: colors.textMuted)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed:
                                    _checkingUpdate ? null : _checkForUpdates,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                                child: _checkingUpdate
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colors.onAccent))
                                    : const Text('Check'),
                              ),
                            ],
                          ),
                          if (_updateStatus.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _updateStatus,
                                style: TextStyle(
                                    color: colors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── About ──────────────────────────────────────
                    _SectionHeader(
                        title: 'About', icon: Icons.info_outline_rounded, colors: colors),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      colors: colors,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/SimpleAttende_AppIcon.png',
                              width: 52,
                              height: 52,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Simple Attende',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: colors.textPrimary),
                                ),
                                Text(
                                  'Version $_currentVersion',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: colors.textMuted),
                                ),
                                Text(
                                  'Attendance, simplified.',
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
                    ),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme Tile ─────────────────────────────────────────────────
class _ThemeTile extends StatelessWidget {
  final AppThemeType type;
  final bool isSelected;
  final dynamic colors;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.type,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  static const Map<AppThemeType, List<Color>> _swatches = {
    AppThemeType.mysticNight: [
      Color(0xFF0D0F1A),
      Color(0xFF7C6BFF),
      Color(0xFFB06BFF),
    ],
    AppThemeType.cottonCandy: [
      Color(0xFFFFF0F5),
      Color(0xFFF06292),
      Color(0xFFEC407A),
    ],
    AppThemeType.skyBlue: [
      Color(0xFFE3F2FD),
      Color(0xFF42A5F5),
      Color(0xFF1E88E5),
    ],
  };

  static const Map<AppThemeType, IconData> _icons = {
    AppThemeType.mysticNight: Icons.nights_stay_rounded,
    AppThemeType.cottonCandy: Icons.favorite_rounded,
    AppThemeType.skyBlue: Icons.wb_sunny_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final swatches = _swatches[type]!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accent : colors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_icons[type], color: swatches[1], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type.displayName,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            // Color swatches preview
            Row(
              children: swatches.map((c) {
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.divider, width: 1),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: colors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final dynamic colors;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.accent),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: colors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Settings Card ──────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final Widget child;
  final dynamic colors;

  const _SettingsCard({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: child,
    );
  }
}
