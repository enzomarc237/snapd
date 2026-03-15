/// Role in a chat conversation.
enum ChatRole { user, assistant, system }

/// A single message in a chat conversation.
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final String? errorText;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.errorText,
  });

  bool get isError => errorText != null;

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    String? errorText,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      errorText: errorText,
    );
  }

  @override
  String toString() => 'ChatMessage(role: ${role.name}, content: $content)';
}
