import 'package:flutter/material.dart';

import '../l10n.dart';
import '../state/app_controller.dart';
import 'clash_page.dart';
import 'help_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'widgets/role_badge.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pages = [
      HomePage(controller: c),
      ClashPage(controller: c),
      SettingsPage(controller: c),
      const HelpPage(),
    ];
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: S.home),
      NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub_rounded), label: S.clash),
      NavigationDestination(icon: Icon(Icons.tune), selectedIcon: Icon(Icons.tune), label: S.settings),
      NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: S.help),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final body = pages[index];
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text(S.home)),
                NavigationRailDestination(icon: Icon(Icons.hub_outlined), label: Text(S.clash)),
                NavigationRailDestination(icon: Icon(Icons.tune), label: Text(S.settings)),
                NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), label: Text(S.help)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(controller: c),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('${S.appName}  ·  ${S.appNameEn}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: RoleBadge(role: c.settings.role, compact: true)),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: destinations,
        onDestinationSelected: (i) => setState(() => index = i),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Text(
              '${S.appName}  ·  ${S.appNameEn}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            RoleBadge(role: controller.settings.role, compact: true),
            if (controller.busy) ...[
              const SizedBox(width: 12),
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
      ),
    );
  }
}
