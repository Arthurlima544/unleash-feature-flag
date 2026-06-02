import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'feature_flag_model.dart';

class FeatureFlagService extends ChangeNotifier {
  static const _baseUrl = 'http://10.0.2.2:8080/api'; // Android emulator → localhost
  // Use 'http://localhost:8080/api' for iOS simulator or web

  final Map<String, FeatureFlag> _flags = {};
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  List<FeatureFlag> get allFlags => _flags.values.toList();

  bool isEnabled(String key) => _flags[key]?.enabled ?? false;

  Future<void> loadFlags() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/flags'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        for (final item in list) {
          final flag = FeatureFlag.fromJson(item as Map<String, dynamic>);
          _flags[flag.key] = flag;
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Could not reach backend. Using defaults.';
      _loadDefaults();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> toggleFlag(String key) async {
    // Optimistic update
    if (_flags.containsKey(key)) {
      _flags[key] = _flags[key]!.copyWith(enabled: !_flags[key]!.enabled);
      notifyListeners();
    }

    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/flags/$key/toggle'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final flag = FeatureFlag.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        _flags[flag.key] = flag;
        notifyListeners();
      }
    } catch (_) {
      // Keep optimistic update on network failure
    }
  }

  void _loadDefaults() {
    final defaults = [
      const FeatureFlag(key: FlagKeys.generalDarkMode, enabled: true, description: 'Dark mode theme', scope: FlagScope.general),
      const FeatureFlag(key: FlagKeys.generalNotificationCenter, enabled: false, description: 'Notification center', scope: FlagScope.general),
      const FeatureFlag(key: FlagKeys.backendAdvancedSearch, enabled: true, description: 'Advanced search endpoint', scope: FlagScope.backend),
      const FeatureFlag(key: FlagKeys.backendAiRecommendations, enabled: false, description: 'AI recommendations', scope: FlagScope.backend),
      const FeatureFlag(key: FlagKeys.webNewDashboard, enabled: true, description: 'New dashboard layout', scope: FlagScope.web),
      const FeatureFlag(key: FlagKeys.webExperimentalCharts, enabled: false, description: 'Experimental charts', scope: FlagScope.web),
      const FeatureFlag(key: FlagKeys.mobileBiometricAuth, enabled: true, description: 'Biometric login UI', scope: FlagScope.mobile),
      const FeatureFlag(key: FlagKeys.mobileOfflineMode, enabled: false, description: 'Offline mode indicator', scope: FlagScope.mobile),
    ];
    for (final f in defaults) {
      _flags[f.key] = f;
    }
  }
}
