import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';

// ---------------------------------------------------------------------------
// Language registration (lazy, once per language)
// ---------------------------------------------------------------------------

final _registered = <String>{};

void _ensureLanguage(String lang) {
  if (_registered.contains(lang)) return;
  _registered.add(lang);
  switch (lang) {
    case 'dart':
      highlight.registerLanguage('dart', dart);
    case 'javascript':
      highlight.registerLanguage('javascript', javascript);
    case 'typescript':
      highlight.registerLanguage('typescript', typescript);
    case 'python':
      highlight.registerLanguage('python', python);
    case 'java':
      highlight.registerLanguage('java', java);
    case 'kotlin':
      highlight.registerLanguage('kotlin', kotlin);
    case 'swift':
      highlight.registerLanguage('swift', swift);
    case 'go':
      highlight.registerLanguage('go', go);
    case 'rust':
      highlight.registerLanguage('rust', rust);
    case 'cpp':
      highlight.registerLanguage('cpp', cpp);
    case 'css':
      highlight.registerLanguage('css', css);
    case 'xml':
      highlight.registerLanguage('xml', xml);
    case 'json':
      highlight.registerLanguage('json', json);
    case 'yaml':
      highlight.registerLanguage('yaml', yaml);
    case 'bash':
      highlight.registerLanguage('bash', bash);
    case 'sql':
      highlight.registerLanguage('sql', sql);
    case 'markdown':
      highlight.registerLanguage('markdown', markdown);
    case 'php':
      highlight.registerLanguage('php', php);
    case 'ruby':
      highlight.registerLanguage('ruby', ruby);
  }
}

String? _detectLanguage(String? ext) => switch (ext?.toLowerCase()) {
  'dart' => 'dart',
  'js' || 'jsx' || 'mjs' => 'javascript',
  'ts' || 'tsx' => 'typescript',
  'py' => 'python',
  'java' => 'java',
  'kt' => 'kotlin',
  'swift' => 'swift',
  'go' => 'go',
  'rs' => 'rust',
  'cpp' || 'cc' || 'cxx' || 'h' || 'hpp' => 'cpp',
  'css' || 'scss' || 'less' => 'css',
  'html' || 'htm' || 'xml' || 'svg' => 'xml',
  'json' => 'json',
  'yaml' || 'yml' => 'yaml',
  'sh' || 'bash' || 'zsh' => 'bash',
  'sql' => 'sql',
  'md' || 'markdown' => 'markdown',
  'php' => 'php',
  'rb' => 'ruby',
  _ => null,
};

String? _extractLanguage(String diff) {
  final match = RegExp(r'^---\s+[ab]/(.+)$', multiLine: true).firstMatch(diff);
  if (match == null) return null;
  final ext = match.group(1)!.split('.').last;
  return _detectLanguage(ext);
}

// ---------------------------------------------------------------------------
// Highlight → TextSpan conversion (mirrors flutter_highlight's _convert)
// ---------------------------------------------------------------------------

List<TextSpan> _convert(List<Node> nodes, Map<String, TextStyle> theme) {
  final spans = <TextSpan>[];
  var current = spans;
  final stack = <List<TextSpan>>[];

  void traverse(Node node) {
    if (node.value != null) {
      final style = node.className != null ? theme[node.className!] : null;
      current.add(TextSpan(text: node.value, style: style));
    } else if (node.children != null) {
      final tmp = <TextSpan>[];
      current.add(TextSpan(children: tmp, style: theme[node.className!]));
      stack.add(current);
      current = tmp;
      for (final child in node.children!) {
        traverse(child);
      }
      current = stack.removeLast();
    }
  }

  for (final node in nodes) {
    traverse(node);
  }
  return spans;
}

List<TextSpan> _highlight(
  String code,
  String? language,
  Map<String, TextStyle> theme,
) {
  if (language == null || code.trim().isEmpty) {
    return [TextSpan(text: code)];
  }
  _ensureLanguage(language);
  try {
    final result = highlight.parse(code, language: language);
    final spans = _convert(result.nodes ?? [], theme);
    return spans.isEmpty ? [TextSpan(text: code)] : spans;
  } catch (_) {
    return [TextSpan(text: code)];
  }
}

// ---------------------------------------------------------------------------
// Diff parser
// ---------------------------------------------------------------------------

class _Row {
  final String? left;
  final String? right;
  final int? leftNum;
  final int? rightNum;
  final bool leftChanged;
  final bool rightChanged;
  final String? header;

  const _Row({
    this.left,
    this.right,
    this.leftNum,
    this.rightNum,
    this.leftChanged = false,
    this.rightChanged = false,
    this.header,
  });

  bool get isHeader => header != null;
  bool get isHunk => header != null && header!.startsWith('@@');
}

List<_Row> _parseDiff(String content) {
  final rows = <_Row>[];
  final lines = content.split('\n');
  int leftNum = 0;
  int rightNum = 0;

  // Buffers for pairing removed/added lines in a changed block
  final removed = <(String, int)>[];
  final added = <(String, int)>[];

  void flush() {
    final pairs = removed.length < added.length ? removed.length : added.length;
    for (int i = 0; i < pairs; i++) {
      rows.add(
        _Row(
          left: removed[i].$1,
          right: added[i].$1,
          leftNum: removed[i].$2,
          rightNum: added[i].$2,
          leftChanged: true,
          rightChanged: true,
        ),
      );
    }
    for (int i = pairs; i < removed.length; i++) {
      rows.add(
        _Row(left: removed[i].$1, leftNum: removed[i].$2, leftChanged: true),
      );
    }
    for (int i = pairs; i < added.length; i++) {
      rows.add(
        _Row(right: added[i].$1, rightNum: added[i].$2, rightChanged: true),
      );
    }
    removed.clear();
    added.clear();
  }

  for (final line in lines) {
    if (line.startsWith('@@')) {
      flush();
      final m = RegExp(
        r'@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@',
      ).firstMatch(line);
      if (m != null) {
        leftNum = int.parse(m.group(1)!) - 1;
        rightNum = int.parse(m.group(2)!) - 1;
      }
      rows.add(_Row(header: line));
    } else if (line.startsWith('diff ') ||
        line.startsWith('index ') ||
        line.startsWith('--- ') ||
        line.startsWith('+++ ')) {
      flush();
      rows.add(_Row(header: line));
    } else if (line.startsWith('-')) {
      leftNum++;
      removed.add((line.substring(1), leftNum));
    } else if (line.startsWith('+')) {
      rightNum++;
      added.add((line.substring(1), rightNum));
    } else {
      flush();
      final code = line.startsWith(' ') ? line.substring(1) : line;
      leftNum++;
      rightNum++;
      rows.add(
        _Row(left: code, right: code, leftNum: leftNum, rightNum: rightNum),
      );
    }
  }
  flush();
  return rows;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class SideBySideDiffView extends StatelessWidget {
  final String content;
  const SideBySideDiffView({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hlTheme = isDark ? atomOneDarkTheme : githubTheme;
    final language = _extractLanguage(content);
    final rows = _parseDiff(content);

    return SelectionArea(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        itemBuilder: (context, i) => _RowWidget(
          row: rows[i],
          hlTheme: hlTheme,
          language: language,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _RowWidget extends StatelessWidget {
  final _Row row;
  final Map<String, TextStyle> hlTheme;
  final String? language;
  final bool isDark;

  const _RowWidget({
    required this.row,
    required this.hlTheme,
    required this.language,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (row.isHunk) {
      return Container(
        color: isDark ? const Color(0xFF1A1A3A) : const Color(0xFFEBF0FF),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          row.header!,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: isDark ? const Color(0xFF79C0FF) : const Color(0xFF0969DA),
          ),
        ),
      );
    }

    if (row.isHeader) {
      return Container(
        color: theme.colorScheme.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          row.header!,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Cell(
              code: row.left,
              lineNum: row.leftNum,
              changed: row.leftChanged,
              isRemoved: true,
              hlTheme: hlTheme,
              language: language,
              isDark: isDark,
            ),
          ),
          VerticalDivider(width: 1, color: theme.dividerColor),
          Expanded(
            child: _Cell(
              code: row.right,
              lineNum: row.rightNum,
              changed: row.rightChanged,
              isRemoved: false,
              hlTheme: hlTheme,
              language: language,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String? code;
  final int? lineNum;
  final bool changed;
  final bool isRemoved;
  final Map<String, TextStyle> hlTheme;
  final String? language;
  final bool isDark;

  const _Cell({
    required this.code,
    required this.lineNum,
    required this.changed,
    required this.isRemoved,
    required this.hlTheme,
    required this.language,
    required this.isDark,
  });

  Color _bg() {
    if (code == null) {
      return isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F8FA);
    }
    if (changed && isRemoved) {
      return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEB);
    }
    if (changed && !isRemoved) {
      return isDark ? const Color(0xFF1A3A1A) : const Color(0xFFE6FFED);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spans = code != null
        ? _highlight(code!, language, hlTheme)
        : <TextSpan>[];
    final baseColor =
        hlTheme['root']?.color ??
        (isDark ? Colors.white : const Color(0xFF24292E));

    return Container(
      color: _bg(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: theme.colorScheme.surfaceContainerHigh.withAlpha(100),
            child: Text(
              lineNum != null ? '$lineNum' : '',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withAlpha(77),
              ),
            ),
          ),
          if (changed)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                isRemoved ? '-' : '+',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isRemoved
                      ? (isDark
                            ? const Color(0xFFFF7B72)
                            : const Color(0xFFB31D28))
                      : (isDark
                            ? const Color(0xFF56D364)
                            : const Color(0xFF116329)),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: code != null
                  ? RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: baseColor,
                        ),
                        children: spans,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
