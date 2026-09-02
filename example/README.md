# spring_pulldown_menu example — Bounce Playground

An interactive playground for `SpringPulldownMenuStyle`'s bounce/distance
knobs. The "..." button in the app bar is live-wired to five sliders in the
body — drag any of them and the button/menu rebuild immediately with the new
`SpringPulldownMenuStyle`, no recompiling needed:

- `buttonPressScale` — how far the button shrinks on press-in
- `buttonBounceScale` — peak of the button's own tap-release bounce
- `buttonImpactBounceIntensity` — the gentler bounce played when the menu
  closes some way other than the button's own tap (tap-outside, picking an
  action); 0 disables it
- `buttonLeanDistance` — how far the button leans toward your touch; 0
  disables the lean
- `menuBounceScale` — peak of the floating menu's own pop-in

Each slider has a "Default: …" button that jumps straight back to that
field's built-in default. There's also a sun/moon toggle in the app bar to
check everything in dark mode.

## Running it

```sh
cd example
flutter pub get
flutter run
```

If you haven't generated platform runners for this example yet:

```sh
flutter create --platforms=ios,android .
```

## What to try

1. Tap the "..." button — feel the default press/bounce/pop-in.
2. Drag `buttonLeanDistance` to 0, tap again — the button now just
   shrinks/grows in place, no lean.
3. Drag `buttonImpactBounceIntensity` to 0, open the menu, then tap outside
   it to dismiss — the button stays still instead of playing the impact
   bounce (tapping the button itself to close it is unaffected either way).
4. Push `buttonBounceScale` and `menuBounceScale` toward their maximums for
   an exaggerated, cartoonish pop — useful for seeing the effect clearly
   before dialing it back to something subtle.
