import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shell/features/home/home_screen.dart';
import 'package:flutter_shell/services/ai/suggestion_engine/suggestion_engine_providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the suggestion engine
    ref.watch(suggestionEngineInitializerProvider);
    
    return MaterialApp(
      title: 'Flutter Shell',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
