import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_context_attachment.dart';

class ContextAttachmentsNotifier extends Notifier<List<ChatContextAttachment>> {
  @override
  List<ChatContextAttachment> build() => const [];

  void add(ChatContextAttachment attachment) {
    state = [...state, attachment];
  }

  void addKnowledge({
    required String displayName,
    required String fileId,
    String? collectionName,
    String? url,
  }) {
    final id = const Uuid().v4();
    add(
      ChatContextAttachment(
        id: id,
        type: ChatContextAttachmentType.knowledge,
        displayName: displayName,
        fileId: fileId,
        url: url,
        collectionName: collectionName,
      ),
    );
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

final contextAttachmentsProvider =
    NotifierProvider<ContextAttachmentsNotifier, List<ChatContextAttachment>>(
      ContextAttachmentsNotifier.new,
    );
