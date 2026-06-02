import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../core/feature_flag_service.dart';

/// Conditionally renders [child] or [fallback] based on a feature flag.
///
/// Example:
/// ```dart
/// FeatureFlagBuilder(
///   flagKey: FlagKeys.mobileBiometricAuth,
///   builder: (_) => const BiometricLoginButton(),
///   fallback: const SizedBox.shrink(),
/// )
/// ```
class FeatureFlagBuilder extends StatelessWidget {
  final String flagKey;
  final WidgetBuilder builder;
  final Widget fallback;

  const FeatureFlagBuilder({
    super.key,
    required this.flagKey,
    required this.builder,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<FeatureFlagService, bool>(
      (svc) => svc.isEnabled(flagKey),
    );
    return enabled ? builder(context) : fallback;
  }
}
