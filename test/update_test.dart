import 'package:flutter_test/flutter_test.dart';
import 'package:simple_attende/providers/update_provider.dart';

void main() {
  group('UpdateProvider Version Comparison Tests', () {
    test('Correctly identifies newer versions', () {
      expect(UpdateProvider.isNewerVersion('1.0.2', '1.0.3'), isTrue);
      expect(UpdateProvider.isNewerVersion('1.0.2', '1.1.0'), isTrue);
      expect(UpdateProvider.isNewerVersion('1.0.2', '2.0.0'), isTrue);
      expect(UpdateProvider.isNewerVersion('v1.0.2', 'v1.0.3'), isTrue);
      expect(UpdateProvider.isNewerVersion('1.0.2+3', 'v1.0.3'), isTrue);
    });

    test('Correctly identifies same or older versions', () {
      expect(UpdateProvider.isNewerVersion('1.0.2', '1.0.2'), isFalse);
      expect(UpdateProvider.isNewerVersion('1.0.2', '1.0.1'), isFalse);
      expect(UpdateProvider.isNewerVersion('1.2.0', '1.1.9'), isFalse);
      expect(UpdateProvider.isNewerVersion('2.0.0', '1.9.9'), isFalse);
      expect(UpdateProvider.isNewerVersion('v1.0.2', '1.0.2'), isFalse);
    });

    test('Handles short or complex version strings cleanly', () {
      expect(UpdateProvider.isNewerVersion('1.0', '1.0.1'), isTrue);
      expect(UpdateProvider.isNewerVersion('1.0.1', '1.0'), isFalse);
      expect(UpdateProvider.isNewerVersion('1.0.2-beta', '1.0.3'), isTrue);
    });
  });
}
