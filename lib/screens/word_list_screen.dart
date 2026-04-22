import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/storage_service.dart';
import 'word_detail_screen.dart';

class WordListScreen extends StatefulWidget {
  final List<Word> words;
  const WordListScreen({super.key, required this.words});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  late List<Word> _words;
  String _search = '';
  _SortMode _sortMode = _SortMode.number;

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.words);
  }

  List<Word> get _filtered {
    var list = _words.where((w) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return w.word.toLowerCase().contains(q) ||
          w.meaning.toLowerCase().contains(q) ||
          w.briefMeaning.toLowerCase().contains(q);
    }).toList();

    switch (_sortMode) {
      case _SortMode.number:
        list.sort((a, b) => a.number.compareTo(b.number));
      case _SortMode.alpha:
        list.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    }
    return list;
  }

  Future<void> _deleteWord(Word word) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('단어 삭제'),
        content: Text('"${word.word}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirm != true) return;

    await StorageService.deleteWord(word.word);
    setState(() => _words.removeWhere((w) => w.word == word.word));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text('단어 목록 (${_words.length})'),
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: _SortMode.number,
                checked: _sortMode == _SortMode.number,
                child: const Text('번호순'),
              ),
              CheckedPopupMenuItem(
                value: _SortMode.alpha,
                checked: _sortMode == _SortMode.alpha,
                child: const Text('알파벳순'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: '단어 또는 뜻 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _search.isEmpty ? '저장된 단어가 없습니다' : '검색 결과가 없습니다',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final word = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              '${word.number}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            word.word,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            word.briefMeaning,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withAlpha(153),
                              fontSize: 13,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 20,
                                color: theme.colorScheme.error.withAlpha(179)),
                            onPressed: () => _deleteWord(word),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WordDetailScreen(word: word),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

enum _SortMode { number, alpha }
