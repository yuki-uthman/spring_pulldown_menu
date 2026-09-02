## 0.2.0

- **Non-breaking**: added `SpringPulldownMenuIconAffinity` (`leading` /
  `trailing`) and a `SpringPulldownMenuStyle.iconAffinity` field controlling
  where each row's icon sits relative to its label. **Default is
  `trailing`** — the original v0.1.0 layout (label, then icon) — so existing
  callers see no visual change. Set `leading` to match Apple Calendar's own
  pull-down menu (icon, then label). Directional, not left/right, so it
  flips correctly under RTL.
- **Fix**: a menu row's label no longer overflows (`RenderFlex overflowed by
  N pixels`) when it's wider than `menuWidth` minus the icon and padding —
  it now ellipsizes instead, at any `menuWidth` and under any font metrics.
  Previously the label had no flex inside a `spaceBetween` `Row`; it's now
  wrapped in `Expanded` with `TextOverflow.ellipsis`.
- No other behavior changed: `dismiss(andThen: action.onTap)` ordering,
  `enableHaptics` semantics/default, row keylessness, the icon's widget
  identity, and the button's own rest chrome (38pt circle, 8px padding
  around a 22pt glyph, hairline border) are all untouched.

## 0.1.0

Initial release.

- `SpringPulldownMenuButton`: springy "..." pull-down menu button with frosted-glass
  popup, spring pop-in, directional press-lean, release bounce, and an
  "impact" bounce when the menu closes some way other than the button's own
  tap.
- `SpringPulldownMenuAction`, `SpringPulldownMenuStyle`, `SpringPulldownMenuController`.
- VoiceOver/TalkBack labels on the button and each menu row.
- Native-style solid selection flash on the tapped menu row.
- Light haptic tick on menu row selection (toggle via `enableHaptics`).
- Dark mode support.
