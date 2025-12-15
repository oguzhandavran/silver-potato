# Hive Context Storage

A secure, encrypted local storage system for managing context events, suggestions, user preferences, and message summaries using Hive.

## Overview

This library provides a comprehensive local storage solution with the following features:

- **Encrypted Storage**: All data is encrypted using AES-256 encryption
- **Type-Safe Models**: Strongly-typed data models with serialization
- **In-Memory Streaming**: Real-time event streaming for recent activities
- **Data Normalization**: Automatic processing of notifications, notes, and browser history
- **Automatic Cleanup**: Built-in data retention and cleanup mechanisms
- **Comprehensive CRUD**: Full create, read, update, delete operations

## Architecture

### Core Components

1. **HiveService**: Handles initialization, encryption key management, and Hive setup
2. **ContextRepository**: Provides unified access to all storage operations
3. **Data Models**: Type-safe models with automatic serialization

## Data Models

### ContextEvent
Represents any contextual information in the system.

```dart
class ContextEvent {
  final String id;
  final String type;           // e.g., 'notification', 'note', 'browser_history'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String source;         // e.g., 'gmail', 'chrome', 'notepad'
  final List<String> tags;
}
```

### Suggestion
Represents actionable suggestions with priorities and expiration.

```dart
class Suggestion {
  final String id;
  final String title;
  final String description;
  final String category;
  final int priority;          // 1-10 scale
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;
  final bool isEnabled;
}
```

### UserPreference
Stores user settings and preferences.

```dart
class UserPreference {
  final String id;
  final String category;       // e.g., 'app', 'notifications'
  final String key;           // e.g., 'theme', 'language'
  final dynamic value;        // Any serializable value
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final bool isEncrypted;     // Mark sensitive preferences
}
```

### MessageSummary
Summarizes conversations and messages.

```dart
class MessageSummary {
  final String id;
  final String conversationId;
  final String preview;
  final int messageCount;
  final DateTime lastMessageAt;
  final String? senderName;
  final List<String> participants;
  final String? category;
  final bool isRead;
  final Map<String, dynamic> metadata;
}
```

## Privacy & Security

### Encryption

- **Algorithm**: AES-256 encryption for all stored data
- **Key Management**: Cryptographically secure 256-bit keys generated using `dart:math`
- **Key Storage**: Encryption keys stored in SharedPreferences (note: not truly secure for production)
- **Key Derivation**: PBKDF2 key derivation with salt for additional security

### Data Protection Features

1. **Encrypted at Rest**: All Hive boxes are encrypted by default
2. **Secure Key Generation**: Uses cryptographically secure random number generation
3. **Initialization Verification**: Automatic verification of encryption setup
4. **Sensitive Data Marking**: UserPreference supports `isEncrypted` flag for additional protection

### Privacy Guarantees

- **Local Storage Only**: All data remains on the user's device
- **No Network Transmission**: Data is never sent to external servers
- **User Control**: Complete control over data creation, modification, and deletion
- **Selective Encryption**: Sensitive preferences can be marked for extra protection

## Data Retention Policies

### Automatic Cleanup

The system includes automatic data cleanup to prevent unbounded storage growth:

1. **Context Events**: Automatically removed after 30 days
2. **Expired Suggestions**: Removed when their `expiresAt` time is reached
3. **Manual Cleanup**: `cleanupExpiredData()` method for proactive maintenance

### Retention Configuration

- **Context Events**: 30-day retention (configurable in `cleanupExpiredData()`)
- **Suggestions**: Until expiration date or manual deletion
- **User Preferences**: Indefinite (user-controlled)
- **Message Summaries**: Indefinite (user-controlled)

### Manual Data Management

```dart
// Get storage statistics
final stats = await repository.getStorageStats();
print('Total items: ${stats.totalCount}');

// Cleanup expired data
await repository.cleanupExpiredData();

// Reset all data (use with caution)
await HiveService.instance.reset();
```

## Usage Examples

### Basic Setup

```dart
import 'package:hive_context_storage/repositories/context_repository.dart';

// Initialize the storage system
await HiveService.instance.initialize();
await ContextRepository.instance.initialize();
```

### ContextEvent Operations

```dart
final repository = ContextRepository.instance;

// Create a context event
final event = await repository.createContextEvent(
  type: 'notification',
  data: {
    'title': 'New Message',
    'body': 'You have a new email',
    'sender': 'john@example.com'
  },
  source: 'gmail',
  tags: ['email', 'unread'],
);

// Get recent events
final recentEvents = await repository.getRecentEvents(limit: 10);

// Filter by type
final notifications = await repository.getEventsByType('notification');

// Filter by tags
final urgentEvents = await repository.getEventsByTags(['urgent', 'important']);
```

### Suggestion Operations

```dart
// Create a suggestion
final suggestion = await repository.createSuggestion(
  title: 'Enable Dark Mode',
  description: 'Switch to dark mode for better battery life',
  category: 'appearance',
  priority: 7,
  expiresAt: DateTime.now().add(const Duration(days: 7)),
);

// Get enabled suggestions
final enabled = await repository.getEnabledSuggestions();

// Filter by category
final appearanceTips = await repository.getSuggestionsByCategory('appearance');
```

### UserPreference Operations

```dart
// Set a preference
await repository.setUserPreference(
  category: 'app',
  key: 'theme',
  value: 'dark',
  description: 'Application theme preference',
  isEncrypted: false,
);

// Get a specific preference
final theme = await repository.getUserPreference('app', 'theme');

// Get all preferences in a category
final appPrefs = await repository.getUserPreferencesByCategory('app');
```

### MessageSummary Operations

```dart
// Create/update a message summary
final summary = await repository.setMessageSummary(
  conversationId: 'email-thread-123',
  preview: 'Re: Project Update',
  messageCount: 15,
  lastMessageAt: DateTime.now(),
  senderName: 'John Doe',
  participants: ['john@example.com', 'team@company.com'],
  category: 'work',
  isRead: false,
);

// Get unread messages
final unread = await repository.getUnreadMessageSummaries();

// Mark as read
await repository.markAsRead('email-thread-123');
```

### Data Normalization

```dart
// Normalize notification data
final notifEvent = await repository.normalizeNotification(
  notificationId: 'notif-456',
  title: 'Calendar Reminder',
  body: 'Meeting in 15 minutes',
  source: 'calendar_app',
  data: {'meetingId': 'meeting-789'},
);

// Normalize note data
final noteEvent = await repository.normalizeNote(
  noteId: 'note-abc',
  title: 'Meeting Notes',
  content: 'Q1 planning discussion...',
  source: 'notes_app',
  tags: ['work', 'planning'],
);

// Normalize browser history
final historyEvent = await repository.normalizeBrowserHistory(
  url: 'https://docs.example.com/api',
  title: 'API Documentation',
  visitedAt: DateTime.now(),
  source: 'chrome',
  visitCount: 1,
  referrer: 'https://google.com',
);
```

### Real-time Event Streaming

```dart
// Listen to real-time events
final subscription = repository.eventStream.listen((event) {
  print('New event: ${event.type} from ${event.source}');
  // Handle real-time updates
});

// Remember to cancel when done
subscription.cancel();
```

## Storage Implementation

### Hive Box Structure

The system uses separate Hive boxes for each data type:

- `context_events`: Stores all ContextEvent objects
- `suggestions`: Stores Suggestion objects
- `user_preferences`: Stores UserPreference objects
- `message_summaries`: Stores MessageSummary objects

### In-Memory Caching

- **Recent Events**: Maintains the 100 most recent events in memory for fast access
- **Event Streaming**: Provides real-time updates through streams
- **Efficient Queries**: Optimized for common query patterns

### Performance Considerations

1. **Indexing**: Hive automatically indexes by key for fast lookups
2. **Pagination**: Use `limit` parameters for large datasets
3. **Filtering**: Use specific query methods instead of loading all data
4. **Cleanup**: Regular cleanup prevents storage bloat

## Error Handling

### Common Exceptions

```dart
try {
  await HiveService.instance.initialize();
} catch (e) {
  if (e is HiveInitializationException) {
    print('Failed to initialize: ${e.message}');
    // Handle initialization failure
  }
}
```

### Recovery Strategies

1. **Reset Storage**: Use `HiveService.instance.reset()` to start fresh
2. **Handle Missing Data**: Check for null returns from get operations
3. **Validate Input**: Ensure data types match expected formats

## Testing

The library includes comprehensive unit tests:

```bash
# Run all tests
flutter test

# Run specific test groups
flutter test test/models/models_test.dart
flutter test test/repositories/context_repository_test.dart
```

### Test Coverage

- **Model Serialization**: JSON encoding/decoding
- **CRUD Operations**: Create, read, update, delete for all models
- **Data Filtering**: Query operations and filtering
- **Event Streaming**: Real-time event handling
- **Storage Statistics**: Usage tracking and cleanup

## Production Considerations

### Security Enhancements

1. **Secure Key Storage**: Use platform-specific secure storage (Keychain/Keystore) instead of SharedPreferences
2. **Key Rotation**: Implement encryption key rotation mechanisms
3. **Authentication**: Add user authentication before accessing encrypted data
4. **Backup Encryption**: Ensure backups are also encrypted

### Performance Optimization

1. **Lazy Loading**: Implement lazy loading for large datasets
2. **Database Indices**: Add custom indices for complex queries
3. **Connection Pooling**: Optimize database connections for high-throughput scenarios

### Privacy Compliance

1. **GDPR Compliance**: Implement right to erasure (data deletion)
2. **Data Portability**: Export functionality for user data
3. **Consent Management**: Track user consent for data collection
4. **Audit Logging**: Log access to sensitive data

## API Reference

### ContextRepository Methods

#### ContextEvent Operations
- `createContextEvent()` - Create new context event
- `getContextEvent(id)` - Retrieve by ID
- `getAllContextEvents()` - Get all events
- `getRecentEvents(limit)` - Get recent events with limit
- `getEventsByType(type)` - Filter by type
- `getEventsBySource(source)` - Filter by source
- `getEventsByTags(tags)` - Filter by tags
- `updateContextEvent(id, ...)` - Update event
- `deleteContextEvent(id)` - Delete event

#### Suggestion Operations
- `createSuggestion()` - Create new suggestion
- `getSuggestion(id)` - Retrieve by ID
- `getAllSuggestions()` - Get all suggestions
- `getEnabledSuggestions()` - Get active suggestions only
- `getSuggestionsByCategory(category)` - Filter by category
- `updateSuggestion(id, ...)` - Update suggestion
- `deleteSuggestion(id)` - Delete suggestion

#### UserPreference Operations
- `setUserPreference()` - Create/update preference
- `getUserPreference(category, key)` - Retrieve specific preference
- `getUserPreferencesByCategory(category)` - Get category preferences
- `getAllUserPreferences()` - Get all preferences
- `deleteUserPreference(category, key)` - Delete preference

#### MessageSummary Operations
- `setMessageSummary()` - Create/update summary
- `getMessageSummary(conversationId)` - Retrieve by conversation
- `getAllMessageSummaries()` - Get all summaries
- `getUnreadMessageSummaries()` - Get unread summaries only
- `markAsRead(conversationId)` - Mark as read
- `updateMessageSummary(conversationId, ...)` - Update summary
- `deleteMessageSummary(conversationId)` - Delete summary

#### Data Normalization
- `normalizeNotification()` - Process notification data
- `normalizeNote()` - Process note data
- `normalizeBrowserHistory()` - Process browser history

#### Utility Methods
- `getStorageStats()` - Get storage usage statistics
- `cleanupExpiredData()` - Remove expired/old data
- `dispose()` - Clean up resources

### Properties
- `eventStream` - Stream of new events
- `recentEvents` - In-memory recent events list

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Contributing

Contributions are welcome! Please ensure:

1. All tests pass
2. Code follows Dart style guidelines
3. Documentation is updated for new features
4. Privacy and security considerations are addressed

## Support

For issues, questions, or contributions, please refer to the project repository or contact the development team.