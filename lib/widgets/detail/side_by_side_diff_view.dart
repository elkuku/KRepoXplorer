import 'package:flutter/material.dart';
import 'diff_utils.dart';

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
    final hlTheme = diffHlTheme(Theme.of(context).brightness);
    final language = extractLang(content);
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
        ? highlightCode(code!, language, hlTheme)
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
