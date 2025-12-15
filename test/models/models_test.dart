import 'package:test/test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import '../lib/models/models.dart';

void main() {
  group('ContextEvent Serialization', () {
    setUp(() async {
      await HiveTest.start();
      Hive.init('test_boxes');
    });

    tearDown(() async {
      await HiveTest.tearDown();
    });

    test('should serialize and deserialize correctly', () {
      final event = ContextEvent(
        id: 'test-id',
        type: 'test-type',
        data: {'key': 'value', 'number': 42},
        timestamp: DateTime.parse('2023-01-01T00:00:00Z'),
        source: 'test-source',
        tags: ['tag1', 'tag2'],
      );

      final json = event.toJson();
      expect(json['id'], equals('test-id'));
      expect(json['type'], equals('test-type'));
      expect(json['data']['key'], equals('value'));
      expect(json['data']['number'], equals(42));
      expect(json['timestamp'], equals('2023-01-01T00:00:00.000Z'));
      expect(json['source'], equals('test-source'));
      expect(json['tags'], equals(['tag1', 'tag2']));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'type': 'test-type',
        'data': {'key': 'value'},
        'timestamp': '2023-01-01T00:00:00.000Z',
        'source': 'test-source',
        'tags': ['tag1'],
      };

      final event = ContextEvent.fromJson(json);
      expect(event.id, equals('test-id'));
      expect(event.type, equals('test-type'));
      expect(event.data['key'], equals('value'));
      expect(event.timestamp, equals(DateTime.parse('2023-01-01T00:00:00Z')));
      expect(event.source, equals('test-source'));
      expect(event.tags, equals(['tag1']));
    });

    test('should support copyWith', () {
      final original = ContextEvent(
        id: 'test-id',
        type: 'test-type',
        data: {'key': 'value'},
        timestamp: DateTime.now(),
        source: 'test-source',
        tags: ['tag1'],
      );

      final copied = original.copyWith(
        type: 'new-type',
        tags: ['tag1', 'tag2'],
      );

      expect(copied.id, equals(original.id));
      expect(copied.type, equals('new-type'));
      expect(copied.data, equals(original.data));
      expect(copied.timestamp, equals(original.timestamp));
      expect(copied.source, equals(original.source));
      expect(copied.tags, equals(['tag1', 'tag2']));
    });

    test('should support props comparison', () {
      final event1 = ContextEvent(
        id: 'test-id',
        type: 'test-type',
        data: {'key': 'value'},
        timestamp: DateTime.parse('2023-01-01T00:00:00Z'),
        source: 'test-source',
        tags: ['tag1'],
      );

      final event2 = ContextEvent(
        id: 'test-id',
        type: 'test-type',
        data: {'key': 'value'},
        timestamp: DateTime.parse('2023-01-01T00:00:00Z'),
        source: 'test-source',
        tags: ['tag1'],
      );

      final event3 = ContextEvent(
        id: 'different-id',
        type: 'test-type',
        data: {'key': 'value'},
        timestamp: DateTime.parse('2023-01-01T00:00:00Z'),
        source: 'test-source',
        tags: ['tag1'],
      );

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });
  });

  group('Suggestion Serialization', () {
    setUp(() async {
      await HiveTest.start();
      Hive.init('test_boxes');
    });

    tearDown(() async {
      await HiveTest.tearDown();
    });

    test('should serialize and deserialize correctly', () {
      final suggestion = Suggestion(
        id: 'test-id',
        title: 'Test Title',
        description: 'Test Description',
        category: 'test-category',
        priority: 5,
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        expiresAt: DateTime.parse('2023-12-31T23:59:59Z'),
        metadata: {'key': 'value'},
        isEnabled: true,
      );

      final json = suggestion.toJson();
      expect(json['id'], equals('test-id'));
      expect(json['title'], equals('Test Title'));
      expect(json['description'], equals('Test Description'));
      expect(json['category'], equals('test-category'));
      expect(json['priority'], equals(5));
      expect(json['createdAt'], equals('2023-01-01T00:00:00.000Z'));
      expect(json['expiresAt'], equals('2023-12-31T23:59:59.000Z'));
      expect(json['metadata']['key'], equals('value'));
      expect(json['isEnabled'], equals(true));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Title',
        'description': 'Test Description',
        'category': 'test-category',
        'priority': 5,
        'createdAt': '2023-01-01T00:00:00.000Z',
        'expiresAt': '2023-12-31T23:59:59.000Z',
        'metadata': {'key': 'value'},
        'isEnabled': true,
      };

      final suggestion = Suggestion.fromJson(json);
      expect(suggestion.id, equals('test-id'));
      expect(suggestion.title, equals('Test Title'));
      expect(suggestion.description, equals('Test Description'));
      expect(suggestion.category, equals('test-category'));
      expect(suggestion.priority, equals(5));
      expect(suggestion.createdAt, equals(DateTime.parse('2023-01-01T00:00:00Z')));
      expect(suggestion.expiresAt, equals(DateTime.parse('2023-12-31T23:59:59Z')));
      expect(suggestion.metadata['key'], equals('value'));
      expect(suggestion.isEnabled, equals(true));
    });

    test('should handle expired suggestions', () {
      final expiredSuggestion = Suggestion(
        id: 'test-id',
        title: 'Test Title',
        description: 'Test Description',
        category: 'test-category',
        priority: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final activeSuggestion = Suggestion(
        id: 'test-id-2',
        title: 'Test Title 2',
        description: 'Test Description 2',
        category: 'test-category',
        priority: 5,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(expiredSuggestion.isExpired, isTrue);
      expect(activeSuggestion.isExpired, isFalse);
    });

    test('should support copyWith', () {
      final original = Suggestion(
        id: 'test-id',
        title: 'Test Title',
        description: 'Test Description',
        category: 'test-category',
        priority: 5,
        createdAt: DateTime.now(),
        metadata: {'key': 'value'},
        isEnabled: true,
      );

      final copied = original.copyWith(
        title: 'New Title',
        priority: 10,
        isEnabled: false,
      );

      expect(copied.id, equals(original.id));
      expect(copied.title, equals('New Title'));
      expect(copied.description, equals(original.description));
      expect(copied.category, equals(original.category));
      expect(copied.priority, equals(10));
      expect(copied.createdAt, equals(original.createdAt));
      expect(copied.metadata, equals(original.metadata));
      expect(copied.isEnabled, isFalse);
    });
  });

  group('UserPreference Serialization', () {
    setUp(() async {
      await HiveTest.start();
      Hive.init('test_boxes');
    });

    tearDown(() async {
      await HiveTest.tearDown();
    });

    test('should serialize and deserialize correctly', () {
      final preference = UserPreference(
        id: 'test-id',
        category: 'test-category',
        key: 'test-key',
        value: 'test-value',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00Z'),
        description: 'Test Description',
        isEncrypted: true,
      );

      final json = preference.toJson();
      expect(json['id'], equals('test-id'));
      expect(json['category'], equals('test-category'));
      expect(json['key'], equals('test-key'));
      expect(json['value'], equals('test-value'));
      expect(json['createdAt'], equals('2023-01-01T00:00:00.000Z'));
      expect(json['updatedAt'], equals('2023-01-02T00:00:00.000Z'));
      expect(json['description'], equals('Test Description'));
      expect(json['isEncrypted'], equals(true));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'category': 'test-category',
        'key': 'test-key',
        'value': 'test-value',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
        'description': 'Test Description',
        'isEncrypted': true,
      };

      final preference = UserPreference.fromJson(json);
      expect(preference.id, equals('test-id'));
      expect(preference.category, equals('test-category'));
      expect(preference.key, equals('test-key'));
      expect(preference.value, equals('test-value'));
      expect(preference.createdAt, equals(DateTime.parse('2023-01-01T00:00:00Z')));
      expect(preference.updatedAt, equals(DateTime.parse('2023-01-02T00:00:00Z')));
      expect(preference.description, equals('Test Description'));
      expect(preference.isEncrypted, equals(true));
    });

    test('should support type conversion', () {
      final stringPref = UserPreference(
        id: 'string-id',
        category: 'test',
        key: 'string-key',
        value: 'string-value',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final intPref = UserPreference(
        id: 'int-id',
        category: 'test',
        key: 'int-key',
        value: 42,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final boolPref = UserPreference(
        id: 'bool-id',
        category: 'test',
        key: 'bool-key',
        value: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(stringPref.getValueAs<String>(), equals('string-value'));
      expect(intPref.getValueAs<int>(), equals(42));
      expect(boolPref.getValueAs<bool>(), equals(true));
    });

    test('should support copyWith', () {
      final original = UserPreference(
        id: 'test-id',
        category: 'test-category',
        key: 'test-key',
        value: 'old-value',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00Z'),
        description: 'Old Description',
        isEncrypted: false,
      );

      final copied = original.copyWith(
        value: 'new-value',
        description: 'New Description',
        isEncrypted: true,
      );

      expect(copied.id, equals(original.id));
      expect(copied.category, equals(original.category));
      expect(copied.key, equals(original.key));
      expect(copied.value, equals('new-value'));
      expect(copied.createdAt, equals(original.createdAt));
      expect(copied.updatedAt, isNot(equals(original.updatedAt))); // Should be updated
      expect(copied.description, equals('New Description'));
      expect(copied.isEncrypted, isTrue);
    });
  });

  group('MessageSummary Serialization', () {
    setUp(() async {
      await HiveTest.start();
      Hive.init('test_boxes');
    });

    tearDown(() async {
      await HiveTest.tearDown();
    });

    test('should serialize and deserialize correctly', () {
      final summary = MessageSummary(
        id: 'test-id',
        conversationId: 'conv-id',
        preview: 'Test preview message',
        messageCount: 5,
        lastMessageAt: DateTime.parse('2023-01-01T00:00:00Z'),
        senderName: 'Test Sender',
        participants: ['user1', 'user2'],
        category: 'test-category',
        isRead: true,
        metadata: {'key': 'value'},
      );

      final json = summary.toJson();
      expect(json['id'], equals('test-id'));
      expect(json['conversationId'], equals('conv-id'));
      expect(json['preview'], equals('Test preview message'));
      expect(json['messageCount'], equals(5));
      expect(json['lastMessageAt'], equals('2023-01-01T00:00:00.000Z'));
      expect(json['senderName'], equals('Test Sender'));
      expect(json['participants'], equals(['user1', 'user2']));
      expect(json['category'], equals('test-category'));
      expect(json['isRead'], equals(true));
      expect(json['metadata']['key'], equals('value'));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'conversationId': 'conv-id',
        'preview': 'Test preview message',
        'messageCount': 5,
        'lastMessageAt': '2023-01-01T00:00:00.000Z',
        'senderName': 'Test Sender',
        'participants': ['user1', 'user2'],
        'category': 'test-category',
        'isRead': true,
        'metadata': {'key': 'value'},
      };

      final summary = MessageSummary.fromJson(json);
      expect(summary.id, equals('test-id'));
      expect(summary.conversationId, equals('conv-id'));
      expect(summary.preview, equals('Test preview message'));
      expect(summary.messageCount, equals(5));
      expect(summary.lastMessageAt, equals(DateTime.parse('2023-01-01T00:00:00Z')));
      expect(summary.senderName, equals('Test Sender'));
      expect(summary.participants, equals(['user1', 'user2']));
      expect(summary.category, equals('test-category'));
      expect(summary.isRead, equals(true));
      expect(summary.metadata['key'], equals('value'));
    });

    test('should support copyWith', () {
      final original = MessageSummary(
        id: 'test-id',
        conversationId: 'conv-id',
        preview: 'Original preview',
        messageCount: 3,
        lastMessageAt: DateTime.parse('2023-01-01T00:00:00Z'),
        senderName: 'Original Sender',
        participants: ['user1'],
        category: 'original-category',
        isRead: false,
        metadata: {'key': 'original'},
      );

      final copied = original.copyWith(
        preview: 'New preview',
        messageCount: 5,
        isRead: true,
        category: 'new-category',
      );

      expect(copied.id, equals(original.id));
      expect(copied.conversationId, equals(original.conversationId));
      expect(copied.preview, equals('New preview'));
      expect(copied.messageCount, equals(5));
      expect(copied.lastMessageAt, equals(original.lastMessageAt));
      expect(copied.senderName, equals(original.senderName));
      expect(copied.participants, equals(original.participants));
      expect(copied.category, equals('new-category'));
      expect(copied.isRead, isTrue);
      expect(copied.metadata, equals(original.metadata));
    });

    test('should handle optional fields correctly', () {
      final minimalSummary = MessageSummary(
        id: 'minimal-id',
        conversationId: 'minimal-conv',
        preview: 'Minimal preview',
        messageCount: 1,
        lastMessageAt: DateTime.now(),
      );

      expect(minimalSummary.senderName, isNull);
      expect(minimalSummary.participants, isEmpty);
      expect(minimalSummary.category, isNull);
      expect(minimalSummary.isRead, isFalse);
      expect(minimalSummary.metadata, isEmpty);
    });
  });
}