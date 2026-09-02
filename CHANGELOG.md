## 0.2.0

- **Non-breaking**: added `SpringPulldownMenuIconAffinity` (`leading` /
  `trailing`) and a `SpringPulldownMenuStyle.iconAffinity` field controlling
  where each row's icon sits relative to its label. **Default is
  `trailing`** — the original v0.1.0 layout (label, then icon) — so existing
  callers see no visual change. Set `leading` to match Apple Calendar's own
  pull-down menu (icon, then label). Directional, not left/right, so it
  flips correctly under RTL.
- **Fix**: a menu row's label no longer overflows (`RenderFlex overflowed by
  N pixels`) when it's wider than the menu's own width — it now ellipsizes
  instead, at any width and under any font metrics. The label is wrapped in
  `Flexible` (not `Expanded` — see below) with `TextOverflow.ellipsis`.
- **Fix / behavior change**: the icon-to-label gap is now a fixed 12px,
  matching Apple's own pull-downs, instead of a `spaceBetween` gap that grew
  to fill however wide the menu happened to be (visually "two disconnected
  columns" for any row shorter than the menu's width). `Flexible` rather
  than `Expanded` was needed for the fix to actually hold in both
  `iconAffinity` directions: `Expanded` forces the label to consume its
  entire allocated share of the row even when the text is shorter, which is
  invisible when the label is the *last* widget (`leading`) but reintroduces
  the exact same gap when the label comes *first* (`trailing`, the default).
- **Behavior change (field repurposed, not renamed)**: `menuWidth` is now a
  *maximum* width, not a fixed one. The menu shrinks to fit its widest row's
  actual content, and only grows up to `menuWidth` for a row too wide to fit
  (which then ellipsizes per the fix above, rather than the menu expanding
  further). A menu of short rows is now visibly narrower than 240pt by
  default; pass `menuWidth` if you want to guarantee a specific maximum.
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
