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
            SpringPulldownMenuAction(
                label: 'Delete', icon: CupertinoIcons.trash),
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

  testWidgets(
    'a label wider than menuWidth ellipsizes instead of overflowing',
    (tester) async {
      // Under flutter_test's placeholder font (no real glyph metrics), any
      // label this long measures wider than the default menuWidth of 240 —
      // reproduces the exact RenderFlex overflow this regression test
      // guards against, without relying on a specific pixel count.
      final controller = SpringPulldownMenuController();

      await tester.pumpWidget(
        wrap(
          SpringPulldownMenuButton(
            controller: controller,
            actions: const [
              SpringPulldownMenuAction(
                label:
                    'A label long enough to overflow any reasonable menu width',
                icon: CupertinoIcons.clock,
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(CupertinoIcons.clock), findsOneWidget);
    },
  );

  testWidgets('iconAffinity.leading places the icon before the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SpringPulldownMenuButton(
          style: SpringPulldownMenuStyle.defaults.copyWith(
            iconAffinity: SpringPulldownMenuIconAffinity.leading,
          ),
          actions: const [
            SpringPulldownMenuAction(
              label: 'Prayer Times',
              icon: CupertinoIcons.clock,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(SpringPulldownMenuButton));
    await tester.pumpAndSettle();

    final iconLeft = tester.getTopLeft(find.byIcon(CupertinoIcons.clock)).dx;
    final labelLeft = tester.getTopLeft(find.text('Prayer Times')).dx;
    expect(iconLeft, lessThan(labelLeft));
  });

  testWidgets(
    'iconAffinity defaults to trailing (icon after the label, v0.1.0 layout)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const SpringPulldownMenuButton(
            actions: [
              SpringPulldownMenuAction(
                label: 'Prayer Times',
                icon: CupertinoIcons.clock,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(SpringPulldownMenuButton));
      await tester.pumpAndSettle();

      final iconLeft = tester.getTopLeft(find.byIcon(CupertinoIcons.clock)).dx;
      final labelLeft = tester.getTopLeft(find.text('Prayer Times')).dx;
      expect(labelLeft, lessThan(iconLeft));
    },
  );

  testWidgets(
    'the menu shrinks to fit a short row instead of using the full menuWidth cap',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          const SpringPulldownMenuButton(
            actions: [
              SpringPulldownMenuAction(label: 'Hi', icon: CupertinoIcons.clock),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(SpringPulldownMenuButton));
      await tester.pumpAndSettle();

      final menuWidth = tester.getSize(find.byType(ClipRRect).first).width;
      // The default cap is 240 — a two-letter label should resolve to
      // nowhere near that, proving this measures actual content width and
      // not just the cap.
      expect(menuWidth, lessThan(150));
    },
  );

  testWidgets(
    'a row too wide for the cap still resolves to exactly menuWidth, not wider',
    (tester) async {
      const style = SpringPulldownMenuStyle(menuWidth: 200);

      await tester.pumpWidget(
        wrap(
          const SpringPulldownMenuButton(
            style: style,
            actions: [
              SpringPulldownMenuAction(
                label:
                    'A label long enough to overflow any reasonable menu width',
                icon: CupertinoIcons.clock,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(SpringPulldownMenuButton));
      await tester.pumpAndSettle();

      final menuWidth = tester.getSize(find.byType(ClipRRect).first).width;
      expect(menuWidth, lessThanOrEqualTo(style.menuWidth));
      expect(menuWidth, greaterThan(style.menuWidth - 1));
    },
  );

  testWidgets('the icon-to-label gap stays fixed regardless of menu width', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SpringPulldownMenuButton(
          style: SpringPulldownMenuStyle(
            iconAffinity: SpringPulldownMenuIconAffinity.leading,
          ),
          actions: [
            SpringPulldownMenuAction(label: 'Hi', icon: CupertinoIcons.clock),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(SpringPulldownMenuButton));
    await tester.pumpAndSettle();

    final iconRight = tester.getTopRight(find.byIcon(CupertinoIcons.clock)).dx;
    final labelLeft = tester.getTopLeft(find.text('Hi')).dx;
    // Fixed 12px SizedBox between them — not a spaceBetween-style gap that
    // would grow with however wide the (capped) menu happens to be.
    expect(labelLeft - iconRight, closeTo(12, 1));
  });

  testWidgets('labelTextStyle overrides font size and weight', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SpringPulldownMenuButton(
          style: SpringPulldownMenuStyle(
            labelTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SpringPulldownMenuAction(
                label: 'Rename', icon: CupertinoIcons.pencil),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(SpringPulldownMenuButton));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('Rename'));
    expect(text.style?.fontSize, 22);
    expect(text.style?.fontWeight, FontWeight.w700);
  });

  testWidgets(
    'labelTextStyle merges without losing the destructive color',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          SpringPulldownMenuButton(
            style: SpringPulldownMenuStyle.defaults.copyWith(
              labelTextStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: const [
              SpringPulldownMenuAction(
                label: 'Delete',
                icon: CupertinoIcons.trash,
                isDestructive: true,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(SpringPulldownMenuButton));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Delete'));
      // fontWeight came from labelTextStyle; color is untouched by it, so
      // it still falls through to destructiveColor rather than resetting
      // to the plain label color.
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(
          text.style?.color, SpringPulldownMenuStyle.defaults.destructiveColor);
    },
  );
}
