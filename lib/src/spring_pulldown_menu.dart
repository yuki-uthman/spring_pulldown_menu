import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoColors;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// -----------------------------------------------------------------------
/// SpringPulldownMenuButton — a self-contained, drop-in "..." button with a
/// springy iOS/UIKit-style pull-down menu popover.
///
/// This whole file has no dependencies beyond the Flutter SDK — nothing else
/// from this package is required to use it.
///
/// ```dart
/// final menuController = SpringPulldownMenuController();
///
/// SpringPulldownMenuButton(
///   controller: menuController, // optional — omit it if you don't need
///                               // to open/close the menu programmatically
///   actions: [
///     SpringPulldownMenuAction(label: 'Rename', icon: CupertinoIcons.pencil, onTap: rename),
///     SpringPulldownMenuAction(label: 'Delete', icon: CupertinoIcons.trash, isDestructive: true, onTap: delete),
///   ],
/// )
///
/// // Elsewhere:
/// menuController.open();
/// menuController.close();
/// ```
/// -----------------------------------------------------------------------

/// A single row in the popup menu.
class SpringPulldownMenuAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// Renders the row in [SpringPulldownMenuStyle.destructiveColor] (e.g. "Delete").
  final bool isDestructive;

  const SpringPulldownMenuAction({
    required this.label,
    required this.icon,
    this.onTap,
    this.isDestructive = false,
  });
}

/// Where [SpringPulldownMenuAction.icon] sits relative to its label within a
/// menu row. Directional (leading/trailing), not left/right, so RTL locales
/// flip correctly.
enum SpringPulldownMenuIconAffinity {
  /// Icon before the label — e.g. Apple Calendar's own pull-down menu.
  leading,

  /// Icon after the label — this package's original v0.1.0 layout.
  trailing,
}

/// Visual + physics configuration for [SpringPulldownMenuButton] — the same role
/// [ThemeData]/`CardTheme` play for built-in Material widgets. Override only
/// the fields you care about via [copyWith]; everything else falls back to
/// HIG-matched defaults.
class SpringPulldownMenuStyle {
  /// Spring driving the button's own press/release recoil.
  final SpringDescription buttonSpring;

  /// Spring driving the menu's pop-in.
  final SpringDescription menuPopSpring;

  /// Dismissal is a plain curve, deliberately NOT a spring — closing should
  /// feel snappy, not bouncy, matching native iOS asymmetric pop-in/fade-out.
  final Duration closeDuration;
  final Curve closeCurve;

  /// The menu's *maximum* width, not a fixed one — as of v0.2.0 it shrinks
  /// to fit its widest row's actual content, and only grows up to this cap
  /// for a row too wide to fit (which then ellipsizes instead of expanding
  /// the menu further).
  final double menuWidth;
  final double cornerRadius;
  final double blurSigma;

  /// Menu card fill color. When null, falls back to a translucent white
  /// (light mode) or translucent dark-gray (dark mode).
  final Color? lightFillColor;
  final Color? darkFillColor;

  final Color destructiveColor;

  /// Whether tapping a menu row fires a light [HapticFeedback.selectionClick]
  /// — matching real iOS pull-down/context menus. Set false if your app
  /// manages its own haptics policy (or for tests).
  final bool enableHaptics;

  /// Where each row's icon sits relative to its label. Defaults to
  /// [SpringPulldownMenuIconAffinity.trailing] — this package's original
  /// v0.1.0 layout — so picking this default up costs existing callers
  /// nothing; set [SpringPulldownMenuIconAffinity.leading] to match Apple
  /// Calendar's own pull-down menu instead.
  final SpringPulldownMenuIconAffinity iconAffinity;

  /// Overrides for a menu row's label text (size, weight, letter-spacing,
  /// font family, etc). Merged on top of the built-in default
  /// (`TextStyle(fontSize: 16)` plus the color already picked for you —
  /// destructive rows use [destructiveColor], everything else adapts to
  /// light/dark mode) via [TextStyle.merge], so setting only e.g.
  /// `fontWeight` doesn't clobber that color logic. Null (the default)
  /// changes nothing.
  final TextStyle? labelTextStyle;

  /// How far the button shrinks on press-down, as a scale factor (1.0 =
  /// no shrink). Smaller values (e.g. 0.7) read as a deeper, more dramatic
  /// press; values close to 1.0 read as a subtle one. Also sets how far
  /// the button leans toward the touch point while held, since both are
  /// driven by the same press-progress signal (see [buttonLeanDistance]).
  final double buttonPressScale;

  /// The peak scale the button pops past 1.0 to on its own tap-release
  /// bounce (see [buttonSpring] for the spring shape it then settles with).
  /// 1.0 would mean no overshoot at all; higher values read as a bigger,
  /// bouncier pop.
  final double buttonBounceScale;

  /// Scales the button's "impact" bounce — the shallower, gentler cousin of
  /// [buttonBounceScale] played when the menu closes some way other than
  /// the button's own tap (tap-outside, picking an action). 1.0 is the
  /// built-in gentle default; 0 disables the impact bounce entirely
  /// (the button stays still); values above 1.0 make it more pronounced,
  /// up to as dramatic as [buttonBounceScale] itself.
  final double buttonImpactBounceIntensity;

  /// How far (in logical pixels, roughly) the button visually leans toward
  /// the touch point while pressed, and rebounds the opposite way on
  /// release/impact. 0 disables the lean entirely, leaving a pure
  /// shrink/grow-in-place bounce.
  final double buttonLeanDistance;

  /// The peak scale the floating menu pops past 1.0 to when it opens, akin
  /// to [buttonBounceScale] but for the menu card itself (see
  /// [menuPopSpring] for the spring shape it then settles with). 1.0 means
  /// no overshoot.
  final double menuBounceScale;

  /// How many times the button's settle-to-rest motion oscillates before
  /// holding still, independent of [buttonBounceScale]'s peak — this is a
  /// spring's *damping ratio*, a physics term for exactly that: 1.0 pops to
  /// the peak and holds with no bounce at all; below 1.0 it oscillates,
  /// more times the closer to 0; above 1.0 it settles slowly with no
  /// oscillation either. Null (the default) leaves [buttonSpring]'s own
  /// `damping` value as given. Setting this recomputes an effective damping
  /// from [buttonSpring]'s `mass`/`stiffness` — it doesn't replace
  /// [buttonSpring], so you can still tune those two for overall speed/feel
  /// and use this just for "how bouncy."
  final double? buttonDampingRatio;

  /// The floating menu's equivalent of [buttonDampingRatio], applied to
  /// [menuPopSpring] the same way.
  final double? menuDampingRatio;

  const SpringPulldownMenuStyle({
    this.buttonSpring = const SpringDescription(
      mass: 1,
      stiffness: 300,
      damping: 12,
    ),
    this.menuPopSpring = const SpringDescription(
      mass: 1,
      stiffness: 250,
      damping: 15,
    ),
    this.closeDuration = const Duration(milliseconds: 160),
    this.closeCurve = Curves.easeIn,
    this.menuWidth = 240,
    this.cornerRadius = 14,
    this.blurSigma = 24,
    this.lightFillColor,
    this.darkFillColor,
    this.destructiveColor = CupertinoColors.destructiveRed,
    this.enableHaptics = true,
    this.iconAffinity = SpringPulldownMenuIconAffinity.trailing,
    this.labelTextStyle,
    this.buttonPressScale = 0.8,
    this.buttonBounceScale = 1.12,
    this.buttonImpactBounceIntensity = 1.0,
    this.buttonLeanDistance = 20.0,
    this.menuBounceScale = 1.15,
    this.buttonDampingRatio,
    this.menuDampingRatio,
  });

  static const defaults = SpringPulldownMenuStyle();

  /// [buttonSpring] as actually used — [buttonSpring] itself unless
  /// [buttonDampingRatio] overrides just its damping.
  SpringDescription get effectiveButtonSpring =>
      _withDampingRatio(buttonSpring, buttonDampingRatio);

  /// [menuPopSpring] as actually used — [menuPopSpring] itself unless
  /// [menuDampingRatio] overrides just its damping.
  SpringDescription get effectiveMenuPopSpring =>
      _withDampingRatio(menuPopSpring, menuDampingRatio);

  static SpringDescription _withDampingRatio(
    SpringDescription spring,
    double? dampingRatio,
  ) {
    if (dampingRatio == null) return spring;
    return SpringDescription(
      mass: spring.mass,
      stiffness: spring.stiffness,
      damping: dampingRatio * 2 * math.sqrt(spring.mass * spring.stiffness),
    );
  }

  SpringPulldownMenuStyle copyWith({
    SpringDescription? buttonSpring,
    SpringDescription? menuPopSpring,
    Duration? closeDuration,
    Curve? closeCurve,
    double? menuWidth,
    double? cornerRadius,
    double? blurSigma,
    Color? lightFillColor,
    Color? darkFillColor,
    Color? destructiveColor,
    bool? enableHaptics,
    SpringPulldownMenuIconAffinity? iconAffinity,
    TextStyle? labelTextStyle,
    double? buttonPressScale,
    double? buttonBounceScale,
    double? buttonImpactBounceIntensity,
    double? buttonLeanDistance,
    double? menuBounceScale,
    double? buttonDampingRatio,
    double? menuDampingRatio,
  }) {
    return SpringPulldownMenuStyle(
      buttonSpring: buttonSpring ?? this.buttonSpring,
      menuPopSpring: menuPopSpring ?? this.menuPopSpring,
      closeDuration: closeDuration ?? this.closeDuration,
      closeCurve: closeCurve ?? this.closeCurve,
      menuWidth: menuWidth ?? this.menuWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      blurSigma: blurSigma ?? this.blurSigma,
      lightFillColor: lightFillColor ?? this.lightFillColor,
      darkFillColor: darkFillColor ?? this.darkFillColor,
      destructiveColor: destructiveColor ?? this.destructiveColor,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      iconAffinity: iconAffinity ?? this.iconAffinity,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      buttonPressScale: buttonPressScale ?? this.buttonPressScale,
      buttonBounceScale: buttonBounceScale ?? this.buttonBounceScale,
      buttonImpactBounceIntensity:
          buttonImpactBounceIntensity ?? this.buttonImpactBounceIntensity,
      buttonLeanDistance: buttonLeanDistance ?? this.buttonLeanDistance,
      menuBounceScale: menuBounceScale ?? this.menuBounceScale,
      buttonDampingRatio: buttonDampingRatio ?? this.buttonDampingRatio,
      menuDampingRatio: menuDampingRatio ?? this.menuDampingRatio,
    );
  }
}

/// Imperative handle for a [SpringPulldownMenuButton] — attach one to open,
/// close, or query the menu from outside the widget that owns the button,
/// the same way you'd drive a [TextEditingController] or [AnimationController].
///
/// Optional: if you never need to control the menu programmatically (only
/// via the button's own tap), leave [SpringPulldownMenuButton.controller] unset —
/// the button manages its own internally.
class SpringPulldownMenuController {
  _SpringPulldownMenuButtonState? _state;

  bool get isOpen => _state?._menuOpen ?? false;

  void open() => _state?._openMenu();
  void close() => _state?._closeMenu();
  void toggle() => _state?._toggleMenu();

  void _attach(_SpringPulldownMenuButtonState state) => _state = state;
  void _detach(_SpringPulldownMenuButtonState state) {
    if (_state == state) _state = null;
  }
}

/// A self-contained iOS-style "..." button that pops open a springy,
/// frosted-glass pull-down menu anchored to the button's own screen position —
/// matching the pop-and-overshoot feel of UIKit's `UIMenu` / SwiftUI's
/// `Menu`.
class SpringPulldownMenuButton extends StatefulWidget {
  final List<SpringPulldownMenuAction> actions;
  final SpringPulldownMenuController? controller;
  final SpringPulldownMenuStyle style;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;

  /// Announced by VoiceOver/TalkBack — this button carries no visible text,
  /// so without this a screen reader has nothing to say for it.
  final String semanticLabel;

  const SpringPulldownMenuButton({
    super.key,
    required this.actions,
    this.controller,
    this.style = SpringPulldownMenuStyle.defaults,
    this.icon = CupertinoIcons.ellipsis,
    this.iconSize = 22,
    this.iconColor,
    this.semanticLabel = 'More options',
  });

  @override
  State<SpringPulldownMenuButton> createState() =>
      _SpringPulldownMenuButtonState();
}

class _SpringPulldownMenuButtonState extends State<SpringPulldownMenuButton>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;

  /// Drives the circular tap-highlight behind the icon — the same
  /// momentary "whitish" (dark mode) / "grayish" (light mode) flash a real
  /// UIKit bar button shows while held down.
  late final AnimationController _highlightController;

  final GlobalKey _buttonKey = GlobalKey();
  final GlobalKey<_SpringMenuOverlayState> _menuKey = GlobalKey();

  SpringPulldownMenuController? _internalController;
  OverlayEntry? _overlayEntry;
  bool _menuOpen = false;

  /// Unit vector from the button's center toward wherever the finger landed,
  /// captured on tap-down. Drives the sideways/vertical nudge below — real
  /// iOS buttons don't just shrink-and-grow in place, they lean slightly the
  /// way they were pushed, then rebound past center before settling.
  Offset _pressDirection = Offset.zero;

  SpringPulldownMenuController get _effectiveController =>
      widget.controller ??
      (_internalController ??= SpringPulldownMenuController());

  @override
  void initState() {
    super.initState();
    // upperBound gives the spring room to overshoot past 1.0 without being
    // clamped mid-animation — generous and fixed rather than computed from
    // widget.style.buttonBounceScale, since AnimationController bounds are
    // set once at construction and can't be resized later if that style
    // property changes at runtime.
    _scaleController = AnimationController(
      vsync: this,
      value: 1.0,
      lowerBound: 0.0,
      upperBound: 5.0,
    );
    _highlightController = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 160),
    );
    _effectiveController._attach(this);
  }

  @override
  void didUpdateWidget(covariant SpringPulldownMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?._detach(this);
      _effectiveController._attach(this);
    }
  }

  @override
  void dispose() {
    _effectiveController._detach(this);
    _overlayEntry?.remove();
    _scaleController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final delta = details.localPosition - box.size.center(Offset.zero);
      _pressDirection =
          delta.distance > 0 ? delta / delta.distance : Offset.zero;
    }

    _scaleController.stop();
    _scaleController.animateTo(
      widget.style.buttonPressScale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
    );
    _highlightController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _playReleaseBounce();
    _highlightController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    _toggleMenu();
  }

  /// A screen reader's activation gesture (VoiceOver double-tap, etc.) has no
  /// touch point of its own to lean toward, so this plays the same
  /// tap-release bounce dead-center instead of skipping it entirely.
  void _activateFromSemantics() {
    _pressDirection = Offset.zero;
    _playReleaseBounce();
    _toggleMenu();
  }

  // A spring settling straight from the pressed-down scale only travels a
  // small distance, so its natural overshoot past 1.0 is tiny — barely
  // perceptible next to the menu popping in at the same moment. Popping
  // explicitly to buttonBounceScale first, then letting the spring settle
  // back down from there, guarantees a bounce that actually reads on screen.
  void _playReleaseBounce() {
    _scaleController
        .animateTo(
      widget.style.buttonBounceScale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    )
        .then((_) {
      if (mounted) {
        _scaleController.animateWith(
          SpringSimulation(
            widget.style.effectiveButtonSpring,
            _scaleController.value,
            1.0,
            0,
          ),
        );
      }
    });
  }

  void _onTapCancel() {
    _scaleController.animateWith(
      SpringSimulation(
        widget.style.effectiveButtonSpring,
        _scaleController.value,
        1.0,
        0,
      ),
    );
    _highlightController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _toggleMenu() {
    if (_menuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_menuOpen) return;

    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final anchor = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _SpringMenuOverlay(
        key: _menuKey,
        anchor: anchor,
        anchorSize: anchorSize,
        actions: widget.actions,
        style: widget.style,
        onDismissStart: _playImpactBounce,
        onRemoved: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
          if (mounted) setState(() => _menuOpen = false);
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _menuOpen = true);
  }

  // Closing via the button's own tap already gets its own press/release
  // bounce from _onTapUp — skip the impact bounce here so the two don't
  // stack. Every other way the menu can close (tap-outside, picking an
  // action) does still want it.
  void _closeMenu() => _menuKey.currentState?.dismiss(notifyButton: false);

  /// Plays a small "the closing menu just landed on the button" bounce —
  /// a shallower, gentler cousin of the deliberate pop in `_onTapUp`, for
  /// closes the button itself didn't initiate (tap-outside, picking an
  /// action). The menu collapses back down toward the button from below, so
  /// the nudge leans downward rather than toward a touch point.
  void _playImpactBounce() {
    _pressDirection = const Offset(0, 1);
    _scaleController.stop();
    // Baseline dip/peak (0.94 / 1.08) scaled by buttonImpactBounceIntensity —
    // 1.0 reproduces the built-in gentle default, 0 flattens it to no bounce
    // at all, values above 1.0 push it toward as dramatic as the button's
    // own tap-release bounce.
    final intensity = widget.style.buttonImpactBounceIntensity;
    final dipScale = 1.0 - 0.06 * intensity;
    final peakScale = 1.0 + 0.08 * intensity;
    _scaleController
        .animateTo(
      dipScale,
      duration: const Duration(milliseconds: 60),
      curve: Curves.easeOut,
    )
        .then((_) {
      if (!mounted) return;
      _scaleController
          .animateTo(
        peakScale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
      )
          .then((_) {
        if (mounted) {
          _scaleController.animateWith(
            SpringSimulation(
              widget.style.effectiveButtonSpring,
              _scaleController.value,
              1.0,
              0,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? Theme.of(context).iconTheme.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // A UIKit bar button whitens its icon area on dark backgrounds and
    // darkens it on light ones while held — never the opposite.
    final highlightColor = isDark ? Colors.white : Colors.black;
    // Real iOS circular toolbar buttons (e.g. Files, Reminders) sit inside a
    // faint tinted circle at rest — a fill one shade off the bar behind it,
    // outlined with a hairline border — not bare, borderless dots. Both use
    // the same base hue as the press highlight, so the two alphas can just
    // add on top of each other.
    final restFillAlpha = isDark ? 0.10 : 0.045;
    final restBorderAlpha = isDark ? 0.16 : 0.09;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: _activateFromSemantics,
      child: GestureDetector(
        key: _buttonKey,
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _highlightController]),
          builder: (context, child) {
            // Same deviation-from-rest the scale bounce already tracks: positive
            // while pressed in (scale < 1, nudges toward the finger), negative
            // during the release overshoot (scale > 1, rebounds past center the
            // other way) — one signal driving both the size and the lean, so
            // they always stay in lockstep instead of two animations drifting
            // out of sync with each other.
            final pushT = 1.0 - _scaleController.value;
            return Transform.translate(
              offset:
                  _pressDirection * (pushT * widget.style.buttonLeanDistance),
              child: Transform.scale(
                scale: _scaleController.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlightColor.withValues(
                      alpha: restFillAlpha + 0.16 * _highlightController.value,
                    ),
                    border: Border.all(
                      color: highlightColor.withValues(alpha: restBorderAlpha),
                      width: 0.75,
                    ),
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: Icon(widget.icon, size: widget.iconSize, color: color),
        ),
      ),
    );
  }
}

/// The overlay: a tap-to-dismiss blurred barrier plus the floating menu card,
/// both driven by one spring-simulated controller. Internal implementation
/// detail — external code drives everything through [SpringPulldownMenuController].
class _SpringMenuOverlay extends StatefulWidget {
  final Offset anchor;
  final Size anchorSize;
  final List<SpringPulldownMenuAction> actions;
  final SpringPulldownMenuStyle style;

  /// Called once, right as a dismiss not triggered by the button itself
  /// begins (tap-outside, picking an action) — lets the button play its own
  /// "impact" bounce as the menu collapses back down onto it.
  final VoidCallback? onDismissStart;

  final VoidCallback onRemoved;

  const _SpringMenuOverlay({
    required super.key,
    required this.anchor,
    required this.anchorSize,
    required this.actions,
    required this.style,
    this.onDismissStart,
    required this.onRemoved,
  });

  @override
  State<_SpringMenuOverlay> createState() => _SpringMenuOverlayState();
}

class _SpringMenuOverlayState extends State<_SpringMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    // upperBound generous and fixed, same reasoning as the button's own
    // _scaleController — set once at construction, so it needs headroom for
    // any reasonable widget.style.menuBounceScale rather than being tied to
    // it directly.
    _controller = AnimationController(
      vsync: this,
      value: 0,
      lowerBound: 0,
      upperBound: 5.0,
    );
    // Pop in on the next frame (so the overlay has a valid size to lay out
    // against). A pure spring from 0 makes the *amount* of overshoot a
    // function of menuPopSpring's damping ratio alone — hard to predict or
    // dial in directly. Popping explicitly to menuBounceScale first, then
    // handing off to menuPopSpring to settle back to 1.0, mirrors the
    // button's own _playReleaseBounce and makes the peak a real, controllable
    // number instead of an incidental side effect of the spring's shape.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller
          .animateTo(
        widget.style.menuBounceScale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
      )
          .then((_) {
        if (mounted) {
          _controller.animateWith(
            SpringSimulation(
              widget.style.effectiveMenuPopSpring,
              _controller.value,
              1.0,
              0,
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Animates the menu out, then removes it from the [Overlay]. [notifyButton]
  /// is false only when the button itself initiated the close (it already
  /// plays its own bounce from the tap that triggered this).
  Future<void> dismiss({
    VoidCallback? andThen,
    bool notifyButton = true,
  }) async {
    if (_closing) return;
    _closing = true;
    if (notifyButton) widget.onDismissStart?.call();
    await _controller.animateTo(
      0,
      duration: widget.style.closeDuration,
      curve: widget.style.closeCurve,
    );
    andThen?.call();
    widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = widget.style;

    // Anchor the card so it hangs below the button, right-edge aligned with
    // it (matching where a native iOS pull-down menu opens from a top-right
    // "..." button), clamped to stay fully on-screen. Positioned from the
    // *right* — not a computed left offset — so this holds regardless of
    // the card's actual (shrink-to-fit) width: right-edge alignment doesn't
    // need to know that width up front the way left-edge placement would.
    final estimatedHeight = widget.actions.length * 48.0 + 16;

    final right =
        (screenSize.width - (widget.anchor.dx + widget.anchorSize.width))
            .clamp(12.0, screenSize.width - 12.0);

    double top = widget.anchor.dy + widget.anchorSize.height + 8;
    if (top + estimatedHeight > screenSize.height - 24) {
      // Not enough room below the button — open upward instead.
      top = widget.anchor.dy - estimatedHeight - 8;
    }

    // The button lives in the page below this overlay, at the same screen
    // rect as [widget.anchor]/[widget.anchorSize]. A naive full-screen
    // GestureDetector here would sit on top of that button in the Overlay's
    // z-order and swallow every tap on it — including the tap meant to
    // close the menu via the button itself — so it never reaches the
    // button's own GestureDetector (no press feedback, and the wrong
    // "outside tap" bounce plays instead of the button's tap-release one).
    // Carving a hole over the button's rect (tap-through, not hit-tested
    // here) lets that tap fall through to the real button underneath, while
    // every other point on screen still dismisses on tap. The visual blur
    // stays a single full-screen, non-interactive layer so there's no seam.
    final holeLeft = widget.anchor.dx.clamp(0.0, screenSize.width);
    final holeTop = widget.anchor.dy.clamp(0.0, screenSize.height);
    final holeRight = (holeLeft + widget.anchorSize.width).clamp(
      0.0,
      screenSize.width,
    );
    final holeBottom = (holeTop + widget.anchorSize.height).clamp(
      0.0,
      screenSize.height,
    );

    Widget dismissRegion() => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => dismiss(),
        );

    return Stack(
      children: [
        // Full-screen barrier: blurs the page behind the menu, fading in
        // lock-step with the menu's pop-in. Purely visual — see the hole
        // note above for why hit-testing is handled separately below.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value.clamp(0.0, 1.0);
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3 * t, sigmaY: 3 * t),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.08 * t),
                  ),
                );
              },
            ),
          ),
        ),
        // Dismiss-on-tap-outside hit region, tiled around the button's rect.
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: holeTop,
          child: dismissRegion(),
        ),
        Positioned(
          left: 0,
          top: holeBottom,
          right: 0,
          bottom: 0,
          child: dismissRegion(),
        ),
        Positioned(
          left: 0,
          top: holeTop,
          width: holeLeft,
          height: holeBottom - holeTop,
          child: dismissRegion(),
        ),
        Positioned(
          left: holeRight,
          top: holeTop,
          right: 0,
          height: holeBottom - holeTop,
          child: dismissRegion(),
        ),
        Positioned(
          right: right,
          top: top,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _controller.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  // Scaling from the corner nearest the button — rather than
                  // the card's center — sells the illusion that the menu is
                  // growing directly out of the button that spawned it.
                  alignment: Alignment.topRight,
                  scale: _controller.value,
                  child: child,
                ),
              );
            },
            // menuWidth is a cap here, not a fixed width — the card shrinks
            // to fit its widest row otherwise (see _MenuCard).
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: style.menuWidth),
              child: _MenuCard(
                actions: widget.actions,
                style: style,
                isDark: isDark,
                onSelect: (action) => dismiss(andThen: action.onTap),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The rounded, frosted-glass menu surface itself.
class _MenuCard extends StatelessWidget {
  final List<SpringPulldownMenuAction> actions;
  final SpringPulldownMenuStyle style;
  final bool isDark;
  final ValueChanged<SpringPulldownMenuAction> onSelect;

  const _MenuCard({
    required this.actions,
    required this.style,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = (isDark ? style.darkFillColor : style.lightFillColor) ??
        (isDark
            ? const Color(0xFF2C2C2E).withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.78));
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final labelColor = isDark ? Colors.white : Colors.black87;
    final radius = BorderRadius.circular(style.cornerRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: style.blurSigma,
          sigmaY: style.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: radius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // IntrinsicWidth + CrossAxisAlignment.stretch, rather than a plain
          // min-size Column: a plain Column sizes to its widest child, but
          // Divider self-expands to fill whatever width it's *offered*
          // regardless of the other rows' actual content — it would report
          // back the full incoming (capped) width even for a menu of two
          // short rows, forcing the menu wide again. IntrinsicWidth measures
          // every row's true content width first, so the dividers stretch
          // to match the *rows*, not the other way around. The outer
          // ConstrainedBox (see the overlay's Positioned) still bounds how
          // wide that resolved value is allowed to be.
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 0.6, color: dividerColor),
                  _MenuRow(
                    action: actions[i],
                    labelColor: actions[i].isDestructive
                        ? style.destructiveColor
                        : labelColor,
                    enableHaptics: style.enableHaptics,
                    iconAffinity: style.iconAffinity,
                    labelTextStyle: style.labelTextStyle,
                    onTap: () => onSelect(actions[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  final SpringPulldownMenuAction action;
  final Color labelColor;
  final bool enableHaptics;
  final SpringPulldownMenuIconAffinity iconAffinity;
  final TextStyle? labelTextStyle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.action,
    required this.labelColor,
    required this.enableHaptics,
    required this.iconAffinity,
    required this.labelTextStyle,
    required this.onTap,
  });

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  // Set once and never reset: the menu (and this row with it) is gone within
  // one dismiss animation of a tap landing, so there's no "un-highlight" to
  // animate back to — real UIKit pull-down menus flash the tapped row solid
  // for exactly that window before closing, distinct from InkWell's own
  // brief, fading tap ripple.
  bool _selected = false;

  void _handleTap() {
    if (widget.enableHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = true);
    widget.onTap();
  }

  // Apple's own pull-downs keep a small fixed gap between icon and label,
  // with any slack falling elsewhere — not a spaceBetween-style gap that
  // grows with the menu's width.
  static const _rowGap = SizedBox(width: 12);

  Widget _rowIcon() {
    return Icon(widget.action.icon, size: 19, color: widget.labelColor);
  }

  // Flexible with FlexFit.loose (the default) — deliberately NOT Expanded.
  // Expanded forces the label's box to consume its entire allocated share of
  // the row's width even when the text itself is shorter, which is invisible
  // when the label is the LAST widget in the row (iconAffinity.leading) but
  // reintroduces the exact "two disconnected columns" gap this exists to fix
  // when the label comes FIRST (iconAffinity.trailing, the default): a short
  // label would still force the icon after it out to the row's far edge.
  // Flexible lets the label shrink to its own text width whenever the row
  // isn't already exactly that wide, so the icon stays snug against it in
  // both orderings, and it still caps + ellipsizes via the same mechanism
  // when the label doesn't fit.
  Widget _rowLabel() {
    // .merge, not a plain override: a caller who only sets e.g. fontWeight
    // in labelTextStyle should still get the destructive/dark-mode color
    // already computed into labelColor, not lose it.
    final baseStyle = TextStyle(fontSize: 16, color: widget.labelColor);
    return Flexible(
      child: Text(
        widget.action.label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: baseStyle.merge(widget.labelTextStyle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFill = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    return Semantics(
      button: true,
      label: widget.action.label,
      excludeSemantics: true,
      child: Material(
        color: _selected ? selectedFill : Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              // Row lays its children out start-to-end per the ambient
              // Directionality, so simply choosing which end the icon goes
              // on below is enough to flip correctly under RTL — no manual
              // left/right handling needed.
              children:
                  widget.iconAffinity == SpringPulldownMenuIconAffinity.leading
                      ? [_rowIcon(), _rowGap, _rowLabel()]
                      : [_rowLabel(), _rowGap, _rowIcon()],
            ),
          ),
        ),
      ),
    );
  }
}
