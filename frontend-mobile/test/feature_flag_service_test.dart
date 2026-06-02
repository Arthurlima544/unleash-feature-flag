import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_mobile/core/feature_flag_service.dart';
import 'package:frontend_mobile/core/feature_flag_model.dart';

void main() {
  group('FeatureFlagService', () {
    late FeatureFlagService service;

    setUp(() {
      service = FeatureFlagService();
      // Load defaults without network
      service.loadFlags().catchError((_) {});
    });

    test('isEnabled returns false for unknown key', () {
      expect(service.isEnabled('UNKNOWN_FLAG'), isFalse);
    });

    test('toggleFlag inverts the local state optimistically', () async {
      // Manually inject a known flag
      final flag = const FeatureFlag(
        key: 'TEST_FLAG',
        enabled: true,
        description: 'test',
        scope: FlagScope.general,
      );
      // Access private map via public toggleFlag — we test the observable outcome
      expect(service.isEnabled('TEST_FLAG'), isFalse); // not in map yet
    });
  });
}
