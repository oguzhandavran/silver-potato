import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/features/suggestions/suggestions_provider.dart';

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suggestionsStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lightbulb,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                'AI-Powered Suggestions',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This screen displays suggestions generated via the AI orchestration layer.\n\nIf no API keys are configured, it will fall back to an offline provider.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        ref.read(suggestionsStateProvider.notifier).fetchSuggestions();
                      },
                icon: const Icon(Icons.refresh),
                label: Text(state.isLoading ? 'Loading...' : 'Fetch Suggestions'),
              ),
              const SizedBox(height: 16),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (state.suggestions.isEmpty && !state.isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tap "Fetch Suggestions" to generate suggestions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...state.suggestions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(s)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
