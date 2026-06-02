enum FlagScope { general, backend, web, mobile }

class FeatureFlag {
  final String key;
  final bool enabled;
  final String description;
  final FlagScope scope;

  const FeatureFlag({
    required this.key,
    required this.enabled,
    required this.description,
    required this.scope,
  });

  FeatureFlag copyWith({bool? enabled}) => FeatureFlag(
        key: key,
        enabled: enabled ?? this.enabled,
        description: description,
        scope: scope,
      );

  factory FeatureFlag.fromJson(Map<String, dynamic> json) => FeatureFlag(
        key: json['key'] as String,
        enabled: json['enabled'] as bool,
        description: json['description'] as String,
        scope: FlagScope.values.firstWhere(
          (s) => s.name.toUpperCase() == (json['scope'] as String),
          orElse: () => FlagScope.general,
        ),
      );
}

// Well-known flag keys
abstract final class FlagKeys {
  static const generalDarkMode = 'GENERAL_DARK_MODE';
  static const generalNotificationCenter = 'GENERAL_NOTIFICATION_CENTER';
  static const backendAdvancedSearch = 'BACKEND_ADVANCED_SEARCH';
  static const backendAiRecommendations = 'BACKEND_AI_RECOMMENDATIONS';
  static const webNewDashboard = 'WEB_NEW_DASHBOARD';
  static const webExperimentalCharts = 'WEB_EXPERIMENTAL_CHARTS';
  static const mobileBiometricAuth = 'MOBILE_BIOMETRIC_AUTH';
  static const mobileOfflineMode = 'MOBILE_OFFLINE_MODE';
}
