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

  // Returns all attendance records for a specific member across all dates in group
  Map<String, AttendanceRecord> getMemberHistory(String groupId, String memberId) {
    final Map<String, AttendanceRecord> result = {};
    final groupData = _data.data[groupId];
    if (groupData == null) return result;

    for (final dateEntry in groupData.entries) {
      final rec = dateEntry.value[memberId];
      if (rec != null && rec.status != AttendanceStatus.unset) {
        result[dateEntry.key] = rec;
      }
    }
    return result;
  }

  // Set of dates where a specific member was marked present or absent
  Set<DateTime> getDatesWithDataForMember(String groupId, String memberId) {
    final history = getMemberHistory(groupId, memberId);
    return history.keys.map((d) {
      try {
        return _dateFormat.parse(d);
      } catch (_) {
        return null;
      }
    }).whereType<DateTime>().toSet();
  }

  // Calculates period statistics (Weekly, Monthly, Yearly) for a specific member
  Map<String, dynamic> getMemberPeriodStats(
      String groupId, String memberId, DateTime referenceDate, String period) {
    final history = getMemberHistory(groupId, memberId);

    DateTime start;
    DateTime end;

    if (period == 'Weekly') {
      // Monday of the week
      final weekday = referenceDate.weekday; // 1 = Monday, 7 = Sunday
      start = DateTime(referenceDate.year, referenceDate.month, referenceDate.day - (weekday - 1));
      end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
    } else if (period == 'Monthly') {
      start = DateTime(referenceDate.year, referenceDate.month, 1);
      final nextMonth = (referenceDate.month == 12)
          ? DateTime(referenceDate.year + 1, 1, 1)
          : DateTime(referenceDate.year, referenceDate.month + 1, 1);
      end = nextMonth.subtract(const Duration(seconds: 1));
    } else {
      // Yearly
      start = DateTime(referenceDate.year, 1, 1);
      end = DateTime(referenceDate.year, 12, 31, 23, 59, 59);
    }

    int present = 0;
    int absent = 0;
    final Map<String, AttendanceRecord> periodRecords = {};

    for (final entry in history.entries) {
      try {
        final d = _dateFormat.parse(entry.key);
        if ((d.isAfter(start) || d.isAtSameMomentAs(start)) &&
            (d.isBefore(end) || d.isAtSameMomentAs(end))) {
          periodRecords[entry.key] = entry.value;
          if (entry.value.status == AttendanceStatus.present) {
            present++;
          } else if (entry.value.status == AttendanceStatus.absent) {
            absent++;
          }
        }
      } catch (_) {}
    }

    final total = present + absent;
    final rate = total > 0 ? ((present / total) * 100).toStringAsFixed(1) : '0.0';

    return {
      'present': present,
      'absent': absent,
      'total': total,
      'rate': rate,
      'records': periodRecords,
      'startDate': start,
      'endDate': end,
    };
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

  // ── Import / Export helpers ────────────────────────────────
  Future<void> importAttendance(String jsonStr, {bool replace = false}) async {
    final incoming = AttendanceData.fromJson(jsonStr);
    if (replace) {
      _data = incoming;
    } else {
      _data.merge(incoming);
    }
    await LocalStorage.saveAttendance(_data);
    notifyListeners();
  }

  Future<void> reload() async {
    _data = LocalStorage.getAttendance();
    notifyListeners();
  }

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
