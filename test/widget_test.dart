import 'package:flutter_test/flutter_test.dart';
import 'package:krepo_xplorer/main.dart';
import 'package:provider/provider.dart';
import 'package:krepo_xplorer/providers/app_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const KRepoXplorerApp(),
      ),
    );
    expect(find.byType(KRepoXplorerApp), findsOneWidget);
  });
}
