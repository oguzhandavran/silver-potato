import 'dart:async';
import 'dart:math';

import 'package:flutter_shell/services/ai/ai_models.dart';
import 'package:flutter_shell/services/ai/ai_orchestrator.dart';
import 'package:flutter_shell/services/context/context_event.dart';
import 'package:flutter_shell/services/context/context_repository.dart';

import 'models/suggestion_models.dart';

class SuggestionEngine {
  final ContextRepository _contextRepository;
  final AiOrchestrator _aiOrchestrator;
  final SuggestionEngineConfig _config;
  
  final StreamController<List<Suggestion>> _suggestionsController = 
      StreamController<List<Suggestion>>.broadcast();
  final StreamController<Suggestion> _pendingSuggestionController = 
      StreamController<Suggestion>.broadcast();
  
  final Map<TemporalProfile, TemporalProfileStats> _profileStats = {};
  final Map<String, DateTime> _lastSuggestionTime = {};
  final Map<String, int> _dailySuggestionCounts = {};
  final List<Suggestion> _pendingSuggestions = [];
  final List<Suggestion> _approvedSuggestions = [];

  SuggestionEngine({
    required ContextRepository contextRepository,
    required AiOrchestrator aiOrchestrator,
    SuggestionEngineConfig? config,
  }) : _contextRepository = contextRepository,
       _aiOrchestrator = aiOrchestrator,
       _config = config ?? const SuggestionEngineConfig() {
    _initializeTemporalProfiles();
    _startEventStream();
  }

  void _initializeTemporalProfiles() {
    for (final profile in TemporalProfile.values) {
      _profileStats[profile] = TemporalProfileStats(lastActivity: DateTime.now());
    }
  }

  void _startEventStream() {
    _contextRepository.events.listen(_processContextEvent);
  }

  TemporalProfile _getCurrentTemporalProfile() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return TemporalProfile.morning;
    if (hour >= 12 && hour < 18) return TemporalProfile.afternoon;
    if (hour >= 18 && hour < 22) return TemporalProfile.evening;
    return TemporalProfile.night;
  }

  void _processContextEvent(ContextEvent event) {
    final profile = _getCurrentTemporalProfile();
    _profileStats[profile]?.lastActivity = DateTime.now();

    // Check if this event type suggests a new suggestion
    final suggestionType = _mapEventToSuggestionType(event);
    if (suggestionType != null) {
      _triggerSuggestionGeneration(suggestionType, event, profile);
    }
  }

  SuggestionType? _mapEventToSuggestionType(ContextEvent event) {
    switch (event.source) {
      case ContextEventSource.notification:
        if (event.type.contains('todo') || event.type.contains('task')) {
          return SuggestionType.todoNudge;
        }
        if (event.type.contains('message') || event.type.contains('chat')) {
          return SuggestionType.empatheticReply;
        }
        break;
      case ContextEventSource.usageStats:
        if (event.type.contains('study') || event.type.contains('learn')) {
          return SuggestionType.studyAid;
        }
        break;
      case ContextEventSource.accessibility:
        if (event.type.contains('reading') || event.type.contains('focus')) {
          return SuggestionType.studyAid;
        }
        break;
      case ContextEventSource.audioFeatures:
        if (event.type.contains('voice') || event.type.contains('meeting')) {
          return SuggestionType.empatheticReply;
        }
        break;
    }
    return null;
  }

  Future<void> _triggerSuggestionGeneration(
    SuggestionType type,
    ContextEvent event,
    TemporalProfile profile,
  ) async {
    // Check if suggestion type is enabled for this profile
    final enabledTypes = _config.enabledSuggestions[profile] ?? {};
    if (!enabledTypes.contains(type)) return;

    // Check daily limits
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    final typeKey = '${type.key}_$dateKey';
    final currentCount = _dailySuggestionCounts[typeKey] ?? 0;
    final maxCount = _config.maxDailySuggestions[type] ?? 3;

    if (currentCount >= maxCount) return;

    // Check cooldown
    final lastTime = _lastSuggestionTime[type.key];
    if (lastTime != null && 
        DateTime.now().difference(lastTime) < _config.suggestionCooldown) {
      return;
    }

    try {
      final suggestion = await _generateAiSuggestion(type, event, profile);
      suggestion.when(
        approved: (s) => _addApprovedSuggestion(s),
        pending: (s) => _addPendingSuggestion(s),
        rejected: (id) {/* ignored */},
      );
    } catch (e) {
      // Log error and potentially create fallback suggestion
      print('Error generating suggestion: $e');
    }
  }

  Future<ApprovalResult> _generateAiSuggestion(
    SuggestionType type,
    ContextEvent event,
    TemporalProfile profile,
  ) async {
    final messages = _buildAiPrompt(type, event, profile);
    
    try {
      final response = await _aiOrchestrator.chat(
        AiChatRequest(
          taskType: AiTaskType.general,
          messages: messages,
        ),
      );

      final suggestion = Suggestion(
        id: _generateId(),
        type: type,
        content: response.text,
        priority: _calculatePriority(type, event, profile),
        suggestedFor: profile,
        createdAt: DateTime.now(),
        context: event.data,
        aiAnalysis: response.text,
      );

      if (_config.autoSendEnabled) {
        return ApprovalResult.approved(suggestion);
      } else {
        return ApprovalResult.pending(suggestion);
      }
    } catch (e) {
      // Fallback suggestion
      final fallbackContent = _getFallbackContent(type);
      final suggestion = Suggestion(
        id: _generateId(),
        type: type,
        content: fallbackContent,
        priority: _calculatePriority(type, event, profile),
        suggestedFor: profile,
        createdAt: DateTime.now(),
        context: event.data,
      );
      
      return ApprovalResult.pending(suggestion);
    }
  }

  List<AiChatMessage> _buildAiPrompt(
    SuggestionType type,
    ContextEvent event,
    TemporalProfile profile,
  ) {
    final basePrompt = _getBasePrompt(type, profile);
    
    return [
      AiChatMessage.system(basePrompt),
      AiChatMessage.user('Context: ${event.data.toString()}'),
    ];
  }

  String _getBasePrompt(SuggestionType type, TemporalProfile profile) {
    final timeContext = 'Current time period: ${profile.key} (${profile.timeRange})';
    
    switch (type) {
      case SuggestionType.todoNudge:
        return '$timeContext Generate a gentle, encouraging nudge for completing a todo task. Keep it brief and motivational. Consider the current time of day for tone.';
      case SuggestionType.empatheticReply:
        return '$timeContext Help draft an empathetic, warm response to a message. The tone should be appropriate for ${profile.key} time - more energetic in morning/afternoon, calmer in evening. Be genuine and supportive.';
      case SuggestionType.studyAid:
        return '$timeContext Create a helpful study suggestion or learning tip. Adapt the approach based on ${profile.key} time - suggest shorter tips for busy periods, longer concepts for quiet times.';
    }
  }

  SuggestionPriority _calculatePriority(
    SuggestionType type,
    ContextEvent event,
    TemporalProfile profile,
  ) {
    // Analyze event data for urgency indicators
    final data = event.data;
    
    if (data.containsKey('urgent') && data['urgent'] == true) {
      return SuggestionPriority.urgent;
    }
    
    if (data.containsKey('deadline')) {
      final deadline = DateTime.tryParse(data['deadline'].toString());
      if (deadline != null) {
        final hoursUntilDeadline = deadline.difference(DateTime.now()).inHours;
        if (hoursUntilDeadline < 2) return SuggestionPriority.urgent;
        if (hoursUntilDeadline < 24) return SuggestionPriority.high;
      }
    }

    // Consider time-based priority adjustments
    switch (profile) {
      case TemporalProfile.morning:
        if (type == SuggestionType.todoNudge) return SuggestionPriority.high;
        break;
      case TemporalProfile.evening:
        if (type == SuggestionType.studyAid) return SuggestionPriority.low;
        break;
      case TemporalProfile.night:
        return SuggestionPriority.low;
      default:
        break;
    }

    // Use engagement history to adjust priority
    final engagementScore = _profileStats[profile]?.getEngagementScore(type) ?? 0.0;
    if (engagementScore < 0.3) return SuggestionPriority.low;
    if (engagementScore > 0.8) return SuggestionPriority.high;
    
    return SuggestionPriority.medium;
  }

  String _getFallbackContent(SuggestionType type) {
    switch (type) {
      case SuggestionType.todoNudge:
        return "You're doing great! Consider checking off one of your todos when you have a moment. Small wins add up!";
      case SuggestionType.empatheticReply:
        return "Remember to respond with kindness and understanding. Your words have the power to make someone's day better.";
      case SuggestionType.studyAid:
        return "Learning is a journey, not a race. Even a few minutes of focused study can make a difference today.";
    }
  }

  String _generateId() => 'suggestion_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  void _addPendingSuggestion(Suggestion suggestion) {
    _pendingSuggestions.add(suggestion);
    _pendingSuggestionController.add(suggestion);
    _emitSuggestionsUpdate();
    
    // Track daily count
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    final typeKey = '${suggestion.type.key}_$dateKey';
    _dailySuggestionCounts[typeKey] = (_dailySuggestionCounts[typeKey] ?? 0) + 1;
    _lastSuggestionTime[suggestion.type.key] = DateTime.now();
  }

  void _addApprovedSuggestion(Suggestion suggestion) {
    _approvedSuggestions.add(suggestion);
    _emitSuggestionsUpdate();
    
    // Track positive engagement for profile learning
    final profile = suggestion.suggestedFor;
    _profileStats[profile]?.recordInteraction(suggestion.type, true);
  }

  void _addRejectedSuggestion(Suggestion suggestion) {
    // Track negative engagement for profile learning
    final profile = suggestion.suggestedFor;
    _profileStats[profile]?.recordInteraction(suggestion.type, false);
  }

  void approveSuggestion(String suggestionId) {
    final suggestion = _pendingSuggestions.firstWhere(
      (s) => s.id == suggestionId,
      orElse: () => throw ArgumentError('Suggestion not found'),
    );
    
    _pendingSuggestions.removeWhere((s) => s.id == suggestionId);
    _approvedSuggestions.add(suggestion);
    _emitSuggestionsUpdate();
    
    _addApprovedSuggestion(suggestion);
  }

  void rejectSuggestion(String suggestionId) {
    final suggestion = _pendingSuggestions.firstWhere(
      (s) => s.id == suggestionId,
      orElse: () => throw ArgumentError('Suggestion not found'),
    );
    
    _pendingSuggestions.removeWhere((s) => s.id == suggestionId);
    _addRejectedSuggestion(suggestion);
    _emitSuggestionsUpdate();
  }

  void sendSuggestion(String suggestionId) {
    // For MVP, this is a placeholder. In a full implementation,
    // this would actually send the suggestion via the appropriate channel
    print('Sending suggestion $suggestionId');
  }

  Stream<List<Suggestion>> get approvedSuggestions => 
      Stream.value(_approvedSuggestions);
      
  Stream<Suggestion> get pendingSuggestions => 
      _pendingSuggestionController.stream;
      
  List<Suggestion> get currentApprovedSuggestions => 
      List.unmodifiable(_approvedSuggestions);
      
  List<Suggestion> get currentPendingSuggestions => 
      List.unmodifiable(_pendingSuggestions);

  void _emitSuggestionsUpdate() {
    final allSuggestions = [..._approvedSuggestions, ..._pendingSuggestions];
    _suggestionsController.add(allSuggestions);
  }

  TemporalProfileStats? getProfileStats(TemporalProfile profile) {
    return _profileStats[profile];
  }

  void dispose() {
    _suggestionsController.close();
    _pendingSuggestionController.close();
  }
}

sealed class ApprovalResult {
  const ApprovalResult();
  
  factory ApprovalResult.approved(Suggestion suggestion) = _Approved;
  factory ApprovalResult.pending(Suggestion suggestion) = _Pending;
  factory ApprovalResult.rejected(String suggestionId) = _Rejected;
}

class _Approved extends ApprovalResult {
  final Suggestion suggestion;
  const _Approved(this.suggestion);
}

class _Pending extends ApprovalResult {
  final Suggestion suggestion;
  const _Pending(this.suggestion);
}

class _Rejected extends ApprovalResult {
  final String suggestionId;
  const _Rejected(this.suggestionId);
}