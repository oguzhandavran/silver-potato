import 'package:flutter_shell/services/ai/suggestion_engine/models/suggestion_models.dart';

/// Documentation for extending the Suggestion Engine with new suggestion types
/// 
/// ## Overview
/// The Suggestion Engine is designed to be extensible, allowing you to add new types of AI-generated suggestions
/// that are tailored to specific contexts and temporal profiles.
///
/// ## Adding a New Suggestion Type
///
/// ### 1. Define the New Type
/// Add your new suggestion type to the `SuggestionType` enum:
/// 
/// ```dart
/// enum SuggestionType {
///   // ... existing types
///   yourNewType('your_new_type');
///   
///   const SuggestionType(this.key);
///   final String key;
/// }
/// ```
///
/// ### 2. Create Context Mapping Logic
/// Extend the `_mapEventToSuggestionType` method in `suggestion_engine.dart`:
/// 
/// ```dart
/// SuggestionType? _mapEventToSuggestionType(ContextEvent event) {
///   switch (event.source) {
///     // ... existing cases
///     case ContextEventSource.usageStats:
///       if (event.type.contains('your_event_type')) {
///         return SuggestionType.yourNewType;
///       }
///       break;
///   }
///   return null;
/// }
/// ```
///
/// ### 3. Define AI Prompt Template
/// Add a new case to the `_getBasePrompt` method:
/// 
/// ```dart
/// String _getBasePrompt(SuggestionType type, TemporalProfile profile) {
///   final timeContext = 'Current time period: ${profile.key} (${profile.timeRange})';
///   
///   switch (type) {
///     // ... existing cases
///     case SuggestionType.yourNewType:
///       return '$timeContext Create a personalized suggestion for your new use case. '
///              'Adapt tone based on ${profile.key} time period.';
///   }
/// }
/// ```
///
/// ### 4. Configure Default Behavior
/// Update the `suggestionEngineConfigProvider` in `suggestion_engine_providers.dart`:
/// 
/// ```dart
/// final suggestionEngineConfigProvider = Provider<SuggestionEngineConfig>((ref) {
///   return const SuggestionEngineConfig(
///     // ... existing config
///     enabledSuggestions: {
///       TemporalProfile.morning: {
///         // ... existing types
///         SuggestionType.yourNewType,
///       },
///       // ... other profiles
///     },
///     maxDailySuggestions: {
///       // ... existing limits
///       SuggestionType.yourNewType: 5, // Set your daily limit
///     },
///   );
/// });
/// ```
///
/// ### 5. Update UI Components
/// Add support in `suggestion_approval_screen.dart`:
///
/// ```dart
/// Widget _buildTypeIcon(SuggestionType type) {
///   switch (type) {
///     // ... existing cases
///     case SuggestionType.yourNewType:
///       icon = Icons.your_icon;
///       color = Colors.yourColor;
///       break;
///   }
/// }
///
/// String _getTypeDisplayName(SuggestionType type) {
///   switch (type) {
///     // ... existing cases
///     case SuggestionType.yourNewType:
///       return 'Your New Type';
///   }
/// }
/// ```
///
/// ### 6. Add Template Support
/// If you want to use template-based generation, add to the templates list:
/// 
/// ```dart
/// List<SuggestionTemplate> _getTemplates() {
///   return [
///     // ... existing templates
///     SuggestionTemplate(
///       type: SuggestionType.yourNewType,
///       template: 'Your template with {placeholders} for context variables',
///       preferredProfile: TemporalProfile.yourPreferredProfile,
///     ),
///   ];
/// }
/// ```
///
/// ## Advanced Extensions
///
/// ### Custom Prioritization Logic
/// Override the `_calculatePriority` method for type-specific priority rules:
/// 
/// ```dart
/// SuggestionPriority _calculatePriority(
///   SuggestionType type,
///   ContextEvent event,
///   TemporalProfile profile,
/// ) {
///   if (type == SuggestionType.yourNewType) {
///     // Your custom logic
///     if (event.data.containsKey('urgent_flag')) {
///       return SuggestionPriority.urgent;
///     }
///   }
///   
///   // Fall back to default logic
///   return super._calculatePriority(type, event, profile);
/// }
/// ```
///
/// ### Integration with External Services
/// Extend the `sendSuggestion` method to integrate with external APIs:
///
/// ```dart
/// void sendSuggestion(String suggestionId) {
///   final suggestion = _approvedSuggestions.firstWhere((s) => s.id == suggestionId);
///   
///   switch (suggestion.type) {
///     case SuggestionType.yourNewType:
///       _sendToYourService(suggestion);
///       break;
///     default:
///       print('Sending suggestion $suggestionId');
///   }
/// }
///
/// Future<void> _sendToYourService(Suggestion suggestion) async {
///   // Your custom sending logic
///   await yourApiClient.sendSuggestion(suggestion);
/// }
/// ```
///
/// ### Custom Context Processors
/// Create specialized context processors for your suggestion type:
///
/// ```dart
/// class YourTypeContextProcessor {
///   static Map<String, Object?> processContext(Map<String, Object?> rawContext) {
///     return {
///       ...rawContext,
///       'processed_for_your_type': _specialProcessing(rawContext),
///     };
///   }
///   
///   static String _specialProcessing(Map<String, Object?> context) {
///     // Your processing logic
///     return 'processed_value';
///   }
/// }
/// ```
///
/// ## Best Practices
///
/// 1. **Temporal Awareness**: Always consider the temporal profile when generating suggestions
/// 2. **Context Sensitivity**: Use relevant context data to personalize suggestions
/// 3. **User Engagement**: Track engagement to improve future suggestions
/// 4. **Rate Limiting**: Respect daily limits and cooldowns to avoid user fatigue
/// 5. **Fallback Content**: Provide meaningful fallback content when AI generation fails
/// 6. **Testing**: Write unit tests for your custom logic and prioritization heuristics
/// 7. **Privacy**: Be mindful of sensitive context data and follow privacy guidelines
///
/// ## Testing Your Extension
///
/// ```dart
/// void main() {
///   group('Your New Suggestion Type', () {
///     test('should generate appropriate suggestions for morning profile', () {
///       // Your test logic
///     });
///     
///     test('should respect daily limits', () {
///       // Your test logic
///     });
///     
///     test('should prioritize correctly based on context', () {
///       // Your test logic
///     });
///   });
/// }
/// ```
///
/// This extension guide ensures that new suggestion types integrate seamlessly with the existing
/// temporal profiling system and maintain consistent user experience patterns.
