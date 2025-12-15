import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../services/hive_service.dart';

/// Repository for managing context data with Hive storage and memory streaming
class ContextRepository {
  static ContextRepository? _instance;
  static ContextRepository get instance => _instance ??= ContextRepository._();

  ContextRepository._();

  late final Box<ContextEvent> _contextEventBox;
  late final Box<Suggestion> _suggestionBox;
  late final Box<UserPreference> _userPreferenceBox;
  late final Box<MessageSummary> _messageSummaryBox;

  // In-memory storage for recent events (for quick access)
  final ListQueue<ContextEvent> _recentEvents = ListQueue<ContextEvent>(100);
  final StreamController<ContextEvent> _eventStreamController = 
      StreamController<ContextEvent>.broadcast();

  // Getters for public access
  Stream<ContextEvent> get eventStream => _eventStreamController.stream;
  List<ContextEvent> get recentEvents => List.unmodifiable(_recentEvents);

  /// Initialize the repository and open all necessary boxes
  Future<void> initialize() async {
    // Ensure Hive is initialized
    await HiveService.instance.initialize();
    
    // Open all boxes
    _contextEventBox = await Hive.openBox<ContextEvent>('context_events');
    _suggestionBox = await Hive.openBox<Suggestion>('suggestions');
    _userPreferenceBox = await Hive.openBox<UserPreference>('user_preferences');
    _messageSummaryBox = await Hive.openBox<MessageSummary>('message_summaries');

    // Load recent events from storage
    await _loadRecentEvents();
  }

  /// Load recent events from storage into memory
  Future<void> _loadRecentEvents() async {
    final events = await getRecentEvents(limit: 50);
    _recentEvents.clear();
    _recentEvents.addAll(events);
  }

  // ===============================
  // ContextEvent Operations
  // ===============================

  /// Create a new context event
  Future<ContextEvent> createContextEvent({
    required String type,
    required Map<String, dynamic> data,
    required String source,
    List<String> tags = const [],
  }) async {
    final event = ContextEvent(
      id: _generateId(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
      source: source,
      tags: tags,
    );

    await _contextEventBox.put(event.id, event);
    _addToRecentEvents(event);
    _eventStreamController.add(event);

    return event;
  }

  /// Get a context event by ID
  Future<ContextEvent?> getContextEvent(String id) async {
    return _contextEventBox.get(id);
  }

  /// Get all context events
  Future<List<ContextEvent>> getAllContextEvents() async {
    return _contextEventBox.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get recent context events with optional limit
  Future<List<ContextEvent>> getRecentEvents({int limit = 50}) async {
    final allEvents = _contextEventBox.values.toList();
    allEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEvents.take(limit).toList();
  }

  /// Get context events by type
  Future<List<ContextEvent>> getEventsByType(String type) async {
    return _contextEventBox.values.where((event) => event.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get context events by source
  Future<List<ContextEvent>> getEventsBySource(String source) async {
    return _contextEventBox.values.where((event) => event.source == source).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get context events by tags
  Future<List<ContextEvent>> getEventsByTags(List<String> tags) async {
    return _contextEventBox.values
        .where((event) => tags.any((tag) => event.tags.contains(tag)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Update a context event
  Future<ContextEvent?> updateContextEvent(String id, {
    String? type,
    Map<String, dynamic>? data,
    String? source,
    List<String>? tags,
  }) async {
    final existing = _contextEventBox.get(id);
    if (existing == null) return null;

    final updated = existing.copyWith(
      type: type,
      data: data,
      source: source,
      tags: tags,
    );

    await _contextEventBox.put(id, updated);
    _updateRecentEvents(updated);
    _eventStreamController.add(updated);

    return updated;
  }

  /// Delete a context event
  Future<bool> deleteContextEvent(String id) async {
    final deleted = await _contextEventBox.delete(id);
    if (deleted != null) {
      _removeFromRecentEvents(id);
    }
    return deleted != null;
  }

  // ===============================
  // Suggestion Operations
  // ===============================

  /// Create a new suggestion
  Future<Suggestion> createSuggestion({
    required String title,
    required String description,
    required String category,
    required int priority,
    DateTime? expiresAt,
    Map<String, dynamic> metadata = const {},
    bool isEnabled = true,
  }) async {
    final suggestion = Suggestion(
      id: _generateId(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      metadata: metadata,
      isEnabled: isEnabled,
    );

    await _suggestionBox.put(suggestion.id, suggestion);
    return suggestion;
  }

  /// Get a suggestion by ID
  Future<Suggestion?> getSuggestion(String id) async {
    return _suggestionBox.get(id);
  }

  /// Get all suggestions
  Future<List<Suggestion>> getAllSuggestions() async {
    return _suggestionBox.values.toList()..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Get enabled suggestions
  Future<List<Suggestion>> getEnabledSuggestions() async {
    return _suggestionBox.values
        .where((s) => s.isEnabled && !s.isExpired)
        .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Get suggestions by category
  Future<List<Suggestion>> getSuggestionsByCategory(String category) async {
    return _suggestionBox.values
        .where((s) => s.category == category && s.isEnabled && !s.isExpired)
        .toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Update a suggestion
  Future<Suggestion?> updateSuggestion(String id, {
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    bool? isEnabled,
  }) async {
    final existing = _suggestionBox.get(id);
    if (existing == null) return null;

    final updated = existing.copyWith(
      title: title,
      description: description,
      category: category,
      priority: priority,
      expiresAt: expiresAt,
      metadata: metadata,
      isEnabled: isEnabled,
    );

    await _suggestionBox.put(id, updated);
    return updated;
  }

  /// Delete a suggestion
  Future<bool> deleteSuggestion(String id) async {
    return await _suggestionBox.delete(id) != null;
  }

  // ===============================
  // UserPreference Operations
  // ===============================

  /// Create or update a user preference
  Future<UserPreference> setUserPreference({
    required String category,
    required String key,
    required dynamic value,
    String? description,
    bool isEncrypted = false,
  }) async {
    final existing = await getUserPreference(category, key);
    
    if (existing != null) {
      final updated = existing.copyWith(
        value: value,
        updatedAt: DateTime.now(),
        isEncrypted: isEncrypted,
      );
      await _userPreferenceBox.put(existing.id, updated);
      return updated;
    } else {
      final preference = UserPreference(
        id: _generateId(),
        category: category,
        key: key,
        value: value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: description,
        isEncrypted: isEncrypted,
      );
      await _userPreferenceBox.put(preference.id, preference);
      return preference;
    }
  }

  /// Get a user preference by category and key
  Future<UserPreference?> getUserPreference(String category, String key) async {
    try {
      return _userPreferenceBox.values.firstWhere(
        (pref) => pref.category == category && pref.key == key,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all user preferences in a category
  Future<List<UserPreference>> getUserPreferencesByCategory(String category) async {
    return _userPreferenceBox.values
        .where((pref) => pref.category == category)
        .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
  }

  /// Get all user preferences
  Future<List<UserPreference>> getAllUserPreferences() async {
    return _userPreferenceBox.values.toList()
      ..sort((a, b) => a.category.compareTo(b.category));
  }

  /// Delete a user preference
  Future<bool> deleteUserPreference(String category, String key) async {
    final preference = await getUserPreference(category, key);
    if (preference == null) return false;
    return await _userPreferenceBox.delete(preference.id) != null;
  }

  // ===============================
  // MessageSummary Operations
  // ===============================

  /// Create or update a message summary
  Future<MessageSummary> setMessageSummary({
    required String conversationId,
    required String preview,
    required int messageCount,
    required DateTime lastMessageAt,
    String? senderName,
    List<String> participants = const [],
    String? category,
    bool isRead = false,
    Map<String, dynamic> metadata = const {},
  }) async {
    final existing = await getMessageSummary(conversationId);
    
    if (existing != null) {
      final updated = existing.copyWith(
        preview: preview,
        messageCount: messageCount,
        lastMessageAt: lastMessageAt,
        senderName: senderName,
        participants: participants,
        category: category,
        isRead: isRead,
        metadata: metadata,
      );
      await _messageSummaryBox.put(existing.id, updated);
      return updated;
    } else {
      final summary = MessageSummary(
        id: _generateId(),
        conversationId: conversationId,
        preview: preview,
        messageCount: messageCount,
        lastMessageAt: lastMessageAt,
        senderName: senderName,
        participants: participants,
        category: category,
        isRead: isRead,
        metadata: metadata,
      );
      await _messageSummaryBox.put(summary.id, summary);
      return summary;
    }
  }

  /// Get a message summary by conversation ID
  Future<MessageSummary?> getMessageSummary(String conversationId) async {
    try {
      return _messageSummaryBox.values.firstWhere(
        (summary) => summary.conversationId == conversationId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all message summaries
  Future<List<MessageSummary>> getAllMessageSummaries() async {
    return _messageSummaryBox.values.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  /// Get unread message summaries
  Future<List<MessageSummary>> getUnreadMessageSummaries() async {
    return _messageSummaryBox.values
        .where((summary) => !summary.isRead)
        .toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  /// Mark a message summary as read
  Future<MessageSummary?> markAsRead(String conversationId) async {
    return await updateMessageSummary(conversationId, isRead: true);
  }

  /// Update a message summary
  Future<MessageSummary?> updateMessageSummary(String conversationId, {
    String? preview,
    int? messageCount,
    DateTime? lastMessageAt,
    String? senderName,
    List<String>? participants,
    String? category,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) async {
    final existing = await getMessageSummary(conversationId);
    if (existing == null) return null;

    final updated = existing.copyWith(
      preview: preview,
      messageCount: messageCount,
      lastMessageAt: lastMessageAt,
      senderName: senderName,
      participants: participants,
      category: category,
      isRead: isRead,
      metadata: metadata,
    );

    await _messageSummaryBox.put(existing.id, updated);
    return updated;
  }

  /// Delete a message summary
  Future<bool> deleteMessageSummary(String conversationId) async {
    final summary = await getMessageSummary(conversationId);
    if (summary == null) return false;
    return await _messageSummaryBox.delete(summary.id) != null;
  }

  // ===============================
  // Data Normalization
  // ===============================

  /// Normalize incoming notification data
  Future<ContextEvent> normalizeNotification({
    required String notificationId,
    required String title,
    required String body,
    required String source,
    Map<String, dynamic>? data,
  }) async {
    return await createContextEvent(
      type: 'notification',
      data: {
        'notificationId': notificationId,
        'title': title,
        'body': body,
        'notificationData': data ?? {},
      },
      source: source,
      tags: ['notification', source],
    );
  }

  /// Normalize incoming note data
  Future<ContextEvent> normalizeNote({
    required String noteId,
    required String title,
    required String content,
    required String source,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    return await createContextEvent(
      type: 'note',
      data: {
        'noteId': noteId,
        'title': title,
        'content': content,
        'noteMetadata': metadata ?? {},
      },
      source: source,
      tags: ['note', ...?tags],
    );
  }

  /// Normalize incoming browser history data
  Future<ContextEvent> normalizeBrowserHistory({
    required String url,
    required String title,
    required DateTime visitedAt,
    required String source,
    int? visitCount,
    String? referrer,
    Map<String, dynamic>? metadata,
  }) async {
    return await createContextEvent(
      type: 'browser_history',
      data: {
        'url': url,
        'title': title,
        'visitedAt': visitedAt.toIso8601String(),
        'visitCount': visitCount ?? 1,
        'referrer': referrer,
        'historyMetadata': metadata ?? {},
      },
      source: source,
      tags: ['browser', 'history', 'web'],
    );
  }

  // ===============================
  // Utility Methods
  // ===============================

  void _addToRecentEvents(ContextEvent event) {
    _recentEvents.addFirst(event);
    while (_recentEvents.length > 100) {
      _recentEvents.removeLast();
    }
  }

  void _updateRecentEvents(ContextEvent event) {
    _removeFromRecentEvents(event.id);
    _addToRecentEvents(event);
  }

  void _removeFromRecentEvents(String eventId) {
    _recentEvents.removeWhere((event) => event.id == eventId);
  }

  String _generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch % chars.length;
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt((random + _randomStringCounter++) % chars.length)),
    );
  }

  int _randomStringCounter = 0;

  /// Clean up expired data
  Future<void> cleanupExpiredData() async {
    final now = DateTime.now();
    
    // Clean up expired suggestions
    final expiredSuggestions = _suggestionBox.values
        .where((s) => s.expiresAt != null && s.expiresAt!.isBefore(now))
        .map((s) => s.id)
        .toList();
    for (final id in expiredSuggestions) {
      await _suggestionBox.delete(id);
    }

    // Clean up old context events (older than 30 days)
    final cutoffDate = now.subtract(const Duration(days: 30));
    final oldEvents = _contextEventBox.values
        .where((e) => e.timestamp.isBefore(cutoffDate))
        .map((e) => e.id)
        .toList();
    for (final id in oldEvents) {
      await deleteContextEvent(id);
    }
  }

  /// Get storage statistics
  Future<StorageStats> getStorageStats() async {
    return StorageStats(
      contextEventCount: _contextEventBox.length,
      suggestionCount: _suggestionBox.length,
      userPreferenceCount: _userPreferenceBox.length,
      messageSummaryCount: _messageSummaryBox.length,
      recentEventCount: _recentEvents.length,
    );
  }

  /// Close all boxes and dispose resources
  Future<void> dispose() async {
    await _contextEventBox.close();
    await _suggestionBox.close();
    await _userPreferenceBox.close();
    await _messageSummaryBox.close();
    await _eventStreamController.close();
  }
}

/// Storage statistics container
class StorageStats {
  final int contextEventCount;
  final int suggestionCount;
  final int userPreferenceCount;
  final int messageSummaryCount;
  final int recentEventCount;

  const StorageStats({
    required this.contextEventCount,
    required this.suggestionCount,
    required this.userPreferenceCount,
    required this.messageSummaryCount,
    required this.recentEventCount,
  });

  int get totalCount =>
      contextEventCount + suggestionCount + userPreferenceCount + messageSummaryCount;

  @override
  String toString() {
    return 'StorageStats('
        'total: $totalCount, '
        'events: $contextEventCount, '
        'suggestions: $suggestionCount, '
        'preferences: $userPreferenceCount, '
        'messages: $messageSummaryCount, '
        'recent: $recentEventCount'
        ')';
  }
}