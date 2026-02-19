import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownyourday/core/theme/app_colors.dart';
import 'package:ownyourday/features/capture/presentation/capture_screen.dart';
import 'package:ownyourday/features/focus/presentation/focus_screen.dart';
import 'package:ownyourday/features/insights/presentation/insights_screen.dart';
import 'package:ownyourday/features/settings/presentation/settings_screen.dart';
import 'package:ownyourday/features/tasks/presentation/today_screen.dart';
import 'package:ownyourday/state/providers.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Plan',
    ),
    _NavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search,
      label: 'Capture',
    ),
    _NavItem(
      icon: Icons.timelapse_outlined,
      activeIcon: Icons.timelapse,
      label: 'Focus',
    ),
    _NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Insights',
    ),
  ];

  late final AnimationController _fadeController;
  int _renderedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    if (app.tabIndex != _renderedIndex) {
      _renderedIndex = app.tabIndex;
      _fadeController.forward(from: 0.0);
    }

    final pages = <Widget>[
      TodayScreen(
        onOpenSettings: () {
          Navigator.of(context).push(_fadeRoute(const SettingsScreen()));
        },
      ),
      const CaptureScreen(),
      const FocusScreen(),
      const InsightsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? const <Color>[Color(0xFF08090F), Color(0xFF120F22)]
                      : const <Color>[Color(0xFFF7F3EE), Color(0xFFF5F2FA)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeInOut,
              ),
              child: IndexedStack(index: app.tabIndex, children: pages),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Container(
            height: 84,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF12131B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List<Widget>.generate(_items.length, (index) {
                      final item = _items[index];
                      final active = app.tabIndex == index;

                      return InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () =>
                            ref.read(appControllerProvider).setTab(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: active
                                ? AppColors.lavender.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                active ? item.activeIcon : item.icon,
                                color: active ? AppColors.lavender : null,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active ? AppColors.lavender : null,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: <Color>[AppColors.lavender, Color(0xFF5E4AB4)],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PageRouteBuilder<void> _fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
