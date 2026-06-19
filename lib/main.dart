import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const KRepoXplorerApp(),
    ),
  );
}

class KRepoXplorerApp extends StatelessWidget {
  const KRepoXplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KRepoXplorer',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _AppLoader(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A6CF7),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final provider = context.read<AppProvider>();
    await provider.initialize();
    if (!mounted) return;
    if (provider.baseFolders.isEmpty) {
      await _showWelcomeDialog();
    }
  }

  Future<void> _showWelcomeDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _WelcomeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (!provider.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const MainScreen();
  }
}

class _WelcomeDialog extends StatelessWidget {
  const _WelcomeDialog();

  Future<void> _pickFolder(BuildContext context) async {
    final path = await getDirectoryPath(
      confirmButtonText: 'Select Base Folder',
    );
    if (path != null && context.mounted) {
      await context.read<AppProvider>().addBaseFolder(path);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.account_tree, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Welcome to KRepoXplorer'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To get started, select a base folder that contains your git repositories.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'KRepoXplorer will scan the folder and its subdirectories to find all git repositories. You can add more folders later.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip for now'),
        ),
        FilledButton.icon(
          onPressed: () => _pickFolder(context),
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text('Select Folder'),
        ),
      ],
    );
  }
}
