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

export 'package:flutter_highlight/themes/atom-one-dark.dart';
export 'package:flutter_highlight/themes/github.dart';

final _registered = <String>{};

void ensureLanguage(String lang) {
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

String? detectLang(String? ext) => switch (ext?.toLowerCase()) {
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

String? extractLang(String diff) {
  final m = RegExp(r'^---\s+[ab]/(.+)$', multiLine: true).firstMatch(diff);
  if (m == null) return null;
  final ext = m.group(1)!.split('.').last;
  return detectLang(ext);
}

List<TextSpan> convertNodes(List<Node> nodes, Map<String, TextStyle> theme) {
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

List<TextSpan> highlightCode(
  String code,
  String? language,
  Map<String, TextStyle> theme,
) {
  if (language == null || code.trim().isEmpty) return [TextSpan(text: code)];
  ensureLanguage(language);
  try {
    final result = highlight.parse(code, language: language);
    final spans = convertNodes(result.nodes ?? [], theme);
    return spans.isEmpty ? [TextSpan(text: code)] : spans;
  } catch (_) {
    return [TextSpan(text: code)];
  }
}

Map<String, TextStyle> diffHlTheme(Brightness brightness) =>
    brightness == Brightness.dark ? atomOneDarkTheme : githubTheme;
