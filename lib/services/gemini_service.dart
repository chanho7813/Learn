import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';

class GeminiService {
  static const _apiKey = 'AIzaSyBK65CPpKu2DipdANp8xQr_JcnaMhPF0yg';
  static const _model = 'gemini-2.0-flash';
  static const _maxRetries = 3;

  static Future<Word> analyzeWord({
    required String word,
    required String sentence,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = '''
You are an English vocabulary tutor for a Korean student preparing for 편입영어 (college transfer exams).

The student is reading this sentence:
"$sentence"

They selected the word: "$word"

Respond with ONLY a JSON object (no markdown, no code fences). Fill every field:
{
  "word": "$word",
  "pronunciation": "IPA 발음기호 (e.g. /ɪˈnɔːrməs/)",
  "briefMeaning": "한 줄 간단한 뜻 (한국어)",
  "meaning": "이 문장에서의 구체적 의미와 일반적 뜻을 함께 설명 (한국어, 2-3문장)",
  "exampleEn": "이 단어를 사용한 다른 예문 (영어)",
  "exampleKo": "위 예문의 한국어 해석",
  "nuances": [
    {"word": "$word", "description": "이 단어의 핵심 뉘앙스 (한국어)", "etymology": ""},
    {"word": "유사어1", "description": "이 단어와의 뉘앙스 차이 (한국어)", "etymology": ""},
    {"word": "유사어2", "description": "이 단어와의 뉘앙스 차이 (한국어)", "etymology": ""}
  ],
  "etymology": "어원 분석 (라틴어/그리스어 등 원형 포함)",
  "etymologyExplain": "어원을 활용한 암기 팁 (한국어)",
  "relatedWords": "관련 파생어, 반의어 등 (쉼표 구분)"
}''';

    final requestBody = json.encode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
      },
    });

    http.Response response;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      }

      if (response.statusCode == 429) {
        if (attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        throw Exception('요청이 너무 잦습니다. 잠시 후 다시 시도해주세요.');
      }

      throw Exception('API 오류 (${response.statusCode})');
    }

    throw Exception('요청 실패. 잠시 후 다시 시도해주세요.');
  }

  static Word _parseResponse(String responseBody) {
    final body = json.decode(responseBody);
    var text = body['candidates'][0]['content']['parts'][0]['text'] as String;

    text = text.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```\w*\n?'), '');
      text = text.replaceFirst(RegExp(r'\n?```$'), '');
      text = text.trim();
    }

    final wordJson = json.decode(text) as Map<String, dynamic>;
    wordJson['number'] = 0;
    return Word.fromJson(wordJson);
  }
}
