import 'dart:convert';

/// Supported AI provider types.
enum AiAgentType {
  openai,
  anthropic,
  ollama,
  gemini,
  custom,
}

extension AiAgentTypeX on AiAgentType {
  String get displayName {
    switch (this) {
      case AiAgentType.openai:
        return 'OpenAI';
      case AiAgentType.anthropic:
        return 'Anthropic';
      case AiAgentType.ollama:
        return 'Ollama (local)';
      case AiAgentType.gemini:
        return 'Google Gemini';
      case AiAgentType.custom:
        return 'Custom (OpenAI-compatible)';
    }
  }

  /// Whether this provider requires an API key.
  bool get requiresApiKey {
    switch (this) {
      case AiAgentType.ollama:
        return false;
      default:
        return true;
    }
  }

  /// Default base URL for the provider.
  String get defaultBaseUrl {
    switch (this) {
      case AiAgentType.openai:
        return 'https://api.openai.com/v1';
      case AiAgentType.anthropic:
        return 'https://api.anthropic.com/v1';
      case AiAgentType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta/openai';
      case AiAgentType.ollama:
        return 'http://localhost:11434/v1';
      case AiAgentType.custom:
        return '';
    }
  }

  /// Suggested default model identifiers.
  List<String> get suggestedModels {
    switch (this) {
      case AiAgentType.openai:
        return ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo'];
      case AiAgentType.anthropic:
        return [
          'claude-opus-4-5',
          'claude-sonnet-4-5',
          'claude-haiku-3-5',
        ];
      case AiAgentType.ollama:
        return ['llama3.2', 'mistral', 'codellama', 'qwen2.5-coder'];
      case AiAgentType.gemini:
        return ['gemini-2.0-flash', 'gemini-1.5-pro'];
      case AiAgentType.custom:
        return [];
    }
  }
}

/// Configuration for an AI agent/assistant.
class AiAgent {
  final String id;
  final String name;
  final AiAgentType type;
  final String model;
  final String? apiKey;
  final String? baseUrl;
  final String systemPrompt;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiAgent({
    required this.id,
    required this.name,
    required this.type,
    required this.model,
    this.apiKey,
    this.baseUrl,
    this.systemPrompt = '',
    this.isEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get effectiveBaseUrl => baseUrl?.isNotEmpty == true ? baseUrl! : type.defaultBaseUrl;

  AiAgent copyWith({
    String? id,
    String? name,
    AiAgentType? type,
    String? model,
    String? apiKey,
    String? baseUrl,
    String? systemPrompt,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiAgent(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'model': model,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'systemPrompt': systemPrompt,
        'isEnabled': isEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AiAgent.fromJson(Map<String, dynamic> json) {
    AiAgentType type;
    try {
      type = AiAgentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AiAgentType.custom,
      );
    } catch (_) {
      type = AiAgentType.custom;
    }
    return AiAgent(
      id: json['id'] as String,
      name: json['name'] as String,
      type: type,
      model: json['model'] as String,
      apiKey: json['apiKey'] as String?,
      baseUrl: json['baseUrl'] as String?,
      systemPrompt: json['systemPrompt'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AiAgent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AiAgent(id: $id, name: $name, type: ${type.name})';
}
