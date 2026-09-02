## 0.4.0

- **Non-breaking**: added five `SpringPulldownMenuStyle` fields controlling
  how far the button's and menu's animations actually travel, complementing
  the existing `buttonSpring`/`menuPopSpring` (which only control the
  settle-back *shape*, not the distance covered):
  - `buttonPressScale` (default 0.8) — how far the button shrinks on press.
  - `buttonBounceScale` (default 1.12) — the peak of the button's own
    tap-release bounce.
  - `buttonImpactBounceIntensity` (default 1.0) — multiplier on the
    button's gentler "impact" bounce (played when the menu closes some way
    other than the button's own tap); 0 disables it entirely.
  - `buttonLeanDistance` (default 20.0) — how far the button leans toward
    the touch point while pressed; 0 disables the lean, leaving a pure
    shrink/grow in place.
  - `menuBounceScale` (default 1.15) — the peak of the floating menu's own
    pop-in.
  All defaults reproduce prior behavior exactly, so existing callers see no
  change.
- **Behavior change**: the menu's pop-in no longer relies on a single
  `SpringSimulation(menuPopSpring, 0, 1, 0)` for its entire 0→1 rise (which
  made the actual overshoot amount an incidental side effect of
  `menuPopSpring`'s damping ratio, not something directly controllable). It
  now pops explicitly to `menuBounceScale` first (a plain 140ms curve), then
  hands off to `menuPopSpring` to settle back to 1.0 — mirroring the
  button's own `_playReleaseBounce` pattern, and making the peak a real,
  predictable number. With the default `menuBounceScale: 1.15` this should
  look and feel equivalent to before, but the *mechanism* producing that
  1.15 changed from "incidental spring overshoot" to "an explicit target,"
  which is worth knowing if you'd already tuned `menuPopSpring` specifically
  to hit a particular overshoot amount.

## 0.3.0

- **Non-breaking**: added `SpringPulldownMenuStyle.labelTextStyle` — lets you
  override a menu row's label font (size, weight, letter-spacing, family,
  etc). Null by default, so existing callers see no change. It's merged
  (via `TextStyle.merge`) onto the built-in default rather than replacing
  it outright, so setting only e.g. `fontWeight` doesn't lose the
  destructive/dark-mode `color` logic that's already computed for you.

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
