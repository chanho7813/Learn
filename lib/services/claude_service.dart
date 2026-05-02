import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

enum ExtractionType { math, reading }

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
        : _readingPrompt(examTitle);

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

  static String _readingPrompt(String examTitle) => '''
당신은 편입영어 시험 지문 추출 전문가입니다.

첨부된 시험지에서 모든 영어 지문과 문제를 추출하여 아래 형식으로 출력하세요.

## 규칙
- 지문 원문을 정확하게 옮기세요 (오탈자 수정하지 말 것)
- 각 문장을 영어 한 줄, 바로 다음 줄에 한국어 해석 한 줄로 쌍을 이루게 하세요
- 밑줄(_____)이나 빈칸은 그대로 유지
- 문제 번호를 섹션 제목으로 사용하세요
${examTitle.isEmpty ? '- title: 시험지에서 학교명, 연도, 과목 등을 파악하여 적절한 제목을 작성하세요 (예: 명지대 2025 편입영어)\n' : ''}- fileName: title을 영문 스네이크케이스로 변환하세요 (예: 명지대 2025 편입영어 → myongji_2025_english)

## 출력 형식
---
title: ${examTitle.isEmpty ? '(시험지에서 자동 감지하여 작성)' : examTitle}
fileName: (title 기반 영문 스네이크케이스)
---

## 1번

The English sentence from the passage.
지문의 영어 문장에 대한 한국어 해석.

Another English sentence continues here.
또 다른 영어 문장의 한국어 해석이 여기에 이어집니다.

## 2번

Next passage's first sentence.
다음 지문의 첫 번째 문장.

...

모든 지문의 모든 문장을 빠짐없이 추출하고, 각 문장마다 자연스러운 한국어 해석을 붙이세요.''';
}
