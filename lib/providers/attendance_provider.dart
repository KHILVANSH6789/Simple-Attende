// ============================================================
// lib/providers/attendance_provider.dart
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/models/attendance_model.dart';
import '../core/storage/local_storage.dart';

class AttendanceProvider extends ChangeNotifier {
  late AttendanceData _data;
  Timer? _midnightTimer;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  AttendanceProvider() {
    _data = LocalStorage.getAttendance();
    _checkAndResetIfNewDay();
    _scheduleMidnightReset();
  }

  String get todayStr => _dateFormat.format(DateTime.now());

  AttendanceRecord getRecord(String groupId, String memberId) {
    return _data.getRecord(groupId, todayStr, memberId);
  }

  AttendanceRecord getRecordForDate(
      String groupId, String memberId, String dateStr) {
    return _data.getRecord(groupId, dateStr, memberId);
  }

  Map<String, AttendanceRecord> getDayRecords(String groupId, String dateStr) {
    return _data.getDayRecords(groupId, dateStr);
  }

  Future<void> setStatus(
      String groupId, String memberId, AttendanceStatus status) async {
    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    _data.setRecord(
      groupId,
      todayStr,
      memberId,
      AttendanceRecord(
          status: status,
          time: status != AttendanceStatus.unset ? timeStr : null),
    );
    await LocalStorage.saveAttendance(_data);
    notifyListeners();
  }

  Future<void> markAll(
      String groupId, List<String> memberIds, AttendanceStatus status) async {
    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    for (final mId in memberIds) {
      _data.setRecord(
        groupId,
        todayStr,
        mId,
        AttendanceRecord(
            status: status,
            time: status != AttendanceStatus.unset ? timeStr : null),
      );
    }
    await LocalStorage.saveAttendance(_data);
    notifyListeners();
  }

  // Count present/absent for today in a group
  Map<String, int> getTodaySummary(String groupId, List<String> memberIds) {
    int present = 0, absent = 0, unset = 0;
    for (final mId in memberIds) {
      final rec = _data.getRecord(groupId, todayStr, mId);
      switch (rec.status) {
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
    return {'present': present, 'absent': absent, 'unset': unset};
  }

  // Returns set of dates that have any attendance recorded for a group
  Set<DateTime> getDatesWithData(String groupId) {
    final groupData = _data.data[groupId];
    if (groupData == null) return {};
    return groupData.keys.map((d) {
      try {
        return _dateFormat.parse(d);
      } catch (_) {
        return null;
      }
    }).whereType<DateTime>().toSet();
  }

  void _checkAndResetIfNewDay() {
    final today = todayStr;
    final lastReset = LocalStorage.getLastResetDate();
    if (lastReset != today) {
      LocalStorage.saveLastResetDate(today);
      // Don't wipe history — just note reset. Today's records start fresh (no action needed)
    }
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now);
    _midnightTimer = Timer(duration, () {
      _checkAndResetIfNewDay();
      notifyListeners();
      _scheduleMidnightReset(); // reschedule for next midnight
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  // ── Export helpers ─────────────────────────────────────────
  String exportGroupCsv(
      String groupId, String groupName, List<dynamic> members, String dateStr) {
    final sb = StringBuffer();
    // Header
    sb.write('Date,Member ID,');
    if (members.isNotEmpty) {
      final fields = (members.first as dynamic).fields as Map<String, String>;
      sb.write(fields.keys.join(','));
    }
    sb.writeln(',Status,Marked At');

    for (final m in members) {
      final rec = getRecordForDate(groupId, m.id, dateStr);
      sb.write('$dateStr,${m.id},');
      sb.write((m.fields as Map<String, String>).values.join(','));
      sb.writeln(',${rec.status.name},${rec.time ?? ""}');
    }
    return sb.toString();
  }
}
