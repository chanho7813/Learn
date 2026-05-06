import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';

class AiService {
  static const _apiKey =
      '';
  static const _model = 'llama-3.3-70b-versatile';
  static const _maxRetries = 3;

  static Future<Word> analyzeWord({
    required String word,
    required String sentence,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final prompt =
        '''
편입영어 단어 분석. JSON만 반환하라.
단어마다 가장 효율적인 학습 전략을 먼저 판단하라.
어원이 현재 뜻을 잘 설명하면 어원 중심, 어원이 멀면 같은 어근/친척 단어 중심, 사용 조합이 중요하면 연어 중심, 둘 다 약하면 예문 중심으로 처리하라.

[예시 — obdurate]
{
  "word": "obdurate",
  "pronunciation": "ˈɑːbdərət",
  "briefMeaning": "완고한, 고집 센",
  "meaning": "설득이나 압력에도 태도를 바꾸지 않는 완고함",
  "learningFocus": "어원 중심",
  "studyGuide": "durus(단단한)가 현재 뜻과 직접 이어지므로 '압력 앞에서 마음이 딱딱하게 굳은 상태' 이미지로 외우면 된다.",
  "exampleEn": "He remained obdurate despite repeated appeals.",
  "exampleKo": "그는 거듭된 호소에도 완고한 태도를 유지했다.",
  "nuances": [
    {"word": "obdurate", "description": "압박에도 마음이 딱딱하게 굳어 바뀌지 않는 느낌", "etymology": "ob-(맞서) + durus(단단한)"},
    {"word": "intransigent", "description": "협상이나 양보를 원칙적으로 거부하는 강한 표현", "etymology": "in-(아님) + transigere(합의하다)"},
    {"word": "stubborn", "description": "일상적으로 쓰는 고집 센 태도", "etymology": "어원 불확실"},
    {"word": "adamant", "description": "결심이 아주 단단해 흔들리지 않는 느낌", "etymology": "adamas(깨지지 않는 단단한 물질)"}
  ],
  "etymology": "ob-(맞서, 앞에) + durus(단단한, 라틴어) + -ate",
  "etymologyExplain": "원뜻은 '앞에서 단단하게 굳은' 상태다. 마음이나 태도가 외부 압력 앞에서 딱딱하게 굳었다는 이미지가 되어 '완고한, 고집 센' 뜻으로 이어진다.",
  "wordFamily": "durable(내구성 있는), endure(견디다), duress(강압)",
  "collocations": ["remain obdurate - 완고한 태도를 유지하다", "an obdurate refusal - 완강한 거부", "obdurate opposition - 완강한 반대"],
  "relatedWords": "durable(내구성 있는), endure(견디다), duress(강압), adamant(단호한)"
}

[규칙]
- learningFocus: 반드시 "어원 중심", "어근 묶음 중심", "연어 중심", "예문 중심" 중 하나
- studyGuide: 왜 그 전략으로 외워야 하는지 한 줄. 억지 어원 암기를 피하라는 판단도 여기에 써라
- meaning: 한 줄, 핵심만
- nuances: 유사어 3~5개, 각 description은 의미 차이 한 줄, etymology는 가능한 경우만 짧게
- etymology: 검증 가능한 접두사·어근·접미사 분해. 불확실하거나 학습에 도움이 작으면 "어원 학습 비추천" 또는 "어원 불확실"이라고 써라
- etymologyExplain: 1~2문장. 어원이 도움될 때만 "원뜻/이미지 -> 의미 변화 -> 현재 한국어 뜻" 흐름으로 설명하라. 도움 안 되면 왜 비추천인지 말하라
- wordFamily: 실제 같은 어근·동족어·파생어만 넣어라. 단순 유의어 금지. 불확실하면 빈 문자열
- collocations: 실제로 자주 붙는 표현 3~5개. "표현 - 한국어 의미" 형식의 문자열 배열
- 원뜻과 현재 뜻이 직접 이어지지 않으면 중간 의미 변화까지 설명하라
- relatedWords: 관련어(뜻) 쉼표 구분
- JSON만 출력. 마크다운·설명 금지

[과제]
문장: "$sentence"
단어: "$word"''';

    final requestBody = json.encode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.3,
      'max_tokens': 1800,
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
