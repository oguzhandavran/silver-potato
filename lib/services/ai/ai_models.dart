enum AiProvider {
  gemini,
  openai,
  claude,
  offline,
}

enum AiTaskType {
  general,
  summarize,
  coding,
  functionCalling,
}

enum AiChatRole {
  system,
  user,
  assistant,
  tool,
}

class AiModelRef {
  final AiProvider provider;
  final String model;

  const AiModelRef({required this.provider, required this.model});

  String get id => '${provider.name}:$model';

  @override
  String toString() => id;
}

class AiChatMessage {
  final AiChatRole role;
  final String content;

  const AiChatMessage({required this.role, required this.content});

  const AiChatMessage.system(String content)
      : role = AiChatRole.system,
        content = content;

  const AiChatMessage.user(String content)
      : role = AiChatRole.user,
        content = content;

  const AiChatMessage.assistant(String content)
      : role = AiChatRole.assistant,
        content = content;

  const AiChatMessage.tool(String content)
      : role = AiChatRole.tool,
        content = content;
}

class AiToolSpec {
  final String name;
  final String description;
  final Map<String, Object?> parametersJsonSchema;

  const AiToolSpec({
    required this.name,
    required this.description,
    required this.parametersJsonSchema,
  });
}

class AiToolCall {
  final String name;
  final Map<String, Object?> arguments;

  const AiToolCall({required this.name, required this.arguments});
}

class AiChatRequest {
  final List<AiChatMessage> messages;
  final AiTaskType taskType;
  final List<AiToolSpec> tools;

  const AiChatRequest({
    required this.messages,
    this.taskType = AiTaskType.general,
    this.tools = const [],
  });

  bool get needsFunctionCalling => tools.isNotEmpty;
}

class AiChatResponse {
  final AiModelRef model;
  final String text;
  final List<AiToolCall> toolCalls;

  const AiChatResponse({
    required this.model,
    required this.text,
    this.toolCalls = const [],
  });
}

class AiClientCredentials {
  final String? apiKey;

  const AiClientCredentials({this.apiKey});
}

class AiRuntimeContext {
  final bool isOffline;

  const AiRuntimeContext({this.isOffline = false});
}

sealed class AiStreamEvent {
  const AiStreamEvent();
}

class AiStreamTextDelta extends AiStreamEvent {
  final String delta;

  const AiStreamTextDelta(this.delta);
}

class AiStreamToolCall extends AiStreamEvent {
  final AiToolCall toolCall;

  const AiStreamToolCall(this.toolCall);
}

class AiStreamDone extends AiStreamEvent {
  final AiChatResponse response;

  const AiStreamDone(this.response);
}
