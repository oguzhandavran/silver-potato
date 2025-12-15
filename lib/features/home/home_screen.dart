import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/features/context_onboarding/context_onboarding_screen.dart';
import 'package:flutter_shell/features/suggestions/suggestions_screen.dart';
import 'package:flutter_shell/features/suggestions/suggestion_approval_screen.dart';
import 'package:flutter_shell/services/app_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Shell'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.flutter_dash,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Flutter Shell',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'A modern Flutter 3 application with AI integration, state management, and background services.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SuggestionsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('View Suggestions'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SuggestionApprovalScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.approval),
                label: const Text('AI Suggestion Engine'),
              ),
              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ContextOnboardingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Context collectors (Android)'),
                ),
              ],
              const SizedBox(height: 16),
              if (appState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    appState.errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
