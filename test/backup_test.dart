import 'package:flutter_test/flutter_test.dart';
import 'package:simple_attende/core/models/group_model.dart';
import 'package:simple_attende/core/models/attendance_model.dart';
import 'package:simple_attende/core/storage/local_storage.dart';

void main() {
  group('Backup & Restore Tests', () {
    test('AttendanceData merges correctly', () {
      final a1 = AttendanceData();
      a1.setRecord('g1', '2026-09-23', 'm1', AttendanceRecord(status: AttendanceStatus.present, time: '09:00'));

      final a2 = AttendanceData();
      a2.setRecord('g1', '2026-09-23', 'm2', AttendanceRecord(status: AttendanceStatus.absent, time: '09:05'));
      a2.setRecord('g2', '2026-09-23', 'm3', AttendanceRecord(status: AttendanceStatus.present, time: '10:00'));

      a1.merge(a2);

      expect(a1.getRecord('g1', '2026-09-23', 'm1').status, AttendanceStatus.present);
      expect(a1.getRecord('g1', '2026-09-23', 'm2').status, AttendanceStatus.absent);
      expect(a1.getRecord('g2', '2026-09-23', 'm3').status, AttendanceStatus.present);
    });

    test('LocalStorage.parseBackupJson parses valid payload', () {
      const jsonStr = '''
      {
        "app": "Simple Attende",
        "version": "1.0.2",
        "groups": [
          {
            "id": "g1",
            "name": "General Clinic",
            "createdAt": "2026-09-23T10:00:00.000",
            "categories": ["Name", "Phone"],
            "members": [
              {
                "id": "m1",
                "fields": {"Name": "John Doe", "Phone": "1234567890"}
              }
            ]
          }
        ],
        "attendance": "{}"
      }
      ''';

      final parsed = LocalStorage.parseBackupJson(jsonStr);
      expect(parsed, isNotNull);
      expect(parsed!['app'], 'Simple Attende');
      expect(parsed['groups'], isA<List>());
      final groups = (parsed['groups'] as List)
          .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      expect(groups.length, 1);
      expect(groups[0].name, 'General Clinic');
      expect(groups[0].members[0].displayName, 'John Doe');
    });

    test('LocalStorage.parseBackupJson rejects invalid payload', () {
      expect(LocalStorage.parseBackupJson('not a json'), isNull);
      expect(LocalStorage.parseBackupJson('{"other_key": 123}'), isNull);
    });
  });
}
