import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/feature_flag_model.dart';
import '../../core/feature_flag_service.dart';
import '../../shared/widgets/feature_flag_builder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flagService = context.watch<FeatureFlagService>();
    final isDark = flagService.isEnabled(FlagKeys.generalDarkMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flags Demo'),
        actions: [
          // GENERAL_NOTIFICATION_CENTER flag
          FeatureFlagBuilder(
            flagKey: FlagKeys.generalNotificationCenter,
            builder: (_) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => _showNotifications(context),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // GENERAL_DARK_MODE flag
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle dark mode (GENERAL_DARK_MODE)',
            onPressed: () => flagService.toggleFlag(FlagKeys.generalDarkMode),
          ),
        ],
      ),
      body: flagService.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (flagService.error != null) _ErrorBanner(flagService.error!),
                _SectionHeader('Flutter-Specific Features', color: Colors.deepPurple),
                const SizedBox(height: 8),

                // MOBILE_BIOMETRIC_AUTH flag
                FeatureFlagBuilder(
                  flagKey: FlagKeys.mobileBiometricAuth,
                  builder: (_) => _FeatureCard(
                    flag: 'MOBILE_BIOMETRIC_AUTH',
                    enabled: true,
                    icon: Icons.fingerprint,
                    title: 'Biometric Authentication',
                    description: 'Login with fingerprint or face recognition',
                    color: Colors.green,
                    onTap: () => _showBiometricDemo(context),
                  ),
                  fallback: _FeatureCard(
                    flag: 'MOBILE_BIOMETRIC_AUTH',
                    enabled: false,
                    icon: Icons.lock_outlined,
                    title: 'Password Login Only',
                    description: 'Enable MOBILE_BIOMETRIC_AUTH for biometric login',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                // MOBILE_OFFLINE_MODE flag
                FeatureFlagBuilder(
                  flagKey: FlagKeys.mobileOfflineMode,
                  builder: (_) => const _OfflineModeBanner(),
                  fallback: _FeatureCard(
                    flag: 'MOBILE_OFFLINE_MODE',
                    enabled: false,
                    icon: Icons.cloud_off_outlined,
                    title: 'Offline Mode (Disabled)',
                    description: 'Enable MOBILE_OFFLINE_MODE to show sync status',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeader('General Features (all platforms)', color: Colors.blue),
                const SizedBox(height: 8),
                _FlagStatusTile(flagKey: FlagKeys.generalDarkMode, label: 'Dark Mode'),
                _FlagStatusTile(flagKey: FlagKeys.generalNotificationCenter, label: 'Notification Center'),
                const SizedBox(height: 24),

                _SectionHeader('Backend Features', color: Colors.orange),
                const SizedBox(height: 8),
                _FlagStatusTile(flagKey: FlagKeys.backendAdvancedSearch, label: 'Advanced Search'),
                _FlagStatusTile(flagKey: FlagKeys.backendAiRecommendations, label: 'AI Recommendations'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/flags'),
        icon: const Icon(Icons.flag),
        label: const Text('Manage Flags'),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _showBiometricDemo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Biometric Auth'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Touch the fingerprint sensor to authenticate\n(demo simulation)'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader(this.title, {required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
  ]);
}

class _FeatureCard extends StatelessWidget {
  final String flag;
  final bool enabled;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.flag, required this.enabled, required this.icon,
    required this.title, required this.description, required this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          _FlagChip(flag: flag, enabled: enabled),
        ],
      ),
      trailing: enabled ? const Icon(Icons.chevron_right) : null,
      onTap: enabled ? onTap : null,
    ),
  );
}

class _FlagChip extends StatelessWidget {
  final String flag;
  final bool enabled;
  const _FlagChip({required this.flag, required this.enabled});

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(flag, style: const TextStyle(fontSize: 10)),
    backgroundColor: enabled ? Colors.green.shade50 : Colors.red.shade50,
    side: BorderSide(color: enabled ? Colors.green.shade200 : Colors.red.shade200),
    padding: EdgeInsets.zero,
    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
  );
}

class _FlagStatusTile extends StatelessWidget {
  final String flagKey;
  final String label;
  const _FlagStatusTile({required this.flagKey, required this.label});

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<FeatureFlagService, bool>((s) => s.isEnabled(flagKey));
    return ListTile(
      dense: true,
      leading: Icon(enabled ? Icons.check_circle : Icons.cancel_outlined,
        color: enabled ? Colors.green : Colors.red, size: 20),
      title: Text(label),
      subtitle: Text(flagKey, style: const TextStyle(fontSize: 11)),
      trailing: Chip(
        label: Text(enabled ? 'ON' : 'OFF', style: const TextStyle(fontSize: 11)),
        backgroundColor: enabled ? Colors.green.shade50 : Colors.red.shade50,
      ),
    );
  }
}

class _OfflineModeBanner extends StatelessWidget {
  const _OfflineModeBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.amber.shade100,
      border: Border.all(color: Colors.amber.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off, color: Colors.amber, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Offline Mode Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('MOBILE_OFFLINE_MODE: ON — Changes will sync when online',
            style: TextStyle(fontSize: 11, color: Colors.amber.shade800)),
        ],
      )),
    ]),
  );
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Chip(label: const Text('GENERAL_NOTIFICATION_CENTER: ON',
            style: TextStyle(fontSize: 10)), backgroundColor: Colors.green.shade50),
        ]),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.info_outline, color: Colors.blue),
          title: Text('Welcome to the notification center!'),
          subtitle: Text('This panel is controlled by a feature flag'),
        ),
        const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Feature flags are working!'),
          subtitle: Text('Try toggling them in the Flag Manager'),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      border: Border.all(color: Colors.orange.shade200),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
    ]),
  );
}
