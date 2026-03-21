import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_providers.dart';
import '../utils/debug_logger.dart';
import 'navigation_service.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../../features/auth/providers/unified_auth_providers.dart';
import '../../features/chat/voice_call/presentation/voice_call_launcher.dart';
import '../../features/chat/services/file_attachment_service.dart';
import '../../shared/services/tasks/task_queue.dart';

part 'app_intents_service.g.dart';

const _askIntentId = 'app.y4shg.jyotigptapp.ask_chat';
const _voiceCallIntentId = 'app.y4shg.jyotigptapp.start_voice_call';
const _sendTextIntentId = 'app.y4shg.jyotigptapp.send_text';
const _sendUrlIntentId = 'app.y4shg.jyotigptapp.send_url';
const _sendImageIntentId = 'app.y4shg.jyotigptapp.send_image';

/// Method channel for receiving App Intent invocations from native iOS code.
/// Native Swift code defines the intents with proper titles and metadata.
/// This Flutter code handles the business logic (navigation, state management).
const _appIntentsChannel = MethodChannel('jyotigptapp/app_intents');

/// Handles iOS App Intents for Siri/Shortcuts.
///
/// Native Swift code in AppDelegate.swift defines the App Intents with proper
/// titles, descriptions, and parameters. This coordinator sets up a method
/// channel to receive invocations and execute Flutter-side business logic.
@Riverpod(keepAlive: true)
class AppIntentCoordinator extends _$AppIntentCoordinator {
  @override
  FutureOr<void> build() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    _appIntentsChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<Map<String, dynamic>> _handleMethodCall(MethodCall call) async {
    final parameters = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};

    try {
      switch (call.method) {
        case _askIntentId:
          return await _handleAskIntent(parameters);
        case _voiceCallIntentId:
          return await _handleVoiceCallIntent(parameters);
        case _sendTextIntentId:
          return await _handleSendTextIntent(parameters);
        case _sendUrlIntentId:
          return await _handleSendUrlIntent(parameters);
        case _sendImageIntentId:
          return await _handleSendImageIntent(parameters);
        default:
          return {'success': false, 'error': 'Unknown intent: ${call.method}'};
      }
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-dispatch',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': error.toString()};
    }
  }

  Future<Map<String, dynamic>> _handleAskIntent(
    Map<String, dynamic> parameters,
  ) async {
    final prompt = (parameters['prompt'] as String?)?.trim();

    try {
      await _prepareChat(prompt: prompt);
      final summary = prompt != null && prompt.isNotEmpty
          ? 'Opening chat for "$prompt"'
          : 'Opening JyotiGPT chat';

      return {'success': true, 'value': summary};
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-handle',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': 'Unable to open chat: $error'};
    }
  }

  Future<Map<String, dynamic>> _handleVoiceCallIntent(
    Map<String, dynamic> parameters,
  ) async {
    DebugLogger.log('Starting voice call from Siri/Shortcuts', scope: 'siri');

    if (!ref.mounted) {
      DebugLogger.log('Ref not mounted for voice call', scope: 'siri');
      return {'success': false, 'error': 'App not ready'};
    }

    // Check authentication state
    final navState = ref.read(authNavigationStateProvider);
    if (navState != AuthNavigationState.authenticated) {
      DebugLogger.log('Not authenticated for voice call', scope: 'siri');
      return {
        'success': false,
        'error': 'Please sign in to start a voice call',
      };
    }

    // Check if a model is selected
    final model = ref.read(selectedModelProvider);
    if (model == null) {
      DebugLogger.log('No model selected for voice call', scope: 'siri');
      return {'success': false, 'error': 'Please select a model first'};
    }

    try {
      await _startVoiceCall();
      DebugLogger.log('Voice call launched from Siri/Shortcuts', scope: 'siri');
      return {'success': true, 'value': 'Starting JyotiGPT voice call'};
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-voice',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': 'Unable to start voice call: $error'};
    }
  }

  Future<Map<String, dynamic>> _handleSendTextIntent(
    Map<String, dynamic> parameters,
  ) async {
    final text = (parameters['text'] as String?)?.trim();
    if (text == null || text.isEmpty) {
      return {'success': false, 'error': 'No text provided.'};
    }

    try {
      await _prepareChatWithOptions(
        prompt: text,
        focusComposer: true,
        resetChat: true,
      );
      return {'success': true, 'value': 'Sent to JyotiGPT'};
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-text',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': 'Unable to send text: $error'};
    }
  }

  Future<Map<String, dynamic>> _handleSendUrlIntent(
    Map<String, dynamic> parameters,
  ) async {
    final url = (parameters['url'] as String?)?.trim();
    if (url == null || url.isEmpty) {
      return {'success': false, 'error': 'No URL provided.'};
    }

    try {
      await _prepareChatWithOptions(
        prompt: url,
        focusComposer: true,
        resetChat: true,
      );

      return {'success': true, 'value': url};
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-url',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': 'Unable to send URL: $error'};
    }
  }

  Future<Map<String, dynamic>> _handleSendImageIntent(
    Map<String, dynamic> parameters,
  ) async {
    final base64 = parameters['bytes'] as String?;
    if (base64 == null || base64.isEmpty) {
      return {'success': false, 'error': 'No image data provided.'};
    }
    final filenameRaw = (parameters['filename'] as String?)?.trim();

    try {
      final file = await _materializeTempFile(
        base64,
        preferredName: filenameRaw,
      );
      await _attachFiles([file]);
      await _prepareChatWithOptions(focusComposer: true, resetChat: true);
      return {'success': true, 'value': 'Image attached in JyotiGPT'};
    } catch (error, stackTrace) {
      DebugLogger.error(
        'app-intents-image',
        scope: 'siri',
        error: error,
        stackTrace: stackTrace,
      );
      return {'success': false, 'error': 'Unable to send image: $error'};
    }
  }

  Future<void> _prepareChat({String? prompt}) async {
    await _prepareChatWithOptions(
      prompt: prompt,
      focusComposer: false,
      resetChat: false,
    );
  }

  Future<void> openChatFromExternal({
    String? prompt,
    bool focusComposer = false,
    bool resetChat = false,
  }) {
    return _prepareChatWithOptions(
      prompt: prompt,
      focusComposer: focusComposer,
      resetChat: resetChat,
    );
  }

  Future<void> startVoiceCallFromExternal() => _startVoiceCall();

  Future<void> _prepareChatWithOptions({
    String? prompt,
    bool focusComposer = false,
    bool resetChat = false,
  }) async {
    if (!ref.mounted) return;

    NavigationService.navigateToChat();

    final navState = ref.read(authNavigationStateProvider);
    if (prompt != null && prompt.isNotEmpty) {
      ref.read(prefilledInputTextProvider.notifier).set(prompt);
    }

    if (navState == AuthNavigationState.authenticated && resetChat) {
      startNewChat(ref);
    }

    if (focusComposer) {
      final tick = ref.read(inputFocusTriggerProvider);
      ref.read(inputFocusTriggerProvider.notifier).set(tick + 1);
    }
  }

  Future<void> _startVoiceCall() async {
    if (!ref.mounted) return;
    await ref
        .read(voiceCallLauncherProvider)
        .launch(startNewConversation: true);
  }

  Future<File> _materializeTempFile(
    String base64Data, {
    String? preferredName,
  }) async {
    final bytes = base64Decode(base64Data);
    const maxBytes = 20 * 1024 * 1024; // 20 MB guardrail
    if (bytes.length > maxBytes) {
      throw StateError('Image too large (max 20 MB).');
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = (preferredName != null && preferredName.isNotEmpty)
        ? preferredName
        : 'jyotigptapp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final sanitizedName = safeName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final file = File(p.join(tempDir.path, sanitizedName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _attachFiles(List<File> files) async {
    if (files.isEmpty) return;
    // Warm the attachment service to ensure dependencies are ready.
    final _ = ref.read(fileAttachmentServiceProvider);
    final notifier = ref.read(attachedFilesProvider.notifier);
    final taskQueue = ref.read(taskQueueProvider.notifier);
    final activeConv = ref.read(activeConversationProvider);

    final attachments = files
        .map((f) => LocalAttachment(file: f, displayName: p.basename(f.path)))
        .toList();

    notifier.addFiles(attachments);

    for (final attachment in attachments) {
      try {
        await taskQueue.enqueueUploadMedia(
          conversationId: activeConv?.id,
          filePath: attachment.file.path,
          fileName: attachment.displayName,
          fileSize: await attachment.file.length(),
        );
      } catch (error, stackTrace) {
        DebugLogger.error(
          'app-intents-upload',
          scope: 'siri',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }
}
