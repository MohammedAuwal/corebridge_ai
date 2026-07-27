
//lib/core/network/api_client.dart
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

    // A fresh client per call — lets us force-close just this request on
    // cancel, without tearing down anything else in flight.
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
      // Cancellation force-closes the client, which surfaces as a
      // socket/HTTP exception here — swallow it cleanly instead of
      // propagating a scary error for what the user asked for.
      if (cancelledLocally || cancelToken?.isCancelled == true) return;
      rethrow;
    } finally {
      localClient.close(force: true);
    }
  }

  /// No longer needed — each streamCompletion call owns and closes its
  /// own HttpClient now, so there's nothing to dispose here. Kept as a
  /// no-op so any existing call site to aiRouterClient.dispose() still
  /// compiles.
  void dispose() {}
}
