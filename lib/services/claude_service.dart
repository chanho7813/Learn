import 'dart:convert';
import 'package:http/http.dart' as http;

enum ExtractionType { math, reading }

class FileAttachment {
  final String base64Data;
  final String mimeType;

  const FileAttachment({required this.base64Data, required this.mimeType});

  Map<String, dynamic> toContentBlock() {
    return {
      'type': 'image_url',
      'image_url': {
        'url': 'data:$mimeType;base64,$base64Data',
      },
    };
  }
}

class ClaudeService {
  static const _apiKey =
      '';
  static const _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _maxRetries = 3;

  static Future<String> extract({
    required List<FileAttachment> files,
    required ExtractionType type,
    required String examTitle,
  }) async {
    final prompt = type == ExtractionType.math
        ? _mathPrompt(examTitle)
        : _readingPrompt(examTitle);

    final contentBlocks = <Map<String, dynamic>>[];
    for (final f in files) {
      contentBlocks.add(f.toContentBlock());
    }
    contentBlocks.add({
      'type': 'text',
      'text': prompt,
    });

    final requestBody = json.encode({
      'model': _visionModel,
      'messages': [
        {
          'role': 'user',
          'content': contentBlocks,
        },
      ],
      'temperature': 0.3,
      'max_tokens': 8192,
    });

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final text =
            body['choices'][0]['message']['content'] as String;
        return text.trim();
      }

      if (response.statusCode == 429) {
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        throw Exception('요청이 너무 잦습니다. 잠시 후 다시 시도해주세요.');
      }

      if (response.statusCode == 401) {
        throw Exception('API 키가 유효하지 않습니다.');
      }

      final errorBody = json.decode(response.body);
      final errorMsg = errorBody['error']?['message'] ?? '알 수 없는 오류';
      throw Exception('API 오류 (${response.statusCode}): $errorMsg');
    }

    throw Exception('요청 실패. 잠시 후 다시 시도해주세요.');
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

## 출력 형식
---
title: $examTitle
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

## 출력 형식
---
title: $examTitle
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
