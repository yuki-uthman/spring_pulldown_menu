import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spring_pulldown_menu/spring_pulldown_menu.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpringPulldownMenuButton Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: PlaygroundScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

/// Interactive playground for the bounce/distance style knobs — the button
/// sits where it would in a real app (top-right of an app bar), and each
/// slider below rebuilds it live with a new [SpringPulldownMenuStyle] so you
/// can feel each parameter's effect immediately, no recompiling needed.
class PlaygroundScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onToggleTheme;

  const PlaygroundScreen({
    super.key,
    this.isDarkMode = false,
    this.onToggleTheme,
  });

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  static const _defaults = SpringPulldownMenuStyle();

  // buttonDampingRatio/menuDampingRatio default to null ("use buttonSpring's
  // own damping as given") — there's no single numeric "default" to show on
  // a slider, so these sliders start at whatever ratio the default springs
  // already imply (damping / (2 * sqrt(mass * stiffness))), computed once
  // below, so "Default" visually means "the built-in feel," not an
  // arbitrary number.
  static double _impliedDampingRatio(SpringDescription spring) =>
      spring.damping / (2 * math.sqrt(spring.mass * spring.stiffness));

  static final double _defaultButtonDampingRatio = _impliedDampingRatio(
    _defaults.buttonSpring,
  );
  static final double _defaultMenuDampingRatio = _impliedDampingRatio(
    _defaults.menuPopSpring,
  );

  double _buttonPressScale = _defaults.buttonPressScale;
  double _buttonBounceScale = _defaults.buttonBounceScale;
  double _buttonImpactBounceIntensity = _defaults.buttonImpactBounceIntensity;
  double _buttonLeanDistance = _defaults.buttonLeanDistance;
  double _menuBounceScale = _defaults.menuBounceScale;
  late double _buttonDampingRatio = _defaultButtonDampingRatio;
  late double _menuDampingRatio = _defaultMenuDampingRatio;

  void _reset() {
    setState(() {
      _buttonPressScale = _defaults.buttonPressScale;
      _buttonBounceScale = _defaults.buttonBounceScale;
      _buttonImpactBounceIntensity = _defaults.buttonImpactBounceIntensity;
      _buttonLeanDistance = _defaults.buttonLeanDistance;
      _menuBounceScale = _defaults.menuBounceScale;
      _buttonDampingRatio = _defaultButtonDampingRatio;
      _menuDampingRatio = _defaultMenuDampingRatio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = SpringPulldownMenuStyle(
      buttonPressScale: _buttonPressScale,
      buttonBounceScale: _buttonBounceScale,
      buttonImpactBounceIntensity: _buttonImpactBounceIntensity,
      buttonLeanDistance: _buttonLeanDistance,
      menuBounceScale: _menuBounceScale,
      buttonDampingRatio: _buttonDampingRatio,
      menuDampingRatio: _menuDampingRatio,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bounce Playground'),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              onPressed: widget.onToggleTheme,
              icon: Icon(
                widget.isDarkMode
                    ? CupertinoIcons.sun_max
                    : CupertinoIcons.moon,
              ),
              tooltip: widget.isDarkMode
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',
            ),
          SpringPulldownMenuButton(
            style: style,
            actions: [
              SpringPulldownMenuAction(
                label: 'Mark all complete',
                icon: CupertinoIcons.checkmark_alt,
                onTap: () {},
              ),
              SpringPulldownMenuAction(
                label: 'Reminders',
                icon: CupertinoIcons.bell,
                onTap: () {},
              ),
              SpringPulldownMenuAction(
                label: 'Edit list',
                icon: CupertinoIcons.pencil,
                onTap: () {},
              ),
              SpringPulldownMenuAction(
                label: 'Delete',
                icon: CupertinoIcons.trash,
                isDestructive: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        key: ValueKey(Theme.of(context).brightness),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'Press and hold the "..." button above to feel the press-in + '
            'lean. Release to feel the tap bounce. Tap outside the popup '
            '(or pick an action) to feel the gentler "impact" bounce. '
            'Reopen it to see the pop-in peak.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 24),
          _Knob(
            label: 'buttonPressScale',
            subtitle: 'How far the button shrinks on press-in.',
            value: _buttonPressScale,
            min: 0.3,
            max: 1.0,
            defaultValue: _defaults.buttonPressScale,
            onChanged: (v) => setState(() => _buttonPressScale = v),
          ),
          _Knob(
            label: 'buttonBounceScale',
            subtitle: "Peak of the button's own tap-release bounce.",
            value: _buttonBounceScale,
            min: 1.0,
            max: 1.6,
            defaultValue: _defaults.buttonBounceScale,
            onChanged: (v) => setState(() => _buttonBounceScale = v),
          ),
          _Knob(
            label: 'buttonImpactBounceIntensity',
            subtitle: 'Gentler bounce when the menu closes some other way. '
                '0 disables it.',
            value: _buttonImpactBounceIntensity,
            min: 0.0,
            max: 3.0,
            defaultValue: _defaults.buttonImpactBounceIntensity,
            onChanged: (v) => setState(() => _buttonImpactBounceIntensity = v),
          ),
          _Knob(
            label: 'buttonLeanDistance',
            subtitle: 'How far the button leans toward your touch. '
                '0 disables the lean.',
            value: _buttonLeanDistance,
            min: 0.0,
            max: 60.0,
            defaultValue: _defaults.buttonLeanDistance,
            onChanged: (v) => setState(() => _buttonLeanDistance = v),
          ),
          _Knob(
            label: 'menuBounceScale',
            subtitle: "Peak of the floating menu's own pop-in.",
            value: _menuBounceScale,
            min: 1.0,
            max: 1.6,
            defaultValue: _defaults.menuBounceScale,
            onChanged: (v) => setState(() => _menuBounceScale = v),
          ),
          _Knob(
            label: 'buttonDampingRatio',
            subtitle: 'How many times the button oscillates before holding '
                'still — independent of the peak above. Low = bounces '
                'several times; 1.0 = pops and holds with no bounce; high '
                '= settles slowly with no bounce either.',
            value: _buttonDampingRatio,
            min: 0.05,
            max: 1.5,
            defaultValue: _defaultButtonDampingRatio,
            onChanged: (v) => setState(() => _buttonDampingRatio = v),
          ),
          _Knob(
            label: 'menuDampingRatio',
            subtitle: "Same idea, for the floating menu's own pop-in.",
            value: _menuDampingRatio,
            min: 0.05,
            max: 1.5,
            defaultValue: _defaultMenuDampingRatio,
            onChanged: (v) => setState(() => _menuDampingRatio = v),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(CupertinoIcons.arrow_counterclockwise),
              label: const Text('Reset to defaults'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  final String label;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final ValueChanged<double> onChanged;

  const _Knob({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 0.02).round(),
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onChanged(defaultValue),
              child: Text('Default: ${defaultValue.toStringAsFixed(2)}'),
            ),
          ),
        ],
      ),
    );
  }
}
