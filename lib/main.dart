import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'AI Stylist Agent',
      theme: AppTheme.darkTheme,
      scrollBehavior: AppScrollBehavior(),
      home: authState.isAuthenticated
          ? const MainWrapper()
          : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
