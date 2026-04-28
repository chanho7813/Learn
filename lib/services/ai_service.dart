import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';

class AiService {
  static const _apiKey = '';
  static const _model = 'llama-3.3-70b-versatile';
  static const _maxRetries = 3;

  static Future<Word> analyzeWord({
    required String word,
    required String sentence,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final prompt = '''
편입영어 단어 분석. 아래 예시와 동일한 길이·톤으로 JSON만 반환하라.

[예시 — disintegrating]
{
  "word": "disintegrating",
  "pronunciation": "dɪsˈɪntɪɡreɪtɪŋ",
  "briefMeaning": "분해되는, 붕괴되는",
  "meaning": "가장 완전하고 철저한 분해. 물리적·사회적·심리적 맥락 모두에 사용",
  "exampleEn": "The old building was slowly disintegrating.",
  "exampleKo": "오래된 건물이 서서히 붕괴되고 있었다.",
  "nuances": [
    {"word": "disintegrating", "description": "가장 완전하고 철저한 분해. 물리적·사회적·심리적 맥락 모두에 사용", "etymology": "dis-(분리) + integer(온전한) + -ing"},
    {"word": "crumbling", "description": "딱딱한 것이 부스러지는 이미지. 벽·돌 등에 주로 사용", "etymology": "cruma(빵 부스러기, 고대 영어)"},
    {"word": "decaying", "description": "생물학적·화학적 부패 과정에 초점", "etymology": "de-(아래로) + cadere(떨어지다, 라틴어)"},
    {"word": "dissolving", "description": "액체에 녹아 사라지거나, 조직·관계 해산에 사용", "etymology": "dis-(분리) + solvere(풀다, 라틴어)"},
    {"word": "collapsing", "description": "구조물이 갑자기 무너지는 급격한 느낌", "etymology": "com-(함께) + labi(미끄러지다, 라틴어)"}
  ],
  "etymology": "dis-(분리) + integer(온전한, 라틴어) + -ate + -ing",
  "etymologyExplain": "완전한 상태에서 분리되어 가는 것",
  "relatedWords": "integrity(진실성), integer(정수), integral(필수적인), integrate(통합하다)"
}

[규칙]
- meaning: 한 줄, 핵심만
- nuances: 유사어 3~5개, 각 description 한 줄, etymology는 접두사+어근 분해
- etymology/etymologyExplain: 각각 한 줄
- relatedWords: 관련어(뜻) 쉼표 구분
- JSON만 출력. 마크다운·설명 금지

[과제]
문장: "$sentence"
단어: "$word"''';

    final requestBody = json.encode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.3,
      'max_tokens': 1024,
    });

    http.Response response;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
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
    var text = body['choices'][0]['message']['content'] as String;

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
