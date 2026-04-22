import 'package:flutter/material.dart';
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
  bool _darkMode = false;
  double _fontSize = 16.0;
  bool _showNuance = true;
  bool _showEtymology = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _darkMode = await SettingsService.getDarkMode();
    _fontSize = await SettingsService.getFontSize();
    _showNuance = await SettingsService.getShowNuance();
    _showEtymology = await SettingsService.getShowEtymology();
    setState(() => _loading = false);
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
            title: const Text('뉘앙스 비교'),
            subtitle: const Text('유의어 뉘앙스 차이 표시'),
            secondary: const Icon(Icons.palette_outlined),
            value: _showNuance,
            onChanged: (v) async {
              await SettingsService.setShowNuance(v);
              setState(() => _showNuance = v);
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
          const Divider(),
          _SectionHeader(title: '데이터'),
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text('모든 단어 삭제',
                style: TextStyle(color: theme.colorScheme.error)),
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
                      child: Text('삭제',
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              await StorageService.clearAll();
              widget.onDataCleared();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 단어가 삭제되었습니다.')),
                );
              }
            },
          ),
          const Divider(),
          _SectionHeader(title: '정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('WordUp'),
            subtitle: Text('버전 1.0.0 · 편입영어 단어 암기 앱'),
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
