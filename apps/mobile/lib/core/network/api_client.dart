import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/ai_stream_event.dart';
import '../utils/cancel_token.dart';

class AiRouterClient {
  final String supabaseFunctionsBaseUrl;

  AiRouterClient(this.supabaseFunctionsBaseUrl);

  Stream<AiStreamEvent> streamCompletion({
    required String provider,
    required String model,
    required List<Map<String, dynamic>> messages,
    required String apiKey,
    bool thinkingEnabled = false,
    CancelToken? cancelToken,
  }) async* {
    if (supabaseFunctionsBaseUrl.trim().isEmpty) {
      throw StateError('App was built without SUPABASE_FUNCTIONS_URL. Rebuild with the correct --dart-define.');
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw StateError('No authenticated Firebase user — cannot call ai-router.');
    }

    final localClient = HttpClient();
    var cancelledLocally = false;
    cancelToken?.onCancel(() {
      cancelledLocally = true;
      localClient.close(force: true);
    });

    try {
      final idToken = await firebaseUser.getIdToken();
      final uri = Uri.parse('$supabaseFunctionsBaseUrl/ai-router');

      final request = await localClient.postUrl(uri);
      request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      request.headers.set('Authorization', 'Bearer $idToken');

      final bodyBytes = utf8.encode(jsonEncode({
        'action': 'complete',
        'provider': provider,
        'model': model,
        'messages': messages,
        'apiKey': apiKey,
        'thinkingEnabled': thinkingEnabled,
      }));
      request.add(bodyBytes);

      final response = await request.close();

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        throw HttpException('ai-router error (${response.statusCode}): $errorBody');
      }

      var buffer = '';
      await for (final chunk in response.transform(utf8.decoder)) {
        if (cancelToken?.isCancelled == true) return;

        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (cancelToken?.isCancelled == true) return;

          final trimmed = line.trim();
          if (trimmed.isEmpty || !trimmed.startsWith('data: ')) continue;
          final payload = trimmed.substring(6).trim();
          if (payload == '[DONE]') return;

          try {
            final decoded = jsonDecode(payload) as Map<String, dynamic>;
            if (decoded['error'] != null) {
              throw HttpException(decoded['error'] as String);
            }
            final thinkingDelta = decoded['thinking'] as String?;
            if (thinkingDelta != null && thinkingDelta.isNotEmpty) {
              yield AiStreamEvent(type: AiStreamEventType.thinking, text: thinkingDelta);
              continue;
            }
            final delta = decoded['delta'] as String?;
            if (delta != null && delta.isNotEmpty) {
              yield AiStreamEvent(type: AiStreamEventType.content, text: delta);
            }
          } catch (e) {
            if (e is HttpException) rethrow;
            continue;
          }
        }
      }
    } catch (e) {
      if (cancelledLocally || cancelToken?.isCancelled == true) return;
      rethrow;
    } finally {
      localClient.close(force: true);
    }
  }

  /// Asks ai-router which models THIS key can actually use, ranked
  /// best-first. Used right after a user connects a key, so the app can
  /// auto-select a working model without the user typing anything.
  /// Throws on failure — caller should catch and fall back gracefully
  /// (e.g. leave the model override unset, which falls back to
  /// AiModels.defaultFor).
  Future<List<String>> listModels({
    required String provider,
    required String apiKey,
  }) async {
    if (supabaseFunctionsBaseUrl.trim().isEmpty) {
      throw StateError('App was built without SUPABASE_FUNCTIONS_URL. Rebuild with the correct --dart-define.');
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw StateError('No authenticated Firebase user — cannot call ai-router.');
    }

    final idToken = await firebaseUser.getIdToken();
    final uri = Uri.parse('$supabaseFunctionsBaseUrl/ai-router');

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      request.headers.set('Authorization', 'Bearer $idToken');
      request.add(utf8.encode(jsonEncode({
        'action': 'listModels',
        'provider': provider,
        'apiKey': apiKey,
      })));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        throw HttpException(decoded['error'] as String? ?? 'listModels failed (${response.statusCode})');
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final models = (decoded['models'] as List?)?.cast<String>() ?? const <String>[];
      return models;
    } finally {
      client.close(force: true);
    }
  }

  void dispose() {}
}
