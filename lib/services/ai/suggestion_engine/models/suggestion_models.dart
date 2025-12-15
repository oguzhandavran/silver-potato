import 'dart:convert';

enum TemporalProfile {
  morning('morning', '06:00-12:00'),
  afternoon('afternoon', '12:00-18:00'),
  evening('evening', '18:00-22:00'),
  night('night', '22:00-06:00');

  const TemporalProfile(this.key, this.timeRange);
  final String key;
  final String timeRange;
}

enum SuggestionType {
  todoNudge('todo_nudge'),
  empatheticReply('empathetic_reply'),
  studyAid('study_aid');

  const SuggestionType(this.key);
  final String key;
}

enum SuggestionPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const SuggestionPriority(this.key);
  final String key;
}

class SuggestionTemplate {
  final SuggestionType type;
  final String template;
  final TemporalProfile preferredProfile;
  final SuggestionPriority defaultPriority;

  const SuggestionTemplate({
    required this.type,
    required this.template,
    required this.preferredProfile,
    this.defaultPriority = SuggestionPriority.medium,
  });

  String generateContent(Map<String, Object?> context) {
    var content = template;
    context.forEach((key, value) {
      content = content.replaceAll('{$key}', value.toString());
    });
    return content;
  }
}

class Suggestion {
  final String id;
  final SuggestionType type;
  final String content;
  final SuggestionPriority priority;
  final TemporalProfile suggestedFor;
  final DateTime createdAt;
  final Map<String, Object?> context;
  final bool requiresApproval;
  final String? aiAnalysis;

  const Suggestion({
    required this.id,
    required this.type,
    required this.content,
    required this.priority,
    required this.suggestedFor,
    required this.createdAt,
    required this.context,
    this.requiresApproval = true,
    this.aiAnalysis,
  });

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.key,
      'content': content,
      'priority': priority.key,
      'suggestedFor': suggestedProfile.key,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'context': context,
      'requiresApproval': requiresApproval,
      'aiAnalysis': aiAnalysis,
    };
  }

  factory Suggestion.fromJson(Map<String, Object?> json) {
    return Suggestion(
      id: json['id'] as String,
      type: SuggestionType.values.byName(json['type'] as String),
      content: json['content'] as String,
      priority: SuggestionPriority.values.byName(json['priority'] as String),
      suggestedFor: TemporalProfile.values.byName(json['suggestedFor'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      context: (json['context'] as Map).cast<String, Object?>(),
      requiresApproval: json['requiresApproval'] as bool? ?? true,
      aiAnalysis: json['aiAnalysis'] as String?,
    );
  }

  Suggestion copyWith({
    String? id,
    SuggestionType? type,
    String? content,
    SuggestionPriority? priority,
    TemporalProfile? suggestedFor,
    DateTime? createdAt,
    Map<String, Object?>? context,
    bool? requiresApproval,
    String? aiAnalysis,
  }) {
    return Suggestion(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      suggestedFor: suggestedFor ?? this.suggestedFor,
      createdAt: createdAt ?? this.createdAt,
      context: context ?? this.context,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    );
  }
}

class TemporalProfileStats {
  final Map<SuggestionType, int> interactionCounts = {};
  final Map<SuggestionType, double> engagementScores = {};
  final DateTime lastActivity;

  TemporalProfileStats({required this.lastActivity});

  void recordInteraction(SuggestionType type, bool engaged) {
    interactionCounts[type] = (interactionCounts[type] ?? 0) + 1;
    final currentScore = engagementScores[type] ?? 0.0;
    final newScore = engaged ? currentScore + 0.1 : currentScore - 0.05;
    engagementScores[type] = newScore.clamp(0.0, 1.0);
  }

  double getEngagementScore(SuggestionType type) {
    return engagementScores[type] ?? 0.0;
  }

  int getInteractionCount(SuggestionType type) {
    return interactionCounts[type] ?? 0;
  }
}

class SuggestionEngineConfig {
  final bool autoSendEnabled;
  final Map<TemporalProfile, Set<SuggestionType>> enabledSuggestions;
  final Map<SuggestionType, int> maxDailySuggestions;
  final Duration suggestionCooldown;

  const SuggestionEngineConfig({
    this.autoSendEnabled = false,
    this.enabledSuggestions = const {},
    this.maxDailySuggestions = const {},
    this.suggestionCooldown = const Duration(hours: 1),
  });
}