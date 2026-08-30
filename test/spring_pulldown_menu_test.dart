import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spring_pulldown_menu/spring_pulldown_menu.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(appBar: AppBar(actions: [child]), body: const SizedBox()),
    );
  }

  testWidgets('opens the menu on tap and shows its actions', (tester) async {
    var renamed = false;

    await tester.pumpWidget(
      wrap(
        SpringPulldownMenuButton(
          actions: [
            SpringPulldownMenuAction(
              label: 'Rename',
              icon: CupertinoIcons.pencil,
              onTap: () => renamed = true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Rename'), findsNothing);

    await tester.tap(find.byType(SpringPulldownMenuButton));
    await tester.pumpAndSettle();

    expect(find.text('Rename'), findsOneWidget);

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(renamed, isTrue);
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('controller opens and closes the menu programmatically', (
    tester,
  ) async {
    final controller = SpringPulldownMenuController();

    await tester.pumpWidget(
      wrap(
        SpringPulldownMenuButton(
          controller: controller,
          actions: const [
            SpringPulldownMenuAction(label: 'Delete', icon: CupertinoIcons.trash),
          ],
        ),
      ),
    );

    expect(controller.isOpen, isFalse);

    controller.open();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue);
    expect(find.text('Delete'), findsOneWidget);

    controller.close();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('Delete'), findsNothing);
  });
}
