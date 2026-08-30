# spring_pulldown_menu

A self-contained, drop-in "..." button for Flutter with a springy,
frosted-glass pull-down menu popover — matching the pop-and-overshoot feel of
UIKit's `UIMenu` / SwiftUI's `Menu`.

No dependencies beyond the Flutter SDK.

## Features

- Springy pop-in menu with a frosted-glass (blurred) card, anchored to the
  button
- Directional press-lean: the button leans toward wherever you actually
  touch it, then rebounds past center on release before settling
- A deliberate release bounce (not just a barely-there natural spring
  overshoot) so the tap feedback actually reads on screen
- An "impact" bounce on the button when the menu closes some way other than
  the button's own tap (tap-outside, picking an action)
- A resting, subtle circular border/fill behind the icon — matching real iOS
  toolbar buttons — that deepens further on press
- Native-style solid selection flash on the tapped menu row (distinct from
  the ripple)
- A light haptic tick on menu row selection (`HapticFeedback.selectionClick`),
  matching real iOS — toggle off via `SpringPulldownMenuStyle.enableHaptics`
- VoiceOver / TalkBack labels on the button and every menu row
- Dark mode support
- An imperative `SpringPulldownMenuController` for opening/closing the menu from
  outside the button (e.g. a keyboard shortcut, another gesture)

## Usage

```dart
import 'package:spring_pulldown_menu/spring_pulldown_menu.dart';

AppBar(
  actions: [
    SpringPulldownMenuButton(
      actions: [
        SpringPulldownMenuAction(
          label: 'Rename',
          icon: CupertinoIcons.pencil,
          onTap: rename,
        ),
        SpringPulldownMenuAction(
          label: 'Delete',
          icon: CupertinoIcons.trash,
          isDestructive: true,
          onTap: delete,
        ),
      ],
    ),
  ],
)
```

Controlling the menu programmatically:

```dart
final menuController = SpringPulldownMenuController();

SpringPulldownMenuButton(
  controller: menuController,
  actions: [...],
)

// Elsewhere:
menuController.open();
menuController.close();
menuController.toggle();
```

Custom styling (springs, timing, colors, size) via `SpringPulldownMenuStyle`:

```dart
SpringPulldownMenuButton(
  style: SpringPulldownMenuStyle.defaults.copyWith(
    menuWidth: 280,
    cornerRadius: 20,
  ),
  actions: [...],
)
```

See `example/` for a full runnable app, including a light/dark mode toggle.

## Known limitations

- No drag-through selection yet (press, drag across menu items, release to
  pick — the real `UIMenu` interaction model). Currently each row only
  responds to its own independent tap.
