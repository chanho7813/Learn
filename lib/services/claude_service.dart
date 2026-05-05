import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

enum ExtractionType { math, english }

enum AiProvider {
  groq,
  gemini,
  claude,
  gpt;

  String get label {
    switch (this) {
      case AiProvider.groq:
        return 'Groq';
      case AiProvider.gemini:
        return 'Gemini';
      case AiProvider.claude:
        return 'Claude';
      case AiProvider.gpt:
        return 'GPT';
    }
  }

  String get hint {
    switch (this) {
      case AiProvider.groq:
        return 'gsk_...';
      case AiProvider.gemini:
        return 'AIza...';
      case AiProvider.claude:
        return 'sk-ant-...';
      case AiProvider.gpt:
        return 'sk-...';
    }
  }

  String get description {
    switch (this) {
      case AiProvider.groq:
        return 'console.groq.com · 무료';
      case AiProvider.gemini:
        return 'aistudio.google.com · 무료';
      case AiProvider.claude:
        return 'console.anthropic.com · 유료';
      case AiProvider.gpt:
        return 'platform.openai.com · 유료';
    }
  }
}

class FileAttachment {
  final String base64Data;
  final String mimeType;
  const FileAttachment({required this.base64Data, required this.mimeType});
}

class ClaudeService {
  static const _defaultGroqKey =
      '';
  static const _maxRetries = 3;

  static Future<AiProvider> getActiveProvider() async {
    final str = await SettingsService.getAiProvider();
    return AiProvider.values.firstWhere(
      (p) => p.name == str,
      orElse: () => AiProvider.groq,
    );
  }

  static Future<String> getApiKeyFor(AiProvider provider) async {
    switch (provider) {
      case AiProvider.groq:
        final key = await SettingsService.getGroqApiKey();
        return key.isNotEmpty ? key : _defaultGroqKey;
      case AiProvider.gemini:
        return SettingsService.getGeminiApiKey();
      case AiProvider.claude:
        return SettingsService.getClaudeApiKey();
      case AiProvider.gpt:
        return SettingsService.getGptApiKey();
    }
  }

  static Future<void> setApiKeyFor(AiProvider provider, String value) async {
    switch (provider) {
      case AiProvider.groq:
        await SettingsService.setGroqApiKey(value);
      case AiProvider.gemini:
        await SettingsService.setGeminiApiKey(value);
      case AiProvider.claude:
        await SettingsService.setClaudeApiKey(value);
      case AiProvider.gpt:
        await SettingsService.setGptApiKey(value);
    }
  }

  static Future<String> extract({
    required List<FileAttachment> files,
    required ExtractionType type,
    required String examTitle,
  }) async {
    final provider = await getActiveProvider();
    final apiKey = await getApiKeyFor(provider);

    if (apiKey.isEmpty) throw Exception('API_KEY_MISSING');

    final prompt = type == ExtractionType.math
        ? _mathPrompt(examTitle)
        : _englishPrompt(examTitle);

    if (provider == AiProvider.claude) {
      return _callClaude(files, prompt, apiKey);
    }
    return _callOpenAiCompat(files, prompt, apiKey, provider);
  }

  static Future<String> _callOpenAiCompat(
    List<FileAttachment> files,
    String prompt,
    String apiKey,
    AiProvider provider,
  ) async {
    final (baseUrl, model) = _openAiConfig(provider);

    final content = <Map<String, dynamic>>[];
    for (final f in files) {
      content.add({
        'type': 'image_url',
        'image_url': {'url': 'data:${f.mimeType};base64,${f.base64Data}'},
      });
    }
    content.add({'type': 'text', 'text': prompt});

    final body = json.encode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': content}
      ],
      'temperature': 0.3,
      'max_tokens': 8192,
    });

    return _post(
      url: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
      extractText: (data) =>
          (data['choices'][0]['message']['content'] as String).trim(),
    );
  }

  static Future<String> _callClaude(
    List<FileAttachment> files,
    String prompt,
    String apiKey,
  ) async {
    final content = <Map<String, dynamic>>[];
    for (final f in files) {
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': f.mimeType,
          'data': f.base64Data,
        },
      });
    }
    content.add({'type': 'text', 'text': prompt});

    final body = json.encode({
      'model': 'claude-sonnet-4-20250514',
      'max_tokens': 8192,
      'messages': [
        {'role': 'user', 'content': content}
      ],
    });

    return _post(
      url: 'https://api.anthropic.com/v1/messages',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
      extractText: (data) {
        final blocks = data['content'] as List;
        return (blocks.firstWhere(
                (b) => b['type'] == 'text')['text'] as String)
            .trim();
      },
    );
  }

  static Future<String> _post({
    required String url,
    required Map<String, String> headers,
    required String body,
    required String Function(Map<String, dynamic>) extractText,
  }) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return extractText(json.decode(response.body));
      }

      if (response.statusCode == 429 && attempt < _maxRetries) {
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        continue;
      }

      if (response.statusCode == 401) {
        throw Exception('API 키가 유효하지 않습니다.');
      }

      final errBody = json.decode(response.body);
      final errMsg = errBody['error']?['message'] ?? '알 수 없는 오류';
      throw Exception('API 오류 (${response.statusCode}): $errMsg');
    }
    throw Exception('요청 실패. 잠시 후 다시 시도해주세요.');
  }

  static (String baseUrl, String model) _openAiConfig(AiProvider provider) {
    switch (provider) {
      case AiProvider.groq:
        return (
          'https://api.groq.com/openai/v1/chat/completions',
          'meta-llama/llama-4-scout-17b-16e-instruct'
        );
      case AiProvider.gemini:
        return (
          'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
          'gemini-2.0-flash'
        );
      case AiProvider.gpt:
        return (
          'https://api.openai.com/v1/chat/completions',
          'gpt-4o'
        );
      default:
        throw StateError('Not an OpenAI-compatible provider');
    }
  }

  static String _mathPrompt(String examTitle) => '''
당신은 편입수학 시험 문제 분석 전문가입니다.

첨부된 시험지에서 모든 문제를 추출하고, 각 문제를 풀어서 아래 형식으로 출력하세요.

## 규칙
- 수식은 반드시 LaTeX로 표기하고 \$ 기호로 감싸세요 (예: \$\\frac{1}{3}\$, \$\\int_0^1 x^2 dx\$)
- 일반 텍스트와 수식을 자연스럽게 섞어 쓰세요
- 풀이는 단계별로 작성하되 핵심만 간결하게
- 개념은 해당 문제를 풀기 위해 반드시 알아야 할 수학 개념만
- 정답은 번호(①②③④⑤) 또는 값으로
${examTitle.isEmpty ? '- title: 시험지에서 학교명, 연도, 과목 등을 파악하여 적절한 제목을 작성하세요 (예: 명지대 2024 편입수학)\n' : ''}- fileName: title을 영문 스네이크케이스로 변환하세요 (예: 명지대 2024 편입수학 → myongji_2024_math)

## 출력 형식
---
title: ${examTitle.isEmpty ? '(시험지에서 자동 감지하여 작성)' : examTitle}
fileName: (title 기반 영문 스네이크케이스)
---

## 1번 [배점]

[문제]
문제 내용 (수식은 \$...\$로)

[보기]
① 보기1  ② 보기2  ③ 보기3  ④ 보기4  ⑤ 보기5

[풀이]
풀이 과정

[개념]
핵심 개념 설명

[정답]
정답

## 2번 [배점]
...

모든 문제를 빠짐없이 추출하고 풀이하세요. 보기가 없는 문제는 [보기] 섹션을 생략하세요.''';

  static String _englishPrompt(String examTitle) => '''
당신은 편입영어 시험 문제 추출 전문가입니다.

첨부된 시험지에서 모든 영어 문제를 추출하여 아래 형식으로 출력하세요.

## [지문] 규칙 — 가장 중요
- [지문]에 해당 문제의 영어 지문 전체를 빠짐없이 넣으세요. 한 문장도 빠뜨리면 안 됩니다.
- 반드시 한 문장(마침표/물음표/느낌표로 끝나는 단위)씩 줄바꿈하세요.
- 절대로 두 문장 이상을 한 줄에 쓰지 마세요.
- 영어 문장 바로 다음 줄에 한국어 해석을 쓰세요.
- 빈칸(_____)이 있는 문장도 지문에 포함하되, 빈칸은 그대로 유지하세요.

## [문제] 규칙
- 문제 번호와 지시문(질문)만 쓰세요. 예: "다음 빈칸에 들어갈 가장 적절한 것은?"
- 지문 내용을 [문제]에 다시 복사하지 마세요. 지문은 이미 [지문]에 있습니다.
- 한국어 해석 없이 원문만 적으세요.

## [보기] 규칙
- 각 보기 바로 다음 줄에 한국어 해석을 반드시 쓰세요. 예외 없음.
- 보기가 단어 하나여도 한국어 뜻을 반드시 쓰세요.

## 기타 규칙
- [정답]: 정답 번호만 간결하게 (예: ③)
- [풀이]: 왜 그 답이 정답인지 한국어로 상세히 설명
- [핵심 개념]: 해당 문제의 문법·어휘·독해 핵심 포인트 정리
- 지문 원문을 정확하게 옮기세요 (오탈자 수정하지 말 것)
- 문제 번호를 ## 섹션 제목으로 사용하세요
- 지문이 없는 문제(어휘, 문법 등)는 [지문] 없이 [문제]부터 시작
${examTitle.isEmpty ? '- title: 시험지에서 학교명, 연도, 과목 등을 파악하여 적절한 제목 작성 (예: 명지대 2025 편입영어)\n' : ''}- fileName: title을 영문 스네이크케이스로 변환 (예: 명지대 2025 편입영어 → myongji_2025_english)

## 출력 형식
---
title: ${examTitle.isEmpty ? '(시험지에서 자동 감지하여 작성)' : examTitle}
fileName: (title 기반 영문 스네이크케이스)
---

## 21번

[지문]
The government of Madagascar has recently designated portions of the territory and the surrounding islands as protected reserves for wildlife.
마다가스카르 정부는 최근 영토의 일부와 주변 섬들을 야생동물 보호구역으로 지정했다.

Madagascar is such an island.
마다가스카르는 그런 섬 중 하나이다.

The aye-aye is initially categorized as a member of the order Rodentia.
아이아이는 처음에 설치류 목의 일원으로 분류되었다.

The aye-aye is more _____ than its fellow primates.
아이아이는 다른 영장류보다 더 _____하다.

Since the aye-aye is so different from its fellow _____, it is on the brink of extinction.
아이아이는 같은 _____들과 너무 달라서 멸종 위기에 처해 있다.

[문제]
Choose the most appropriate pair of words for the blanks.

[보기]
① large - red
① 큰 - 빨간

② long - extant
② 긴 - 현존하는

③ adaptations - prototypes
③ 적응 - 원형

④ sympatry - nonsympatry
④ 공서 - 비공서

[정답]
③

[풀이]
지문에서 aye-aye가 다른 영장류보다 더 많은 적응(adaptations)을 가지고 있다고 설명하고 있다. 또한 같은 원형(prototypes)들과 다르다는 내용이 이어지므로 ③이 정답이다.

[핵심 개념]
adaptation: 적응, 순응 (생물학적 맥락에서 환경에 맞게 변화하는 것)
prototype: 원형, 시제품 (같은 분류 내의 기본 형태)
on the brink of extinction: 멸종 위기에 처한
Rodentia: 설치류 목

## 22번

...

모든 문제를 빠짐없이 추출하세요.''';
}
