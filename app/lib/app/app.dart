import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import '../shared/widgets/network_status_bar.dart';

class VccApp extends ConsumerWidget {
  const VccApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '开造 VCC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      builder: (context, child) {
        // 限制最大字体缩放倍数为1.3
        final mediaQueryData = MediaQuery.of(context);
        final scale = mediaQueryData.textScaler.scale(1).clamp(0.8, 1.3);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: NetworkStatusBar(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
