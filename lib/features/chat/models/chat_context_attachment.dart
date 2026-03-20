/// Represents a non-file attachment that enriches a chat message,
/// such as an existing knowledge base document reference.
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

enum ChatContextAttachmentType { knowledge }
