import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/services/ai/suggestion_engine/models/suggestion_models.dart';
import 'package:flutter_shell/services/ai/suggestion_engine/suggestion_engine_providers.dart';

class SuggestionApprovalScreen extends ConsumerWidget {
  const SuggestionApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSuggestions = ref.watch(pendingSuggestionsProvider);
    final approvedSuggestions = ref.watch(approvedSuggestionsProvider);
    final suggestionActions = ref.watch(suggestionActionsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Suggestions'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending), text: 'Pending Approval'),
              Tab(icon: Icon(Icons.check_circle), text: 'Approved'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildPendingTab(context, pendingSuggestions, suggestionActions),
            _buildApprovedTab(context, approvedSuggestions),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showSuggestionTemplates(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPendingTab(
    BuildContext context,
    AsyncValue<List<Suggestion>> suggestions,
    SuggestionActions actions,
  ) {
    return suggestions.when(
      data: (suggestionsList) {
        if (suggestionsList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No pending suggestions',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'AI suggestions will appear here for your approval',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestionsList.length,
          itemBuilder: (context, index) {
            final suggestion = suggestionsList[index];
            return _SuggestionCard(
              suggestion: suggestion,
              onApprove: () => actions.approve(suggestion.id),
              onReject: () => actions.reject(suggestion.id),
              onSend: () => actions.send(suggestion.id),
              showActions: true,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading suggestions: $error'),
      ),
    );
  }

  Widget _buildApprovedTab(
    BuildContext context,
    AsyncValue<List<Suggestion>> suggestions,
  ) {
    return suggestions.when(
      data: (suggestionsList) {
        if (suggestionsList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No approved suggestions yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestionsList.length,
          itemBuilder: (context, index) {
            final suggestion = suggestionsList[index];
            return Consumer(
              builder: (context, ref, _) {
                final actions = ref.watch(suggestionActionsProvider);
                return _SuggestionCard(
                  suggestion: suggestion,
                  onApprove: null,
                  onReject: null,
                  onSend: () => actions.send(suggestion.id),
                  showActions: false,
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading approved suggestions: $error'),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const SuggestionEngineSettingsDialog(),
    );
  }

  void _showSuggestionTemplates(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SuggestionTemplatesSheet(),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onSend;
  final bool showActions;

  const _SuggestionCard({
    required this.suggestion,
    required this.onApprove,
    required this.onReject,
    required this.onSend,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(suggestion.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeDisplayName(suggestion.type),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'For ${suggestion.suggestedFor.key} • ${suggestion.priority.key} priority',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildPriorityChip(suggestion.priority),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (suggestion.aiAnalysis != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AI Analysis: ${suggestion.aiAnalysis}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatTime(suggestion.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (showActions) ...[
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: onSend,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(SuggestionType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case SuggestionType.todoNudge:
        icon = Icons.check_box;
        color = Colors.blue;
        break;
      case SuggestionType.empatheticReply:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case SuggestionType.studyAid:
        icon = Icons.school;
        color = Colors.green;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildPriorityChip(SuggestionPriority priority) {
    Color color;
    
    switch (priority) {
      case SuggestionPriority.low:
        color = Colors.grey;
        break;
      case SuggestionPriority.medium:
        color = Colors.blue;
        break;
      case SuggestionPriority.high:
        color = Colors.orange;
        break;
      case SuggestionPriority.urgent:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.key,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getTypeDisplayName(SuggestionType type) {
    switch (type) {
      case SuggestionType.todoNudge:
        return 'Todo Nudge';
      case SuggestionType.empatheticReply:
        return 'Empathetic Reply';
      case SuggestionType.studyAid:
        return 'Study Aid';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class SuggestionEngineSettingsDialog extends ConsumerWidget {
  const SuggestionEngineSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(suggestionEngineConfigProvider);

    return AlertDialog(
      title: const Text('Suggestion Engine Settings'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SettingsSection(
              title: 'Auto-send Settings',
              children: [
                Text('Auto-send is currently DISABLED by default for safety.'),
                SizedBox(height: 8),
                Text('Configure auto-send templates and rules in code.'),
              ],
            ),
            SizedBox(height: 16),
            _SettingsSection(
              title: 'Enabled Suggestion Types',
              children: [
                Text('• Morning: Todo nudges, Study aids'),
                Text('• Afternoon: All types enabled'),
                Text('• Evening: Empathetic replies, Study aids'),
                Text('• Night: Disabled'),
              ],
            ),
            SizedBox(height: 16),
            _SettingsSection(
              title: 'Daily Limits',
              children: [
                Text('• Todo nudges: 3 per day'),
                Text('• Empathetic replies: 5 per day'),
                Text('• Study aids: 2 per day'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class SuggestionTemplatesSheet extends StatelessWidget {
  const SuggestionTemplatesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = _getTemplates();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestion Templates',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Template-based auto-send scaffolding (currently disabled by default). '
            'These templates are used when auto-send is enabled.',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Card(
                  child: ListTile(
                    leading: _buildTypeIcon(template.type),
                    title: Text(_getTypeDisplayName(template.type)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Template: "${template.template}"'),
                        Text('Best for: ${template.preferredProfile.key} (${template.preferredProfile.timeRange})'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<SuggestionTemplate> _getTemplates() {
    return [
      const SuggestionTemplate(
        type: SuggestionType.todoNudge,
        template: 'Hi! It\'s {timeOfDay}. How about tackling "{task}"? You\'ve got this! 💪',
        preferredProfile: TemporalProfile.morning,
      ),
      const SuggestionTemplate(
        type: SuggestionType.empatheticReply,
        template: 'I understand you\'re feeling {emotion}. Your feelings are valid. Would you like to talk about it?',
        preferredProfile: TemporalProfile.evening,
      ),
      const SuggestionTemplate(
        type: SuggestionType.studyAid,
        template: 'Quick learning tip: {tip}. Want to explore this further?',
        preferredProfile: TemporalProfile.afternoon,
      ),
    ];
  }

  Widget _buildTypeIcon(SuggestionType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case SuggestionType.todoNudge:
        icon = Icons.check_box;
        color = Colors.blue;
        break;
      case SuggestionType.empatheticReply:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case SuggestionType.studyAid:
        icon = Icons.school;
        color = Colors.green;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }

  String _getTypeDisplayName(SuggestionType type) {
    switch (type) {
      case SuggestionType.todoNudge:
        return 'Todo Nudge';
      case SuggestionType.empatheticReply:
        return 'Empathetic Reply';
      case SuggestionType.studyAid:
        return 'Study Aid';
    }
  }
}