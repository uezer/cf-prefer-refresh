import 'package:flutter/material.dart';

import 'l10n.dart';
import 'state/app_controller.dart';
import 'theme.dart';
import 'ui/shell.dart';

class CfPreferApp extends StatelessWidget {
  const CfPreferApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: '${S.appName} · ${S.appNameEn}',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          home: controller.loaded
              ? AppShell(controller: controller)
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }
}
