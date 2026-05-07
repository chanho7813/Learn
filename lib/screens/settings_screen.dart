import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final VoidCallback onDataCleared;
  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.onDataCleared,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _groqApiKeyController = TextEditingController();
  bool _darkMode = false;
  double _fontSize = 16.0;
  bool _showPronunciation = true;
  bool _showBriefMeaning = true;
  bool _showMeaning = true;
  bool _showEtymology = true;
  bool _showRelatedWords = true;
  bool _showExample = true;
  bool _showNuance = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _darkMode = await SettingsService.getDarkMode();
    _fontSize = await SettingsService.getFontSize();
    _showPronunciation = await SettingsService.getShowPronunciation();
    _showBriefMeaning = await SettingsService.getShowBriefMeaning();
    _showMeaning = await SettingsService.getShowMeaning();
    _showEtymology = await SettingsService.getShowEtymology();
    _showRelatedWords = await SettingsService.getShowRelatedWords();
    _showExample = await SettingsService.getShowExample();
    _showNuance = await SettingsService.getShowNuance();
    _groqApiKeyController.text = await SettingsService.getGroqApiKey();
    setState(() => _loading = false);
  }

  Future<String> _getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  @override
  void dispose() {
    _groqApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _SectionHeader(title: '화면'),
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: const Text('어두운 테마 사용'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: _darkMode,
            onChanged: (v) async {
              await SettingsService.setDarkMode(v);
              setState(() => _darkMode = v);
              widget.onThemeChanged();
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('글꼴 크기'),
            subtitle: Text('${_fontSize.toInt()}pt'),
            trailing: SizedBox(
              width: 180,
              child: Slider(
                value: _fontSize,
                min: 12,
                max: 24,
                divisions: 6,
                label: '${_fontSize.toInt()}pt',
                onChanged: (v) async {
                  await SettingsService.setFontSize(v);
                  setState(() => _fontSize = v);
                },
              ),
            ),
          ),
          const Divider(),
          _SectionHeader(title: '단어 상세 표시'),
          SwitchListTile(
            title: const Text('발음 기호'),
            subtitle: const Text('단어 발음 기호 표시'),
            secondary: const Icon(Icons.record_voice_over_outlined),
            value: _showPronunciation,
            onChanged: (v) async {
              await SettingsService.setShowPronunciation(v);
              setState(() => _showPronunciation = v);
            },
          ),
          SwitchListTile(
            title: const Text('간략 뜻'),
            subtitle: const Text('단어 옆에 간략한 뜻 표시'),
            secondary: const Icon(Icons.short_text),
            value: _showBriefMeaning,
            onChanged: (v) async {
              await SettingsService.setShowBriefMeaning(v);
              setState(() => _showBriefMeaning = v);
            },
          ),
          SwitchListTile(
            title: const Text('상세 뜻'),
            subtitle: const Text('자세한 뜻 풀이 표시'),
            secondary: const Icon(Icons.translate),
            value: _showMeaning,
            onChanged: (v) async {
              await SettingsService.setShowMeaning(v);
              setState(() => _showMeaning = v);
            },
          ),
          SwitchListTile(
            title: const Text('어원'),
            subtitle: const Text('단어 어원 정보 표시'),
            secondary: const Icon(Icons.history_edu),
            value: _showEtymology,
            onChanged: (v) async {
              await SettingsService.setShowEtymology(v);
              setState(() => _showEtymology = v);
            },
          ),
          SwitchListTile(
            title: const Text('관련어'),
            subtitle: const Text('어원 관련 단어 표시'),
            secondary: const Icon(Icons.link),
            value: _showRelatedWords,
            onChanged: (v) async {
              await SettingsService.setShowRelatedWords(v);
              setState(() => _showRelatedWords = v);
            },
          ),
          SwitchListTile(
            title: const Text('예문'),
            subtitle: const Text('영어 예문 및 한국어 해석 표시'),
            secondary: const Icon(Icons.format_quote),
            value: _showExample,
            onChanged: (v) async {
              await SettingsService.setShowExample(v);
              setState(() => _showExample = v);
            },
          ),
          SwitchListTile(
            title: const Text('뉘앙스 비교'),
            subtitle: const Text('유의어 뉘앙스 차이 표시'),
            secondary: const Icon(Icons.palette_outlined),
            value: _showNuance,
            onChanged: (v) async {
              await SettingsService.setShowNuance(v);
              setState(() => _showNuance = v);
            },
          ),
          const Divider(),
          _SectionHeader(title: 'AI'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _groqApiKeyController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key_outlined),
                labelText: 'Groq API 키',
                helperText: '단어 AI 분석에 사용됩니다',
              ),
              onChanged: SettingsService.setGroqApiKey,
            ),
          ),
          const Divider(),
          _SectionHeader(title: '데이터'),
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(
              '모든 단어 삭제',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('저장된 모든 단어를 삭제합니다'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('전체 삭제'),
                  content: const Text('저장된 모든 단어가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        '삭제',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              await StorageService.clearAll();
              if (!context.mounted) return;
              widget.onDataCleared();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('모든 단어가 삭제되었습니다.')));
            },
          ),
          const Divider(),
          _SectionHeader(title: '정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Learn'),
            subtitle: FutureBuilder<String>(
              future: _getVersion(),
              builder: (context, snapshot) {
                final version = snapshot.data ?? '';
                return Text('버전 $version · 영어 단어 암기 앱');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
