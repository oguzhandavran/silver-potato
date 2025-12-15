import 'package:test/test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../lib/repositories/context_repository.dart';
import '../lib/models/models.dart';

// Generate mock classes
@GenerateMocks([Box])
import 'context_repository_test.mocks.dart';

void main() {
  group('ContextRepository CRUD Operations', () {
    late ContextRepository repository;
    late MockBox<ContextEvent> mockEventBox;
    late MockBox<Suggestion> mockSuggestionBox;
    late MockBox<UserPreference> mockPreferenceBox;
    late MockBox<MessageSummary> mockMessageBox;

    setUp(() async {
      await HiveTest.start();
      
      repository = ContextRepository.instance;
      
      // Create mock boxes
      mockEventBox = MockBox<ContextEvent>();
      mockSuggestionBox = MockBox<Suggestion>();
      mockPreferenceBox = MockBox<UserPreference>();
      mockMessageBox = MockBox<MessageSummary>();
    });

    tearDown(() async {
      await HiveTest.tearDown();
    });

    group('ContextEvent CRUD', () {
      test('should create context event successfully', () async {
        final testEvent = ContextEvent(
          id: 'test-event-id',
          type: 'notification',
          data: {'title': 'Test', 'body': 'Test body'},
          timestamp: DateTime.now(),
          source: 'test-source',
          tags: ['test'],
        );

        when(mockEventBox.put(testEvent.id, testEvent)).thenAnswer((_) async => null);

        // Since we're testing the actual repository logic, 
        // we'll need to test with real Hive boxes for integration
        final event = await repository.createContextEvent(
          type: 'notification',
          data: {'title': 'Test', 'body': 'Test body'},
          source: 'test-source',
          tags: ['test'],
        );

        expect(event.type, equals('notification'));
        expect(event.data['title'], equals('Test'));
        expect(event.source, equals('test-source'));
        expect(event.tags, equals(['test']));
      });

      test('should update context event successfully', () async {
        // First create an event
        final event = await repository.createContextEvent(
          type: 'notification',
          data: {'title': 'Original'},
          source: 'test-source',
        );

        final updated = await repository.updateContextEvent(
          event.id,
          type: 'note',
          data: {'title': 'Updated'},
        );

        expect(updated, isNotNull);
        expect(updated!.type, equals('note'));
        expect(updated.data['title'], equals('Updated'));
        expect(updated.id, equals(event.id));
      });

      test('should get context event by ID', () async {
        final created = await repository.createContextEvent(
          type: 'test-type',
          data: {'key': 'value'},
          source: 'test-source',
        );

        final retrieved = await repository.getContextEvent(created.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(created.id));
        expect(retrieved.type, equals('test-type'));
      });

      test('should delete context event successfully', () async {
        final event = await repository.createContextEvent(
          type: 'test-type',
          data: {},
          source: 'test-source',
        );

        final deleted = await repository.deleteContextEvent(event.id);

        expect(deleted, isTrue);

        final retrieved = await repository.getContextEvent(event.id);
        expect(retrieved, isNull);
      });

      test('should filter events by type', () async {
        await repository.createContextEvent(
          type: 'notification',
          data: {},
          source: 'source1',
        );
        await repository.createContextEvent(
          type: 'note',
          data: {},
          source: 'source2',
        );
        await repository.createContextEvent(
          type: 'notification',
          data: {},
          source: 'source3',
        );

        final notifications = await repository.getEventsByType('notification');
        final notes = await repository.getEventsByType('note');

        expect(notifications.length, equals(2));
        expect(notes.length, equals(1));
        expect(notifications.every((e) => e.type == 'notification'), isTrue);
        expect(notes.every((e) => e.type == 'note'), isTrue);
      });

      test('should filter events by source', () async {
        await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'source1',
        );
        await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'source2',
        );

        final source1Events = await repository.getEventsBySource('source1');
        final source2Events = await repository.getEventsBySource('source2');

        expect(source1Events.length, equals(1));
        expect(source2Events.length, equals(1));
        expect(source1Events.first.source, equals('source1'));
        expect(source2Events.first.source, equals('source2'));
      });

      test('should filter events by tags', () async {
        await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'test',
          tags: ['work', 'urgent'],
        );
        await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'test',
          tags: ['personal'],
        );
        await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'test',
          tags: ['work'],
        );

        final workEvents = await repository.getEventsByTags(['work']);
        final urgentEvents = await repository.getEventsByTags(['urgent']);

        expect(workEvents.length, equals(2));
        expect(urgentEvents.length, equals(1));
      });
    });

    group('Suggestion CRUD', () {
      test('should create suggestion successfully', () async {
        final suggestion = await repository.createSuggestion(
          title: 'Test Suggestion',
          description: 'Test Description',
          category: 'productivity',
          priority: 5,
        );

        expect(suggestion.title, equals('Test Suggestion'));
        expect(suggestion.description, equals('Test Description'));
        expect(suggestion.category, equals('productivity'));
        expect(suggestion.priority, equals(5));
        expect(suggestion.isEnabled, isTrue);
        expect(suggestion.isExpired, isFalse);
      });

      test('should get enabled suggestions', () async {
        await repository.createSuggestion(
          title: 'Enabled Suggestion',
          description: 'Description',
          category: 'test',
          priority: 5,
          isEnabled: true,
        );
        
        await repository.createSuggestion(
          title: 'Disabled Suggestion',
          description: 'Description',
          category: 'test',
          priority: 3,
          isEnabled: false,
        );

        await repository.createSuggestion(
          title: 'Expired Suggestion',
          description: 'Description',
          category: 'test',
          priority: 4,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          isEnabled: true,
        );

        final enabled = await repository.getEnabledSuggestions();

        expect(enabled.length, equals(1));
        expect(enabled.first.title, equals('Enabled Suggestion'));
      });

      test('should filter suggestions by category', () async {
        await repository.createSuggestion(
          title: 'Productivity Tip',
          description: 'Description',
          category: 'productivity',
          priority: 5,
        );
        
        await repository.createSuggestion(
          title: 'Security Tip',
          description: 'Description',
          category: 'security',
          priority: 3,
        );

        final productivity = await repository.getSuggestionsByCategory('productivity');
        final security = await repository.getSuggestionsByCategory('security');

        expect(productivity.length, equals(1));
        expect(security.length, equals(1));
        expect(productivity.first.category, equals('productivity'));
        expect(security.first.category, equals('security'));
      });

      test('should detect expired suggestions', () async {
        final expiredSuggestion = await repository.createSuggestion(
          title: 'Expired',
          description: 'Description',
          category: 'test',
          priority: 5,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        final activeSuggestion = await repository.createSuggestion(
          title: 'Active',
          description: 'Description',
          category: 'test',
          priority: 3,
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        );

        expect(expiredSuggestion.isExpired, isTrue);
        expect(activeSuggestion.isExpired, isFalse);
      });

      test('should update suggestion successfully', () async {
        final created = await repository.createSuggestion(
          title: 'Original Title',
          description: 'Original Description',
          category: 'test',
          priority: 5,
        );

        final updated = await repository.updateSuggestion(
          created.id,
          title: 'Updated Title',
          priority: 10,
          isEnabled: false,
        );

        expect(updated, isNotNull);
        expect(updated!.title, equals('Updated Title'));
        expect(updated.priority, equals(10));
        expect(updated.isEnabled, isFalse);
        expect(updated.id, equals(created.id));
      });

      test('should delete suggestion successfully', () async {
        final suggestion = await repository.createSuggestion(
          title: 'Test Suggestion',
          description: 'Description',
          category: 'test',
          priority: 5,
        );

        final deleted = await repository.deleteSuggestion(suggestion.id);

        expect(deleted, isTrue);

        final retrieved = await repository.getSuggestion(suggestion.id);
        expect(retrieved, isNull);
      });
    });

    group('UserPreference CRUD', () {
      test('should set and get user preference', () async {
        final set = await repository.setUserPreference(
          category: 'app',
          key: 'theme',
          value: 'dark',
          description: 'App theme preference',
          isEncrypted: false,
        );

        expect(set.category, equals('app'));
        expect(set.key, equals('theme'));
        expect(set.value, equals('dark'));
        expect(set.description, equals('App theme preference'));

        final retrieved = await repository.getUserPreference('app', 'theme');

        expect(retrieved, isNotNull);
        expect(retrieved!.category, equals('app'));
        expect(retrieved.key, equals('theme'));
        expect(retrieved.value, equals('dark'));
      });

      test('should update existing preference', () async {
        await repository.setUserPreference(
          category: 'app',
          key: 'language',
          value: 'en',
        );

        await repository.setUserPreference(
          category: 'app',
          key: 'language',
          value: 'es',
        );

        final retrieved = await repository.getUserPreference('app', 'language');

        expect(retrieved, isNotNull);
        expect(retrieved!.value, equals('es'));
        expect(retrieved.updatedAt, isNot(equals(retrieved.createdAt)));
      });

      test('should get preferences by category', () async {
        await repository.setUserPreference(
          category: 'app',
          key: 'theme',
          value: 'dark',
        );
        await repository.setUserPreference(
          category: 'app',
          key: 'language',
          value: 'en',
        );
        await repository.setUserPreference(
          category: 'notifications',
          key: 'enabled',
          value: true,
        );

        final appPrefs = await repository.getUserPreferencesByCategory('app');
        final notificationPrefs = await repository.getUserPreferencesByCategory('notifications');

        expect(appPrefs.length, equals(2));
        expect(notificationPrefs.length, equals(1));
        expect(appPrefs.every((p) => p.category == 'app'), isTrue);
        expect(notificationPrefs.first.key, equals('enabled'));
      });

      test('should delete user preference', () async {
        await repository.setUserPreference(
          category: 'test',
          key: 'key1',
          value: 'value1',
        );

        final deleted = await repository.deleteUserPreference('test', 'key1');

        expect(deleted, isTrue);

        final retrieved = await repository.getUserPreference('test', 'key1');
        expect(retrieved, isNull);
      });
    });

    group('MessageSummary CRUD', () {
      test('should set and get message summary', () async {
        final summary = await repository.setMessageSummary(
          conversationId: 'conv-123',
          preview: 'Hello, how are you?',
          messageCount: 5,
          lastMessageAt: DateTime.now(),
          senderName: 'John Doe',
          participants: ['user1', 'user2'],
          category: 'personal',
          isRead: false,
        );

        expect(summary.conversationId, equals('conv-123'));
        expect(summary.preview, equals('Hello, how are you?'));
        expect(summary.messageCount, equals(5));
        expect(summary.senderName, equals('John Doe'));
        expect(summary.participants, equals(['user1', 'user2']));
        expect(summary.category, equals('personal'));
        expect(summary.isRead, isFalse);

        final retrieved = await repository.getMessageSummary('conv-123');

        expect(retrieved, isNotNull);
        expect(retrieved!.conversationId, equals('conv-123'));
        expect(retrieved.preview, equals('Hello, how are you?'));
      });

      test('should get unread message summaries', () async {
        await repository.setMessageSummary(
          conversationId: 'conv-1',
          preview: 'Read message',
          messageCount: 2,
          lastMessageAt: DateTime.now(),
          isRead: true,
        );
        
        await repository.setMessageSummary(
          conversationId: 'conv-2',
          preview: 'Unread message',
          messageCount: 1,
          lastMessageAt: DateTime.now(),
          isRead: false,
        );

        final unread = await repository.getUnreadMessageSummaries();

        expect(unread.length, equals(1));
        expect(unread.first.conversationId, equals('conv-2'));
      });

      test('should mark message as read', () async {
        await repository.setMessageSummary(
          conversationId: 'conv-123',
          preview: 'Test message',
          messageCount: 1,
          lastMessageAt: DateTime.now(),
          isRead: false,
        );

        final marked = await repository.markAsRead('conv-123');

        expect(marked, isNotNull);
        expect(marked!.isRead, isTrue);

        final unread = await repository.getUnreadMessageSummaries();
        expect(unread.length, equals(0));
      });

      test('should update message summary', () async {
        await repository.setMessageSummary(
          conversationId: 'conv-123',
          preview: 'Original preview',
          messageCount: 1,
          lastMessageAt: DateTime.now(),
        );

        final updated = await repository.updateMessageSummary(
          'conv-123',
          preview: 'Updated preview',
          messageCount: 5,
          isRead: true,
        );

        expect(updated, isNotNull);
        expect(updated!.preview, equals('Updated preview'));
        expect(updated.messageCount, equals(5));
        expect(updated.isRead, isTrue);
      });

      test('should delete message summary', () async {
        await repository.setMessageSummary(
          conversationId: 'conv-123',
          preview: 'Test message',
          messageCount: 1,
          lastMessageAt: DateTime.now(),
        );

        final deleted = await repository.deleteMessageSummary('conv-123');

        expect(deleted, isTrue);

        final retrieved = await repository.getMessageSummary('conv-123');
        expect(retrieved, isNull);
      });
    });

    group('Data Normalization', () {
      test('should normalize notification data', () async {
        final event = await repository.normalizeNotification(
          notificationId: 'notif-123',
          title: 'New Message',
          body: 'You have a new message',
          source: 'gmail',
          data: {'sender': 'john@example.com'},
        );

        expect(event.type, equals('notification'));
        expect(event.data['notificationId'], equals('notif-123'));
        expect(event.data['title'], equals('New Message'));
        expect(event.data['body'], equals('You have a new message'));
        expect(event.source, equals('gmail'));
        expect(event.tags, contains('notification'));
        expect(event.tags, contains('gmail'));
      });

      test('should normalize note data', () async {
        final event = await repository.normalizeNote(
          noteId: 'note-456',
          title: 'Meeting Notes',
          content: 'Important meeting details...',
          source: 'notepad',
          tags: ['work', 'meeting'],
          metadata: {'color': 'yellow'},
        );

        expect(event.type, equals('note'));
        expect(event.data['noteId'], equals('note-456'));
        expect(event.data['title'], equals('Meeting Notes'));
        expect(event.data['content'], equals('Important meeting details...'));
        expect(event.source, equals('notepad'));
        expect(event.tags, contains('note'));
        expect(event.tags, contains('work'));
        expect(event.tags, contains('meeting'));
      });

      test('should normalize browser history data', () async {
        final visitedAt = DateTime.now();
        final event = await repository.normalizeBrowserHistory(
          url: 'https://example.com',
          title: 'Example Page',
          visitedAt: visitedAt,
          source: 'chrome',
          visitCount: 3,
          referrer: 'https://google.com',
          metadata: {'session': 'abc123'},
        );

        expect(event.type, equals('browser_history'));
        expect(event.data['url'], equals('https://example.com'));
        expect(event.data['title'], equals('Example Page'));
        expect(event.data['visitCount'], equals(3));
        expect(event.data['referrer'], equals('https://google.com'));
        expect(event.source, equals('chrome'));
        expect(event.tags, containsAll(['browser', 'history', 'web']));
      });
    });

    group('Storage Statistics and Cleanup', () {
      test('should provide storage statistics', () async {
        await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'test',
        );
        
        await repository.createSuggestion(
          title: 'Test',
          description: 'Description',
          category: 'test',
          priority: 1,
        );
        
        await repository.setUserPreference(
          category: 'test',
          key: 'key1',
          value: 'value1',
        );
        
        await repository.setMessageSummary(
          conversationId: 'conv-1',
          preview: 'Test message',
          messageCount: 1,
          lastMessageAt: DateTime.now(),
        );

        final stats = await repository.getStorageStats();

        expect(stats.contextEventCount, equals(1));
        expect(stats.suggestionCount, equals(1));
        expect(stats.userPreferenceCount, equals(1));
        expect(stats.messageSummaryCount, equals(1));
        expect(stats.totalCount, equals(4));
      });

      test('should clean up expired data', () async {
        // Create active suggestion
        await repository.createSuggestion(
          title: 'Active Suggestion',
          description: 'Description',
          category: 'test',
          priority: 1,
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        );

        // Create expired suggestion
        await repository.createSuggestion(
          title: 'Expired Suggestion',
          description: 'Description',
          category: 'test',
          priority: 2,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        await repository.cleanupExpiredData();

        final allSuggestions = await repository.getAllSuggestions();
        expect(allSuggestions.length, equals(1));
        expect(allSuggestions.first.title, equals('Active Suggestion'));
      });
    });

    group('In-Memory Event Streaming', () {
      test('should stream new events', () async {
        final events = <ContextEvent>[];
        
        // Listen to event stream
        repository.eventStream.listen(events.add);

        final event1 = await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'test',
        );

        final event2 = await repository.createContextEvent(
          type: 'test',
          data: {},
          source: 'test',
        );

        await Future.delayed(const Duration(milliseconds: 100)); // Allow stream processing

        expect(events.length, equals(2));
        expect(events[0].id, equals(event1.id));
        expect(events[1].id, equals(event2.id));
      });

      test('should maintain recent events in memory', () async {
        // Create multiple events
        for (int i = 0; i < 5; i++) {
          await repository.createContextEvent(
            type: 'test',
            data: {'index': i},
            source: 'test',
          );
        }

        final recent = repository.recentEvents;
        expect(recent.length, lessThanOrEqualTo(5));
        expect(recent.first.data['index'], equals(4)); // Most recent first
      });
    });
  });
}