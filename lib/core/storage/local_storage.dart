// ============================================================
// lib/core/storage/local_storage.dart
// ============================================================
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_model.dart';
import '../models/attendance_model.dart';
import '../theme/app_theme.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw Exception('LocalStorage not initialized');
    return _prefs!;
  }

  // ── Theme ──────────────────────────────────────────────────
  static AppThemeType getTheme() {
    final key = _p.getString('theme') ?? 'mystic_night';
    return AppThemeTypeExtension.fromKey(key);
  }

  static Future<void> saveTheme(AppThemeType t) async {
    await _p.setString('theme', t.storageKey);
  }

  // ── Sound & Haptics ───────────────────────────────────────
  static bool getSoundEnabled() => _p.getBool('sound_enabled') ?? true;

  static Future<void> saveSoundEnabled(bool v) async {
    await _p.setBool('sound_enabled', v);
  }

  static bool getHapticsEnabled() => _p.getBool('haptics_enabled') ?? true;

  static Future<void> saveHapticsEnabled(bool v) async {
    await _p.setBool('haptics_enabled', v);
  }

  // ── Groups ─────────────────────────────────────────────────
  static List<GroupModel> getGroups() {
    final raw = _p.getString('groups');
    if (raw == null || raw.isEmpty) return [];
    return GroupModel.listFromJson(raw);
  }

  static Future<void> saveGroups(List<GroupModel> groups) async {
    await _p.setString('groups', GroupModel.listToJson(groups));
  }

  // ── Attendance ─────────────────────────────────────────────
  static AttendanceData getAttendance() {
    final raw = _p.getString('attendance') ?? '';
    return AttendanceData.fromJson(raw);
  }

  static Future<void> saveAttendance(AttendanceData data) async {
    await _p.setString('attendance', data.toJson());
  }

  // ── Midnight reset tracking ────────────────────────────────
  static String? getLastResetDate() => _p.getString('last_reset_date');

  static Future<void> saveLastResetDate(String date) async {
    await _p.setString('last_reset_date', date);
  }

  // ── App version ────────────────────────────────────────────
  static String getVersion() => _p.getString('app_version') ?? '1.0.0';
  static Future<void> saveVersion(String v) async => _p.setString('app_version', v);

  // ── Intro shown ────────────────────────────────────────────
  static bool getIntroShown() => _p.getBool('intro_shown') ?? false;
  static Future<void> setIntroShown() async => _p.setBool('intro_shown', true);

  // ── Full Backup Export & Import ─────────────────────────────
  static String exportFullBackupJson() {
    final groups = getGroups();
    final attendance = getAttendance();
    final data = {
      'app': 'Simple Attende',
      'version': '1.0.3',
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': groups.map((g) => g.toJson()).toList(),
      'attendance': attendance.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Map<String, dynamic>? parseBackupJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      if (!map.containsKey('groups') && !map.containsKey('attendance')) {
        return null;
      }
      return map;
    } catch (_) {
      return null;
    }
  }
}
