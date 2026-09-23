// ============================================================
// lib/core/models/attendance_model.dart
// ============================================================
import 'dart:convert';

enum AttendanceStatus { present, absent, unset }

class AttendanceRecord {
  AttendanceStatus status;
  String? time; // HH:MM when marked

  AttendanceRecord({this.status = AttendanceStatus.unset, this.time});

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'time': time,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AttendanceStatus.unset,
        ),
        time: json['time'],
      );
}

/// Structure: { groupId: { dateStr(yyyy-MM-dd): { memberId: AttendanceRecord } } }
class AttendanceData {
  // groupId -> dateStr -> memberId -> record
  Map<String, Map<String, Map<String, AttendanceRecord>>> data;

  AttendanceData({Map<String, Map<String, Map<String, AttendanceRecord>>>? data})
      : data = data ?? {};

  AttendanceRecord getRecord(String groupId, String dateStr, String memberId) {
    return data[groupId]?[dateStr]?[memberId] ?? AttendanceRecord();
  }

  void setRecord(
      String groupId, String dateStr, String memberId, AttendanceRecord record) {
    data.putIfAbsent(groupId, () => {});
    data[groupId]!.putIfAbsent(dateStr, () => {});
    data[groupId]![dateStr]![memberId] = record;
  }

  Map<String, AttendanceRecord> getDayRecords(String groupId, String dateStr) {
    return data[groupId]?[dateStr] ?? {};
  }

  void merge(AttendanceData other) {
    for (final groupEntry in other.data.entries) {
      data.putIfAbsent(groupEntry.key, () => {});
      for (final dateEntry in groupEntry.value.entries) {
        data[groupEntry.key]!.putIfAbsent(dateEntry.key, () => {});
        for (final memberEntry in dateEntry.value.entries) {
          data[groupEntry.key]![dateEntry.key]![memberEntry.key] = memberEntry.value;
        }
      }
    }
  }

  String toJson() => jsonEncode(data.map(
        (gId, dates) => MapEntry(
          gId,
          dates.map(
            (date, members) => MapEntry(
              date,
              members.map(
                (mId, rec) => MapEntry(mId, rec.toJson()),
              ),
            ),
          ),
        ),
      ));

  factory AttendanceData.fromJson(String jsonStr) {
    if (jsonStr.isEmpty) return AttendanceData();
    try {
      final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = raw.map(
        (gId, dates) => MapEntry(
          gId,
          (dates as Map<String, dynamic>).map(
            (date, members) => MapEntry(
              date,
              (members as Map<String, dynamic>).map(
                (mId, rec) =>
                    MapEntry(mId, AttendanceRecord.fromJson(rec as Map<String, dynamic>)),
              ),
            ),
          ),
        ),
      );
      return AttendanceData(data: data);
    } catch (_) {
      return AttendanceData();
    }
  }
}
