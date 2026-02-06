import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class OpenAiTranscriptionService {
  const OpenAiTranscriptionService({this.endpoint = 'https://api.openai.com/v1/audio/transcriptions'});

  final String endpoint;

  Future<String> transcribe({
    required String apiKey,
    required String localPath,
    required String model,
    String? prompt,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found for transcription.');
    }

    final request = http.MultipartRequest('POST', Uri.parse(endpoint))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = model
      ..fields['response_format'] = 'json'
      ..fields['language'] = 'ar'
      ..fields.addAll(
        (prompt != null && prompt.trim().isNotEmpty)
            ? <String, String>{
                // Improves transcription stability for short recitations by providing context.
                'prompt': prompt.trim(),
              }
            : const <String, String>{},
      )
      ..files.add(await http.MultipartFile.fromPath('file', localPath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('OpenAI transcription failed: ${streamed.statusCode} ${body.isNotEmpty ? body : ''}');
    }

    final jsonBody = json.decode(body) as Map<String, dynamic>;
    final text = jsonBody['text'] as String?;
    if (text == null) {
      throw Exception('OpenAI transcription missing text.');
    }
    return text.trim();
  }
}
