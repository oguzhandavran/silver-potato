import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_shell/services/context/context_providers.dart';

class ContextOnboardingScreen extends ConsumerWidget {
  const ContextOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(contextIngestionControllerProvider.notifier);
    final state = ref.watch(contextIngestionControllerProvider);
    final bridge = ref.watch(contextPlatformBridgeProvider);

    ref.watch(contextEventsStreamProvider);
    final repo = ref.watch(contextRepositoryProvider);

    Future<void> requestAudioPermissions() async {
      await Permission.microphone.request();
      await Permission.notification.request();
    }

    Widget collectorTile({
      required String id,
      required String title,
      required String description,
      required Future<bool> Function() enabledCheck,
      required VoidCallback onOpenSettings,
      Future<void> Function()? onStart,
      Future<void> Function()? onStop,
    }) {
      final isActive = state.activeCollectorIds.contains(id);

      return FutureBuilder<bool>(
        future: enabledCheck(),
        builder: (context, snapshot) {
          final enabled = snapshot.data ?? false;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusChip(label: enabled ? 'OS access enabled' : 'OS access disabled', ok: enabled),
                      _StatusChip(label: isActive ? 'Collector running' : 'Collector stopped', ok: isActive),
                      OutlinedButton(
                        onPressed: onOpenSettings,
                        child: const Text('Open settings'),
                      ),
                      if (!isActive)
                        FilledButton(
                          onPressed: onStart == null
                              ? null
                              : () async {
                                  await onStart();
                                },
                          child: const Text('Start'),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: onStop == null
                              ? null
                              : () async {
                                  await onStop();
                                },
                          child: const Text('Stop'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Collectors (Android)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'These collectors are Android-only stubs. Each requires explicit user action in system settings and can be started/stopped from here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          collectorTile(
            id: 'notifications',
            title: 'Notifications',
            description:
                'Listens for notifications from WhatsApp/ColorNote/StarNote via NotificationListenerService. Stores hashes/lengths only (no raw message text).',
            enabledCheck: bridge.isNotificationListenerEnabled,
            onOpenSettings: () {
              bridge.openNotificationListenerSettings();
            },
            onStart: () => controller.startCollector('notifications'),
            onStop: () => controller.stopCollector('notifications'),
          ),
          collectorTile(
            id: 'accessibility',
            title: 'Accessibility context (strict opt-in)',
            description:
                'Captures high-level UI events (app switches/window changes) without window content. Must be enabled manually in Accessibility settings.',
            enabledCheck: bridge.isAccessibilityServiceEnabled,
            onOpenSettings: () {
              bridge.openAccessibilitySettings();
            },
            onStart: () => controller.startCollector('accessibility'),
            onStop: () => controller.stopCollector('accessibility'),
          ),
          collectorTile(
            id: 'usage_stats',
            title: 'Usage stats browser summary',
            description:
                'Queries UsageStatsManager for aggregate foreground time for Chrome/Firefox. Does not provide per-URL browser history.',
            enabledCheck: bridge.hasUsageStatsAccess,
            onOpenSettings: () {
              bridge.openUsageAccessSettings();
            },
            onStart: () => controller.startCollector('usage_stats'),
            onStop: () => controller.stopCollector('usage_stats'),
          ),
          collectorTile(
            id: 'audio_features',
            title: 'Audio features (foreground)',
            description:
                'Runs a foreground service and samples microphone amplitude to compute activity level + VAD-like flag. Does not store audio.',
            enabledCheck: bridge.isAudioFeaturesServiceRunning,
            onOpenSettings: () async {
              await requestAudioPermissions();
            },
            onStart: () async {
              await requestAudioPermissions();
              await controller.startCollector('audio_features');
            },
            onStop: () => controller.stopCollector('audio_features'),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Text('Recent sanitized events', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...repo.recentEvents.reversed.take(15).map(
                (event) => ListTile(
                  dense: true,
                  title: Text('${event.source.name}: ${event.type}'),
                  subtitle: Text(event.data.toString()),
                  trailing: Text(
                    TimeOfDay.fromDateTime(event.timestamp).format(context),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool ok;

  const _StatusChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Colors.grey;
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: ok ? Colors.white : null),
      backgroundColor: ok ? color : null,
      side: ok ? BorderSide.none : BorderSide(color: color),
    );
  }
}
