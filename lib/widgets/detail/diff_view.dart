import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart' show AppProvider, DiffMode;
import 'diff_utils.dart';
import 'side_by_side_diff_view.dart';

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

    if (provider.diffMode == DiffMode.sideBySide) {
      return SideBySideDiffView(content: content);
    }

    return _UnifiedDiffRenderer(content: content);
  }
}

class _UnifiedDiffRenderer extends StatelessWidget {
  final String content;
  const _UnifiedDiffRenderer({required this.content});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hlTheme = diffHlTheme(Theme.of(context).brightness);
    final language = extractLang(content);
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

    final bool isCodeLine = !_isFileHeader && !_isHunk;
    final String codeContent = isCodeLine && line.isNotEmpty
        ? line.substring(1)
        : line;
    final List<TextSpan> codeSpans = isCodeLine
        ? highlightCode(codeContent, language, hlTheme)
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
