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

/// Represents the source or category of a chat context attachment.
enum ChatContextAttachmentType {
  /// Indicates an attachment sourced from the knowledge base, providing
  /// supplementary information for RAG (Retrieval-Augmented Generation).
  knowledge
}
