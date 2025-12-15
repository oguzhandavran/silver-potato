import 'dart:async';
import 'lib/hive_context_storage.dart';

/// Example usage of the Hive Context Storage system
Future<void> main() async {
  print('🚀 Hive Context Storage Example');
  
  try {
    // 1. Initialize Hive with encryption
    print('🔐 Initializing Hive with encryption...');
    await HiveService.instance.initialize();
    print('✅ Hive initialized successfully');
    
    // 2. Initialize the repository
    print('📦 Initializing Context Repository...');
    await ContextRepository.instance.initialize();
    print('✅ Repository initialized successfully');
    
    // 3. Create some context events
    print('📝 Creating context events...');
    
    final notification = await ContextRepository.instance.createContextEvent(
      type: 'notification',
      data: {
        'title': 'Welcome!',
        'body': 'Thanks for using Hive Context Storage',
        'sender': 'system'
      },
      source: 'example_app',
      tags: ['welcome', 'system'],
    );
    print('Created notification: ${notification.id}');
    
    final note = await ContextRepository.instance.normalizeNote(
      noteId: 'note-123',
      title: 'Meeting Notes',
      content: 'Q1 planning meeting - discuss new features',
      source: 'notes_app',
      tags: ['work', 'planning'],
      metadata: {'color': 'yellow'},
    );
    print('Created note: ${note.id}');
    
    final history = await ContextRepository.instance.normalizeBrowserHistory(
      url: 'https://hivedb.dev',
      title: 'Hive Database Documentation',
      visitedAt: DateTime.now(),
      source: 'chrome',
      visitCount: 1,
    );
    print('Created browser history: ${history.id}');
    
    // 4. Create some suggestions
    print('💡 Creating suggestions...');
    
    final suggestion1 = await ContextRepository.instance.createSuggestion(
      title: 'Enable Notifications',
      description: 'Get notified about important events',
      category: 'app_settings',
      priority: 8,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    print('Created suggestion: ${suggestion1.id}');
    
    final suggestion2 = await ContextRepository.instance.createSuggestion(
      title: 'Dark Mode Available',
      description: 'Switch to dark mode for better battery life',
      category: 'appearance',
      priority: 6,
    );
    print('Created suggestion: ${suggestion2.id}');
    
    // 5. Set user preferences
    print('⚙️ Setting user preferences...');
    
    await ContextRepository.instance.setUserPreference(
      category: 'app',
      key: 'theme',
      value: 'dark',
      description: 'Application theme preference',
    );
    print('Set theme preference');
    
    await ContextRepository.instance.setUserPreference(
      category: 'notifications',
      key: 'enabled',
      value: true,
      description: 'Enable notifications',
    );
    print('Set notification preference');
    
    await ContextRepository.instance.setUserPreference(
      category: 'security',
      key: 'biometric_auth',
      value: false,
      description: 'Use biometric authentication',
      isEncrypted: true,
    );
    print('Set security preference (encrypted)');
    
    // 6. Create message summaries
    print('💬 Creating message summaries...');
    
    await ContextRepository.instance.setMessageSummary(
      conversationId: 'email-thread-123',
      preview: 'Re: Q1 Planning Meeting',
      messageCount: 15,
      lastMessageAt: DateTime.now(),
      senderName: 'John Doe',
      participants: ['john@example.com', 'team@company.com'],
      category: 'work',
      isRead: false,
    );
    print('Created message summary');
    
    await ContextRepository.instance.setMessageSummary(
      conversationId: 'chat-room-general',
      preview: 'Welcome to the team! 🎉',
      messageCount: 42,
      lastMessageAt: DateTime.now(),
      senderName: 'HR Bot',
      participants: ['user1', 'user2', 'user3', 'hr@company.com'],
      category: 'announcements',
      isRead: true,
    );
    print('Created another message summary');
    
    // 7. Demonstrate queries
    print('\n📊 Querying data...');
    
    // Get recent events
    final recentEvents = await ContextRepository.instance.getRecentEvents(limit: 5);
    print('Recent events (${recentEvents.length}):');
    for (final event in recentEvents) {
      print('  - ${event.type} from ${event.source}');
    }
    
    // Get enabled suggestions
    final enabledSuggestions = await ContextRepository.instance.getEnabledSuggestions();
    print('Enabled suggestions (${enabledSuggestions.length}):');
    for (final suggestion in enabledSuggestions) {
      print('  - ${suggestion.title} (priority: ${suggestion.priority})');
    }
    
    // Get app preferences
    final appPrefs = await ContextRepository.instance.getUserPreferencesByCategory('app');
    print('App preferences (${appPrefs.length}):');
    for (final pref in appPrefs) {
      print('  - ${pref.key}: ${pref.value}');
    }
    
    // Get unread messages
    final unreadMessages = await ContextRepository.instance.getUnreadMessageSummaries();
    print('Unread messages (${unreadMessages.length}):');
    for (final msg in unreadMessages) {
      print('  - ${msg.preview}');
    }
    
    // 8. Demonstrate event streaming
    print('\n🌊 Setting up event streaming...');
    final eventSubscription = ContextRepository.instance.eventStream.listen((event) {
      print('📡 New event received: ${event.type} from ${event.source}');
    });
    
    // Create a new event to test streaming
    await ContextRepository.instance.createContextEvent(
      type: 'test_stream',
      data: {'message': 'Testing real-time streaming'},
      source: 'example',
      tags: ['stream', 'test'],
    );
    
    // 9. Get storage statistics
    print('\n📈 Storage statistics:');
    final stats = await ContextRepository.instance.getStorageStats();
    print('$stats');
    
    // 10. Clean up
    print('\n🧹 Cleaning up...');
    await eventSubscription.cancel();
    await ContextRepository.instance.dispose();
    print('✅ Cleanup complete');
    
    print('\n🎉 Example completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}