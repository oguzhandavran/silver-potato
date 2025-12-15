import 'package:flutter_shell/services/context/context_event.dart';

abstract class ContextIngestor {
  String get id;
  String get displayName;

  Stream<ContextEvent> get events;

  Future<void> start();
  Future<void> stop();

  void dispose();
}
