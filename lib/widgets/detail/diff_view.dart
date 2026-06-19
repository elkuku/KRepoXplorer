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
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import 'side_by_side_diff_view.dart';

// ---------------------------------------------------------------------------
// Language registration (shared with side_by_side_diff_view via module scope)
// The highlight package deduplicates registrations internally, so calling
// registerLanguage again is safe but this file registers its own set.
// ---------------------------------------------------------------------------

final _registeredUnified = <String>{};

void _ensureLanguageUnified(String lang) {
  if (_registeredUnified.contains(lang)) return;
  _registeredUnified.add(lang);
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

String? _detectLang(String? ext) => switch (ext?.toLowerCase()) {
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

String? _extractLang(String diff) {
  final m = RegExp(r'^---\s+[ab]/(.+)$', multiLine: true).firstMatch(diff);
  if (m == null) return null;
  final ext = m.group(1)!.split('.').last;
  return _detectLang(ext);
}

List<TextSpan> _convertNodes(List<Node> nodes, Map<String, TextStyle> theme) {
  final spans = <TextSpan>[];
  var current = spans;
  final stack = <List<TextSpan>>[];

  void traverse(Node node) {
    if (node.value != null) {
      current.add(
        TextSpan(
          text: node.value,
          style: node.className != null ? theme[node.className!] : null,
        ),
      );
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

List<TextSpan> _highlightCode(
  String code,
  String? language,
  Map<String, TextStyle> theme,
) {
  if (language == null || code.trim().isEmpty) return [TextSpan(text: code)];
  _ensureLanguageUnified(language);
  try {
    final result = highlight.parse(code, language: language);
    final spans = _convertNodes(result.nodes ?? [], theme);
    return spans.isEmpty ? [TextSpan(text: code)] : spans;
  } catch (_) {
    return [TextSpan(text: code)];
  }
}

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class DiffView extends StatefulWidget {
  final String? content;
  const DiffView({super.key, this.content});

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  @override
  void initState() {
    super.initState();
    if (widget.content == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppProvider>().loadFullDiff();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final content = widget.content ?? provider.diffContent;

    if (content == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (content.trim().isEmpty) {
      return const Center(child: Text('No diff to show'));
    }

    if (provider.diffMode == 'sideBySide') {
      return SideBySideDiffView(content: content);
    }

    return _UnifiedDiffRenderer(content: content);
  }
}

// ---------------------------------------------------------------------------
// Unified diff renderer (normal mode) with syntax highlighting
// ---------------------------------------------------------------------------

class _UnifiedDiffRenderer extends StatelessWidget {
  final String content;
  const _UnifiedDiffRenderer({required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hlTheme = isDark ? atomOneDarkTheme : githubTheme;
    final language = _extractLang(content);
    final lines = content.split('\n');

    return SelectionArea(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: lines.length,
        itemBuilder: (context, index) => _UnifiedDiffLine(
          line: lines[index],
          lineNumber: index + 1,
          hlTheme: hlTheme,
          language: language,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _UnifiedDiffLine extends StatelessWidget {
  final String line;
  final int lineNumber;
  final Map<String, TextStyle> hlTheme;
  final String? language;
  final bool isDark;

  const _UnifiedDiffLine({
    required this.line,
    required this.lineNumber,
    required this.hlTheme,
    required this.language,
    required this.isDark,
  });

  bool get _isAdded => line.startsWith('+') && !line.startsWith('+++');
  bool get _isRemoved => line.startsWith('-') && !line.startsWith('---');
  bool get _isHunk => line.startsWith('@@');
  bool get _isFileHeader =>
      line.startsWith('diff ') ||
      line.startsWith('index ') ||
      line.startsWith('---') ||
      line.startsWith('+++');

  Color _bgColor(BuildContext context) {
    final theme = Theme.of(context);
    if (_isAdded) {
      return isDark ? const Color(0xFF1A3A1A) : const Color(0xFFE6FFED);
    }
    if (_isRemoved) {
      return isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEB);
    }
    if (_isHunk) {
      return isDark ? const Color(0xFF1A1A3A) : const Color(0xFFEBF0FF);
    }
    if (_isFileHeader) return theme.colorScheme.surfaceContainerHigh;
    return Colors.transparent;
  }

  Color _markerColor() {
    if (_isAdded) {
      return isDark ? const Color(0xFF56D364) : const Color(0xFF116329);
    }
    if (_isRemoved) {
      return isDark ? const Color(0xFFFF7B72) : const Color(0xFFB31D28);
    }
    if (_isHunk) {
      return isDark ? const Color(0xFF79C0FF) : const Color(0xFF0969DA);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        hlTheme['root']?.color ?? (isDark ? Colors.white : Colors.black87);

    // For code lines (+/-/context), highlight the code portion only.
    // Header lines are rendered as plain styled text.
    final bool isCodeLine = !_isFileHeader && !_isHunk;
    final String codeContent = isCodeLine && line.isNotEmpty
        ? line.substring(1)
        : line;
    final List<TextSpan> codeSpans = isCodeLine
        ? _highlightCode(codeContent, language, hlTheme)
        : [
            TextSpan(
              text: line.isEmpty ? ' ' : line,
              style: TextStyle(color: _markerColor()),
            ),
          ];

    return Container(
      color: _bgColor(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: theme.colorScheme.surfaceContainerHigh.withAlpha(128),
            child: Text(
              '$lineNumber',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withAlpha(77),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (isCodeLine)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                line.isEmpty ? ' ' : line[0],
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: _markerColor(),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: baseColor,
                  ),
                  children: codeSpans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
