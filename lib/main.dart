import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/main_shell.dart';
import 'theme/app_theme.dart';

export 'services/app_signals.dart';
export 'theme/app_theme.dart';

const String appVersion = '7.0.2';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = ThemeController();
  await controller.load();
  runApp(ThemeState(controller: controller, child: const RecompApp()));
}

class ThemeState extends StatefulWidget {
  final Widget child;
  final ThemeController? controller;
  const ThemeState({super.key, required this.child, this.controller});

  @override
  State<ThemeState> createState() => _ThemeStateState();
}

class _ThemeStateState extends State<ThemeState> {
  late final ThemeController _controller =
      widget.controller ?? ThemeController();
  late final bool _ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    if (_ownsController) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(controller: _controller, child: widget.child);
  }
}

class RecompApp extends StatelessWidget {
  const RecompApp({super.key});

  static ThemeData themeFor(AppTheme mode) => buildThemeData(mode);

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.maybeOf(context);
    final mode = controller?.current ?? AppTheme.blue;
    return MaterialApp(
      title: '青燃',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: themeFor(mode),
      home: const MainShell(appVersion: appVersion),
    );
  }
}
