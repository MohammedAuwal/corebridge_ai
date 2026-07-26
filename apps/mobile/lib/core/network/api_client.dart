import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/ai_stream_event.dart';

class AiRouterClient {
  final String supabaseFunctionsBaseUrl;
  final HttpClient _httpClient = HttpClient();

  AiRouterClient(this.supabaseFunctionsBaseUrl);

  Stream<AiStreamEvent> streamCompletion({
    required String provider,
    required String model,
    required List<Map<String, String>> messages,
    required String apiKey,
    bool thinkingEnabled = false,
  }) async* {
    if (supabaseFunctionsBaseUrl.trim().isEmpty) {
      throw StateError('App was built without SUPABASE_FUNCTIONS_URL. Rebuild with the correct --dart-define.');
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw StateError('No authenticated Firebase user — cannot call ai-router.');
    }

    final idToken = await firebaseUser.getIdToken();
    final uri = Uri.parse('$supabaseFunctionsBaseUrl/ai-router');

    final request = await _httpClient.postUrl(uri);
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
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
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
  }

  void dispose() => _httpClient.close(force: true);
}
