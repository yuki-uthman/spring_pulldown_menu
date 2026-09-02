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
- The menu shrinks to fit its widest row's actual content, growing only up
  to `menuWidth` as a maximum — not a fixed size regardless of content
- A fixed icon-to-label gap (12px) that doesn't grow with the menu's width,
  matching Apple's own pull-downs
- Row labels ellipsize instead of overflowing when a row is too wide for
  `menuWidth`
- Configurable icon placement per row (`SpringPulldownMenuStyle.iconAffinity`
  — `trailing` by default, matching v0.1.0; `leading` to match Apple
  Calendar's own pull-down menu), directional so it flips correctly under RTL
- Customizable row label font (`SpringPulldownMenuStyle.labelTextStyle`) —
  size, weight, letter-spacing, font family, etc — merged on top of the
  built-in default without disturbing the destructive/dark-mode color logic
- Adjustable bounce intensity and lean distance for the button
  (`buttonPressScale`, `buttonBounceScale`, `buttonImpactBounceIntensity`,
  `buttonLeanDistance`) and the floating menu's own pop-in (`menuBounceScale`)
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

Custom styling (springs, timing, colors, size) via `SpringPulldownMenuStyle`.
`menuWidth` is a *maximum*, not a fixed width — the menu shrinks to fit its
content otherwise:

```dart
SpringPulldownMenuButton(
  style: SpringPulldownMenuStyle.defaults.copyWith(
    menuWidth: 280, // cap; short rows render narrower than this
    cornerRadius: 20,
  ),
  actions: [...],
)
```

Icon-leading rows (Apple Calendar's own pull-down layout):

```dart
SpringPulldownMenuButton(
  style: SpringPulldownMenuStyle.defaults.copyWith(
    iconAffinity: SpringPulldownMenuIconAffinity.leading,
  ),
  actions: [...],
)
```

Custom row label font — merges onto the default, so setting only
`fontWeight` doesn't lose the destructive/dark-mode color already picked
for you:

```dart
SpringPulldownMenuButton(
  style: SpringPulldownMenuStyle.defaults.copyWith(
    labelTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  ),
  actions: [...],
)
```

Adjusting the bounce/distance feel — button press-in, its tap-release
bounce, its gentler "impact" bounce when the menu closes some other way, how
far it leans toward your touch, and the menu's own pop-in peak:

```dart
SpringPulldownMenuButton(
  style: SpringPulldownMenuStyle.defaults.copyWith(
    buttonPressScale: 0.7,             // deeper press-in (default 0.8)
    buttonBounceScale: 1.2,            // bigger tap-release pop (default 1.12)
    buttonImpactBounceIntensity: 0.0,  // disable the impact bounce entirely
    buttonLeanDistance: 0.0,           // pure shrink/grow, no lean at all
    menuBounceScale: 1.25,             // bigger pop-in peak (default 1.15)
  ),
  actions: [...],
)
```

`buttonSpring` and `menuPopSpring` (both `SpringDescription`) separately
control the *shape* of the settle-back-to-rest motion (how bouncy/springy vs.
stiff/damped it feels) — the fields above control how far each animation
actually travels before that settle begins.

See `example/` for a full runnable app, including a light/dark mode toggle.

## Known limitations

- No drag-through selection yet (press, drag across menu items, release to
  pick — the real `UIMenu` interaction model). Currently each row only
  responds to its own independent tap.
