import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_spring_menu_button/ios_spring_menu_button.dart';

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
        IosSpringMenuButton(
          actions: [
            IosMenuAction(
              label: 'Rename',
              icon: CupertinoIcons.pencil,
              onTap: () => renamed = true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Rename'), findsNothing);

    await tester.tap(find.byType(IosSpringMenuButton));
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
    final controller = IosSpringMenuController();

    await tester.pumpWidget(
      wrap(
        IosSpringMenuButton(
          controller: controller,
          actions: const [
            IosMenuAction(label: 'Delete', icon: CupertinoIcons.trash),
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
