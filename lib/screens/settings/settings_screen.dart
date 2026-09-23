// ============================================================
// lib/screens/settings/settings_screen.dart
// ============================================================
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/update_provider.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/group_model.dart';
import '../../core/services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _githubUser = 'KHILVANSH6789';
  static const String _githubRepo = 'Simple-Attende';

  void _playClick() {
    FeedbackService.tap(context);
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

  Future<void> _exportFullBackup() async {
    _playClick();
    try {
      final jsonStr = LocalStorage.exportFullBackupJson();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/simple_attende_backup_$dateStr.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Simple Attende Backup - $dateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup export failed: $e')),
        );
      }
    }
  }

  void _showImportOptionsDialog() {
    _playClick();
    final colors = context.read<SettingsProvider>().colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import Dataset',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a previously exported Simple Attende backup file (.json) or paste the JSON text.',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.file_open_rounded, color: colors.accent),
                ),
                title: Text(
                  'Select Backup File',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Pick a .json backup file from device storage',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndImportFile();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.accentSecondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.paste_rounded, color: colors.accentSecondary),
                ),
                title: Text(
                  'Paste JSON Text',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Paste raw backup JSON directly from clipboard',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showPasteJsonDialog();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndImportFile() async {
    _playClick();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          final file = File(path);
          final content = await file.readAsString();
          _processImportJson(content);
        } else if (result.files.single.bytes != null) {
          final content = utf8.decode(result.files.single.bytes!);
          _processImportJson(content);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read file: $e')),
        );
      }
    }
  }

  void _showPasteJsonDialog() {
    _playClick();
    final colors = context.read<SettingsProvider>().colors;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Paste Backup JSON',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: '{\n  "groups": [...],\n  "attendance": "..."\n}',
              hintStyle: TextStyle(color: colors.textMuted.withOpacity(0.5)),
              filled: true,
              fillColor: colors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.cardBorder),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                _processImportJson(text);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _processImportJson(String jsonStr) {
    final parsed = LocalStorage.parseBackupJson(jsonStr);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Invalid backup JSON format. Please select a valid Simple Attende backup file.'),
        ),
      );
      return;
    }

    final rawGroups = parsed['groups'] as List<dynamic>? ?? [];
    final groupCount = rawGroups.length;

    _showImportConfirmationDialog(parsed, groupCount);
  }

  void _showImportConfirmationDialog(Map<String, dynamic> backupData, int groupCount) {
    final colors = context.read<SettingsProvider>().colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_download_rounded, color: colors.accent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Import Dataset',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup parsed successfully! Found $groupCount group(s) with attendance records.',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Import Mode:',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Merge: Adds new groups and records without deleting existing data.',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Replace All: Clears all current groups & attendance, restoring only the backup.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _applyImport(backupData, replace: true);
            },
            child: const Text('Replace All', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applyImport(backupData, replace: false);
            },
            child: const Text('Merge Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyImport(Map<String, dynamic> data, {required bool replace}) async {
    final groupsProvider = context.read<GroupsProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    try {
      final rawGroups = (data['groups'] as List<dynamic>? ?? [])
          .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final rawAttendance = data['attendance'];
      String attendanceJson = '';
      if (rawAttendance is String) {
        attendanceJson = rawAttendance;
      } else if (rawAttendance is Map) {
        attendanceJson = jsonEncode(rawAttendance);
      }

      await groupsProvider.importGroups(rawGroups, replace: replace);
      if (attendanceJson.isNotEmpty) {
        await attendanceProvider.importAttendance(attendanceJson, replace: replace);
      }

      if (mounted) {
        FeedbackService.tap(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text(
              replace
                  ? 'Data replaced successfully with ${rawGroups.length} group(s).'
                  : 'Successfully merged ${rawGroups.length} group(s) & attendance records.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Import failed: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = settings.colors;
    final groups = context.watch<GroupsProvider>().groups;
    final update = context.watch<UpdateProvider>();

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

                    // ── Sound & Haptics ────────────────────────────
                    _SectionHeader(
                        title: 'Sound & Haptics',
                        icon: Icons.volume_up_rounded,
                        colors: colors),
                    const SizedBox(height: 10),
                    _SettingsCard(
                      colors: colors,
                      child: Column(
                        children: [
                          Row(
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
                                  Text('Button clicks, saves, and intro audio',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: colors.textMuted)),
                                ],
                              ),
                              Switch(
                                value: settings.soundEnabled,
                                onChanged: (v) {
                                  FeedbackService.haptic(context);
                                  settings.setSoundEnabled(v);
                                },
                                activeTrackColor: colors.accent,
                              ),
                            ],
                          ),
                          Divider(color: colors.cardBorder, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Haptic Feedback',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(color: colors.textPrimary)),
                                  Text('Subtle vibrations on taps & interactions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: colors.textMuted)),
                                ],
                              ),
                              Switch(
                                value: settings.hapticsEnabled,
                                onChanged: (v) {
                                  settings.setHapticsEnabled(v);
                                  if (v) FeedbackService.haptic(context);
                                },
                                activeTrackColor: colors.accent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Data & Backup ──────────────────────────────
                    _SectionHeader(
                        title: 'Data & Backup',
                        icon: Icons.storage_rounded,
                        colors: colors),
                    const SizedBox(height: 10),

                    // Local storage warning banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFA000).withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFFA000),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Local Storage Warning',
                                  style: TextStyle(
                                    color: Color(0xFFFFA000),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All attendance and group records are saved locally on this device. Clearing app data or uninstalling will permanently delete all attendance data, which will be unrecoverable later. Export regular backups to prevent data loss.',
                                  style: TextStyle(
                                    color: colors.textPrimary.withOpacity(0.9),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _SettingsCard(
                      colors: colors,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Backup & Restore Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _exportFullBackup,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colors.accent.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.file_upload_rounded,
                                              color: colors.accent, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Export Backup',
                                                  style: TextStyle(
                                                      color: colors.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13)),
                                              Text('Save JSON backup',
                                                  style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _showImportOptionsDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colors.accentSecondary
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                              Icons.file_download_rounded,
                                              color: colors.accentSecondary,
                                              size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Import Dataset',
                                                  style: TextStyle(
                                                      color: colors.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13)),
                                              Text('Restore from JSON',
                                                  style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (groups.isNotEmpty) ...[
                            Divider(color: colors.cardBorder, height: 28),
                            Text(
                              'EXPORT GROUP CSV',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: groups.asMap().entries.map((entry) {
                                final i = entry.key;
                                final g = entry.value;
                                return Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Container(
                                        width: 36,
                                        height: 36,
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
                                                fontSize: 15),
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
                          ],
                        ],
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
                                  Text('Current version: v${UpdateProvider.currentVersion}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: colors.textMuted)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: update.isChecking || update.isDownloading
                                    ? null
                                    : () {
                                        _playClick();
                                        update.checkForUpdates(silent: false);
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                                child: update.isChecking
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
                          if (update.statusMessage != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                update.statusMessage!,
                                style: TextStyle(
                                    color: colors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                          if (update.hasUpdate) ...[
                            Divider(color: colors.cardBorder, height: 24),
                            if (update.isDownloading) ...[
                              Text(
                                'Downloading Simple Attende v${update.latestVersion}...',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: update.downloadProgress > 0 ? update.downloadProgress : null,
                                  backgroundColor: colors.cardBorder,
                                  color: colors.accent,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(update.downloadProgress * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (update.totalMb > 0)
                                    Text(
                                      '${update.downloadedMb.toStringAsFixed(1)} / ${update.totalMb.toStringAsFixed(1)} MB',
                                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                                    ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'v${update.latestVersion} Available',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          update.isReadyToInstall
                                              ? 'Downloaded & ready to install'
                                              : 'Tap to download & install update',
                                          style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      _playClick();
                                      if (update.isReadyToInstall) {
                                        await update.installDownloadedApk();
                                      } else {
                                        await update.downloadAndInstall();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.accent,
                                      foregroundColor: colors.onAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    icon: Icon(
                                      update.isReadyToInstall ? Icons.install_mobile_rounded : Icons.file_download_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      update.isReadyToInstall ? 'Install Now' : 'Download & Install',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                      child: Column(
                        children: [
                          Row(
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
                                      'Version ${UpdateProvider.currentVersion}',
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
                          Divider(color: colors.cardBorder, height: 28),
                          // GitHub Repository Tile
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              FeedbackService.tap(context);
                              final url = Uri.parse(
                                  'https://github.com/$_githubUser/$_githubRepo');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: colors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.code_rounded,
                                        size: 20, color: colors.accent),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GitHub Repository',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'github.com/$_githubUser/$_githubRepo',
                                          style: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.open_in_new_rounded,
                                      size: 18, color: colors.accent),
                                ],
                              ),
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
