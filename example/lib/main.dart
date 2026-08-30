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
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
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
      home: TodayScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

/// The button sitting where it would in a real app — top-right of an app
/// bar over a list of content.
class TodayScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback? onToggleTheme;

  const TodayScreen({super.key, this.isDarkMode = false, this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          if (onToggleTheme != null)
            IconButton(
              onPressed: onToggleTheme,
              icon: Icon(isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon),
              tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            ),
          SpringPulldownMenuButton(
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
      body: ListView.separated(
        // Keyed on brightness so the list rebuilds cleanly on a theme flip
        // instead of intermittently holding the old ColorScheme.
        key: ValueKey(Theme.of(context).brightness),
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Habit ${index + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        },
      ),
    );
  }
}
