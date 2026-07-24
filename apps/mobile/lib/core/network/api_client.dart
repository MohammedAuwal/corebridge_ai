import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin client around the `ai-router` Supabase Edge Function.
/// BYOK model: the caller must supply the user's own provider API key —
/// it is sent per request and never stored server-side.
class AiRouterClient {
  final String supabaseFunctionsBaseUrl;
  final HttpClient _httpClient = HttpClient();

  AiRouterClient(this.supabaseFunctionsBaseUrl);

  Stream<String> streamCompletion({
    required String provider,
    required String model,
    required List<Map<String, String>> messages,
    required String apiKey,
  }) async* {
    if (apiKey.trim().isEmpty) {
      throw StateError('No API key set for $provider. Add one in Settings.');
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw StateError('No authenticated Firebase user — cannot call ai-router.');
    }

    final idToken = await firebaseUser.getIdToken();
    final uri = Uri.parse('$supabaseFunctionsBaseUrl/ai-router');

    final request = await _httpClient.postUrl(uri);
    request.headers.set('Authorization', 'Bearer $idToken');
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'provider': provider,
      'model': model,
      'messages': messages,
      'apiKey': apiKey,
    }));

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
          final delta = decoded['delta'] as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        } catch (e) {
          if (e is HttpException) rethrow;
          continue;
        }
      }
    }
  }

  void dispose() => _httpClient.close(force: true);
}
