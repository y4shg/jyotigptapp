/// Represents a knowledge-base document reference that enriches a
/// chat message.
class ChatContextAttachment {
  const ChatContextAttachment({
    required this.id,
    required this.type,
    required this.displayName,
    this.url,
    this.content,
    this.collectionName,
    this.fileId,
  });

  final String id;
  final ChatContextAttachmentType type;
  final String displayName;
  final String? url;
  final String? content;
  final String? collectionName;
  final String? fileId;
}

/// The type of context attachment included with a chat message.
enum ChatContextAttachmentType {
  /// Attachment sourced from the knowledge base.
  ///
  /// This represents a document or snippet that should be treated as
  /// reference material for the conversation context.
  knowledge,
}
