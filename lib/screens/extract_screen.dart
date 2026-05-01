import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/claude_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';

class ExtractScreen extends StatefulWidget {
  const ExtractScreen({super.key});

  @override
  State<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends State<ExtractScreen> {
  ExtractionType _type = ExtractionType.math;
  final _titleController = TextEditingController();
  final _fileNameController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  bool _extracting = false;
  String? _result;
  String? _error;
  double _progress = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _fileNameController.dispose();
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
    if (title.isEmpty) {
      setState(() => _error = '시험 제목을 입력해주세요.');
      return;
    }

    final apiKey = await SettingsService.getClaudeApiKey();
    if (apiKey.isEmpty) {
      if (!mounted) return;
      _showApiKeyDialog();
      return;
    }

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
        if (mounted) _showApiKeyDialog();
      } else {
        setState(() => _error = msg);
      }
    } finally {
      setState(() => _extracting = false);
    }
  }

  Future<void> _saveResult() async {
    if (_result == null) return;
    final fileName = _fileNameController.text.trim();
    final safeName = fileName.isEmpty
        ? 'extract_result'
        : fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');

    final savePath = await FilePicker.pickFiles(
      dialogTitle: '저장할 위치 선택',
      type: FileType.any,
    );

    // fallback: copy to clipboard
    await Clipboard.setData(ClipboardData(text: _result!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(savePath != null
              ? '저장 완료!'
              : '클립보드에 복사되었습니다. ($safeName.txt)'),
        ),
      );
    }
  }

  void _copyResult() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('클립보드에 복사되었습니다')),
    );
  }

  Future<void> _saveToCategory() async {
    if (_result == null) return;
    try {
      if (_type == ExtractionType.math) {
        await StorageService.addCustomMathExam(_result!);
      } else {
        await StorageService.addCustomReadingExam(_result!);
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

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Claude API 키 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'console.anthropic.com에서\nAPI 키를 발급받아 입력하세요.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-ant-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await SettingsService.setClaudeApiKey(key);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
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
              labelText: '시험 제목',
              hintText: '예: 명지대 2024 편입수학',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(51),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _fileNameController,
            decoration: InputDecoration(
              labelText: '저장 파일명 (선택)',
              hintText: '예: myongji_2024_math',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.save_outlined),
              suffixText: '.txt',
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
                  'Groq 무료 API · 이미지만 지원',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF/HWP는 캡처 또는 이미지로 변환 후 업로드',
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
                  const SizedBox(height: 8),
                  Text(
                    '아래 내용을 복사하여 assets 폴더에 .txt 파일로 저장하세요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _result!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
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
