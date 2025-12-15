import 'dart:async';

import 'package:flutter_shell/services/context/context_event.dart';

abstract class ContextRepository {
  Stream<ContextEvent> get events;
  List<ContextEvent> get recentEvents;

  void addEvent(ContextEvent event);

  void dispose();
}

class InMemoryContextRepository implements ContextRepository {
  final int maxEvents;
  final List<ContextEvent> _events = <ContextEvent>[];
  final StreamController<ContextEvent> _controller = StreamController<ContextEvent>.broadcast();

  InMemoryContextRepository({this.maxEvents = 500});

  @override
  Stream<ContextEvent> get events => _controller.stream;

  @override
  List<ContextEvent> get recentEvents => List<ContextEvent>.unmodifiable(_events);

  @override
  void addEvent(ContextEvent event) {
    _events.add(event);
    if (_events.length > maxEvents) {
      _events.removeRange(0, _events.length - maxEvents);
    }

    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
