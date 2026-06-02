import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'feature_flag_model.dart';
import 'feature_flag_service.dart';

/// Connects to the Unleash Frontend API directly.
/// Toggle calls still go through the Spring Boot backend which proxies to
/// the Unleash Admin API (avoids exposing the admin token to mobile clients).
class UnleashFeatureFlagService extends FeatureFlagService {
  static const _clientKey = 'default:development.unleash-frontend-token';
  static const _pollInterval = Duration(seconds: 15);

  // 10.0.2.2 = Android emulator loopback to host; everything else uses localhost
  static String get _host {
    if (kIsWeb) return 'localhost';
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {}
    return 'localhost';
  }

  String get _unleashUrl => 'http://$_host:4242/api/frontend';
  String get _backendUrl => 'http://$_host:8080/api';

  Timer? _pollTimer;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> loadFlags() async {
    // Show spinner only on first load
    await _fetchFromUnleash(showLoading: true);
    _startPolling();
  }

  @override
  Future<void> toggleFlag(String key) async {
    // Optimistic update
    if (flags.containsKey(key)) {
      flags[key] = flags[key]!.copyWith(enabled: !flags[key]!.enabled);
      notifyListeners();
    }

    // Toggle through backend → Unleash Admin API
    try {
      await http
          .post(Uri.parse('$_backendUrl/flags/$key/toggle'))
          .timeout(const Duration(seconds: 5));
      // Re-fetch to get the authoritative state from Unleash (silent, no spinner)
      await _fetchFromUnleash(showLoading: false);
    } catch (_) {
      // Optimistic update stays on failure
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── private ────────────────────────────────────────────────────────────────

  Future<void> _fetchFromUnleash({required bool showLoading}) async {
    if (showLoading) setLoading(true);

    try {
      final response = await http.get(
        Uri.parse(_unleashUrl),
        headers: {'Authorization': _clientKey},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final toggles = (body['toggles'] as List?) ?? [];

        // Unleash Frontend API returns all flags; build enabled-name set
        final enabledSet = {
          for (final t in toggles)
            if ((t as Map<String, dynamic>)['enabled'] == true)
              t['name'] as String,
        };

        // Merge Unleash state with local metadata (scope / description)
        for (final flag in defaultFlagDefinitions()) {
          flags[flag.key] = flag.copyWith(enabled: enabledSet.contains(flag.key));
        }

        setError(null);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      final msg = e.toString().split('\n').first;
      setError('Unleash unreachable ($msg) — trying backend');
      await _fetchFromBackend();
    }

    if (showLoading) setLoading(false);
    notifyListeners();
  }

  Future<void> _fetchFromBackend() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/flags'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        for (final item in list) {
          final flag = FeatureFlag.fromJson(item as Map<String, dynamic>);
          flags[flag.key] = flag;
        }
        setError(null);
      }
    } catch (_) {
      if (flags.isEmpty) loadDefaults();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Silent polls — no spinner, just update flags in the background
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchFromUnleash(showLoading: false));
  }
}
