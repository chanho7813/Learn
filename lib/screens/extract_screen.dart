import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/claude_service.dart';
import '../services/storage_service.dart';
import '../widgets/math_tex.dart';

class ExtractScreen extends StatefulWidget {
  const ExtractScreen({super.key});

  @override
  State<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends State<ExtractScreen> {
  ExtractionType _type = ExtractionType.math;
  final _titleController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  bool _extracting = false;
  String? _result;
  String? _error;
  double _progress = 0;
  AiProvider _provider = AiProvider.groq;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final p = await ClaudeService.getActiveProvider();
    if (mounted) setState(() => _provider = p);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  static const _supportedExts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  String _mimeTypeFromExt(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;

    final supported = result.files.where((f) {
      if (f.bytes == null || f.bytes!.isEmpty) return false;
      final ext = (f.extension ?? f.name.split('.').last).toLowerCase();
      return _supportedExts.contains(ext);
    }).toList();

    if (supported.isEmpty) {
      setState(() => _error = '지원되는 파일이 없습니다. (PNG, JPG)\nPDF/HWP는 이미지로 변환 후 업로드해주세요.');
      return;
    }

    setState(() {
      _selectedFiles = supported;
      _error = null;
      _result = null;
    });
  }

  String _filesSummary() {
    return '이미지 ${_selectedFiles.length}장 선택됨';
  }

  Future<void> _startExtraction() async {
    if (_selectedFiles.isEmpty) {
      setState(() => _error = '파일을 선택해주세요.');
      return;
    }

    final title = _titleController.text.trim();

    setState(() {
      _extracting = true;
      _error = null;
      _result = null;
      _progress = 0.1;
    });

    try {
      setState(() => _progress = 0.3);

      final attachments = <FileAttachment>[];
      for (final pf in _selectedFiles) {
        final ext = (pf.extension ?? pf.name.split('.').last).toLowerCase();
        attachments.add(FileAttachment(
          base64Data: base64Encode(pf.bytes!),
          mimeType: _mimeTypeFromExt(ext),
        ));
      }

      setState(() => _progress = 0.5);

      final result = await ClaudeService.extract(
        files: attachments,
        type: _type,
        examTitle: title,
      );

      setState(() {
        _progress = 1.0;
        _result = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('추출 완료!')),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'API_KEY_MISSING') {
        setState(() => _error = '설정에서 ${_provider.label} API 키를 입력해주세요.');
      } else {
        setState(() => _error = msg);
      }
    } finally {
      setState(() => _extracting = false);
    }
  }

  void _copyResult() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('클립보드에 복사되었습니다')),
    );
  }

  Widget _buildResultPreview(ThemeData theme, ColorScheme colorScheme) {
    final lines = _result!.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      if (trimmed == '---') {
        widgets.add(Divider(
          color: colorScheme.outlineVariant.withAlpha(77),
          height: 16,
        ));
        continue;
      }

      if (trimmed.startsWith('title:') || trimmed.startsWith('fileName:')) {
        widgets.add(Text(
          trimmed,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withAlpha(128),
            fontStyle: FontStyle.italic,
          ),
        ));
        continue;
      }

      if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            trimmed.substring(3),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ));
        continue;
      }

      if (RegExp(r'^\[.+\]$').hasMatch(trimmed)) {
        final tag = trimmed.substring(1, trimmed.length - 1);
        final tagColor = switch (tag) {
          '문제' => colorScheme.primary,
          '보기' => colorScheme.secondary,
          '풀이' => Colors.orange,
          '개념' => colorScheme.tertiary,
          '정답' => Colors.green,
          _ => colorScheme.onSurface.withAlpha(153),
        };
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tagColor,
              ),
            ),
          ),
        ));
        continue;
      }

      widgets.add(MathTex(
        text: trimmed,
        fontSize: 13,
        color: colorScheme.onSurface.withAlpha(204),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _ensureFileName(String content) {
    if (content.contains(RegExp(r'fileName\s*:'))) return content;
    final typeName = _type == ExtractionType.math ? 'math' : 'reading';
    final fallback = '${typeName}_${DateTime.now().millisecondsSinceEpoch}';
    final titleMatch = RegExp(r'title:[^\n]*').firstMatch(content);
    if (titleMatch != null) {
      final pos = titleMatch.end;
      return '${content.substring(0, pos)}\nfileName: $fallback${content.substring(pos)}';
    }
    return content;
  }

  Future<void> _saveToCategory() async {
    if (_result == null) return;
    final content = _ensureFileName(_result!);
    try {
      if (_type == ExtractionType.math) {
        await StorageService.addCustomMathExam(content);
      } else {
        await StorageService.addCustomReadingExam(content);
      }
      if (mounted) {
        final label = _type == ExtractionType.math ? '수학' : '리딩';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 카테고리에 저장되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('시험지 추출'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '시험지에서 문제를 추출합니다',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 24),

          Text('추출 유형', style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          SegmentedButton<ExtractionType>(
            segments: const [
              ButtonSegment(
                value: ExtractionType.math,
                label: Text('수학'),
                icon: Icon(Icons.calculate_outlined),
              ),
              ButtonSegment(
                value: ExtractionType.reading,
                label: Text('영어'),
                icon: Icon(Icons.auto_stories_outlined),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '시험 제목 (선택)',
              hintText: '비워두면 AI가 자동 감지',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(51),
            ),
          ),
          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: _extracting ? null : _pickFiles,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(_selectedFiles.isEmpty
                ? '시험지 이미지 선택 (PNG, JPG)'
                : _filesSummary()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFiles.map((f) {
                final name = f.name;
                return Chip(
                  avatar: Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    name.length > 20 ? '${name.substring(0, 17)}...' : name,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_provider.label} · ${_provider.description}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '설정에서 AI 프로바이더 변경 가능 · 이미지만 지원',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(102),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _extracting ? null : _startExtraction,
            icon: _extracting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_extracting ? '추출 중...' : '추출 시작'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          if (_extracting) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 4),
            Text(
              _progressMessage(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(128),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(77),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '추출 완료',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _copyResult,
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: '복사',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: SingleChildScrollView(
                      child: _buildResultPreview(theme, colorScheme),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyResult,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('전체 복사'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveToCategory,
                          icon: Icon(
                            _type == ExtractionType.math
                                ? Icons.calculate_outlined
                                : Icons.auto_stories_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _type == ExtractionType.math ? '수학에 저장' : '리딩에 저장',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _progressMessage() {
    if (_progress < 0.3) return '파일 준비 중...';
    if (_progress < 0.5) return '파일 인코딩 중...';
    if (_progress < 0.9) return 'AI 분석 중... (30초~2분 소요)';
    return '완료!';
  }
}
