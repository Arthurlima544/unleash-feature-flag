import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/feature_flag_model.dart';
import '../../core/feature_flag_service.dart';

class FlagManagerScreen extends StatelessWidget {
  const FlagManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flagService = context.watch<FeatureFlagService>();
    final grouped = _groupByScope(flagService.allFlags);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flag Manager'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
            onPressed: () => flagService.loadFlags(),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final scope in FlagScope.values)
            if (grouped[scope]?.isNotEmpty ?? false) ...[
              _ScopeHeader(scope: scope),
              for (final flag in grouped[scope]!)
                _FlagTile(flag: flag, onToggle: () => flagService.toggleFlag(flag.key)),
            ],
        ],
      ),
    );
  }

  Map<FlagScope, List<FeatureFlag>> _groupByScope(List<FeatureFlag> flags) {
    final map = <FlagScope, List<FeatureFlag>>{};
    for (final flag in flags) {
      map.putIfAbsent(flag.scope, () => []).add(flag);
    }
    return map;
  }
}

class _ScopeHeader extends StatelessWidget {
  final FlagScope scope;
  const _ScopeHeader({required this.scope});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (scope) {
      FlagScope.general => ('GENERAL', Colors.blue),
      FlagScope.backend => ('BACKEND', Colors.orange),
      FlagScope.web => ('WEB', Colors.green),
      FlagScope.mobile => ('MOBILE', Colors.purple),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600,
          )),
        ),
      ]),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final FeatureFlag flag;
  final VoidCallback onToggle;
  const _FlagTile({required this.flag, required this.onToggle});

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(flag.key, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
    subtitle: Text(flag.description, style: const TextStyle(fontSize: 12)),
    trailing: Switch(
      value: flag.enabled,
      onChanged: (_) => onToggle(),
    ),
  );
}
