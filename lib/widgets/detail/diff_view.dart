import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

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

    return _DiffRenderer(content: content);
  }
}

class _DiffRenderer extends StatelessWidget {
  final String content;
  const _DiffRenderer({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');

    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(0),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];
          return _DiffLine(line: line, lineNumber: index + 1);
        },
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  final String line;
  final int lineNumber;
  const _DiffLine({required this.line, required this.lineNumber});

  Color _bgColor(BuildContext context) {
    final theme = Theme.of(context);
    if (line.startsWith('+') && !line.startsWith('+++')) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF1A3A1A)
          : const Color(0xFFE6FFED);
    }
    if (line.startsWith('-') && !line.startsWith('---')) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF3A1A1A)
          : const Color(0xFFFFEBEB);
    }
    if (line.startsWith('@@')) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF1A1A3A)
          : const Color(0xFFEBF0FF);
    }
    if (line.startsWith('diff ') || line.startsWith('index ') ||
        line.startsWith('---') || line.startsWith('+++')) {
      return theme.colorScheme.surfaceContainerHigh;
    }
    return Colors.transparent;
  }

  Color _textColor(BuildContext context) {
    final theme = Theme.of(context);
    if (line.startsWith('+') && !line.startsWith('+++')) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF56D364)
          : const Color(0xFF116329);
    }
    if (line.startsWith('-') && !line.startsWith('---')) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFFFF7B72)
          : const Color(0xFFB31D28);
    }
    if (line.startsWith('@@')) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF79C0FF)
          : const Color(0xFF0969DA);
    }
    return theme.colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                line.isEmpty ? ' ' : line,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: _textColor(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
