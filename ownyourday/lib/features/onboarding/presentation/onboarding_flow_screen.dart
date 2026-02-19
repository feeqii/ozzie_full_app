import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownyourday/core/theme/app_colors.dart';
import 'package:ownyourday/state/providers.dart';
import 'package:ownyourday/shared/widgets/illustration_placeholder.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < 3) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutQuart,
      );
      return;
    }

    await ref.read(appControllerProvider).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = ref.watch(appControllerProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? const <Color>[Color(0xFF0B0D14), Color(0xFF181229)]
                : const <Color>[Color(0xFFF7F3EE), Color(0xFFEEE7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: <Widget>[
                    _IntroSplash(onContinue: _next),
                    _WelcomePage(onContinue: _next),
                    _MockLoginPage(
                      onContinue: () async {
                        await app.completeMockLogin();
                        await _next();
                      },
                    ),
                    _NotificationPage(onContinue: _next),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    4,
                    (dot) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _index == dot ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _index == dot
                            ? AppColors.lavender
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.22,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroSplash extends StatelessWidget {
  const _IntroSplash({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Spacer(flex: 2),
          Center(child: _OydMark(size: 130)),
          const SizedBox(height: 30),
          Text(
            'Own your day',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your day planner that reaches out before things slip.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const Spacer(flex: 3),
          _PrimaryPillButton(text: 'Start setup', onPressed: onContinue),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 24),
          Text(
            'Own your day',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The app comes to you with smart, gentle nudges built around what matters.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 26),
          const IllustrationPlaceholder(
            title: 'Foundational hero illustration',
            note:
                'Direction: playful character holding a circular timer + floating task shapes in pastel lavender and peach.',
            height: 330,
          ),
          const Spacer(),
          _PrimaryPillButton(text: 'Make it happen', onPressed: onContinue),
        ],
      ),
    );
  }
}

class _MockLoginPage extends StatelessWidget {
  const _MockLoginPage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 20),
          Text(
            'Mock login (MVP)',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Authentication is intentionally mocked for sprint one. Real auth can replace this screen without changing navigation.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          _PrimaryPillButton(
            text: 'Continue with Apple (mock)',
            icon: Icons.apple,
            onPressed: onContinue,
          ),
          const SizedBox(height: 12),
          _OutlinedPillButton(
            text: 'Continue with email (mock)',
            onPressed: onContinue,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: theme.colorScheme.surface.withValues(alpha: 0.55),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              'Note: login persistence is local-only for this MVP.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Spacer(),
          Text(
            'By continuing, you agree to the MVP privacy and terms placeholders.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NotificationPage extends ConsumerWidget {
  const _NotificationPage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final app = ref.watch(appControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 18),
          Text(
            'Set your gentle nudges',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'OYD will suggest reminder timing and keep it calm. No alarm spam.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Morning check-in',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text('8:00 AM → 8:30 AM', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 6),
                Text(
                  'Placeholder logic: AI can personalize this by usage patterns in later sprints.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SwitchListTile.adaptive(
            value: app.settings.notificationsEnabled,
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable smart notifications'),
            subtitle: const Text('Gentle nudges + one follow-up only'),
            onChanged: (value) {
              ref.read(appControllerProvider).setNotificationsEnabled(value);
            },
          ),
          const Spacer(),
          _PrimaryPillButton(text: 'Enter Own Your Day', onPressed: onContinue),
        ],
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 24),
        label: Text(text),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFF2F2F2)
              : const Color(0xFF131518),
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF11131A)
              : Colors.white,
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.25),
            width: 1.6,
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Text(text),
      ),
    );
  }
}

class _OydMark extends StatelessWidget {
  const _OydMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: const Alignment(-0.2, -0.25),
            child: Container(
              width: size * 0.43,
              height: size * 0.43,
              decoration: const BoxDecoration(
                color: AppColors.blush,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.2, -0.25),
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.18, 0.25),
            child: Container(
              width: size * 0.54,
              height: size * 0.54,
              decoration: const BoxDecoration(
                color: Color(0xFFD9DDF6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.2, 0.25),
            child: Container(
              width: size * 0.54,
              height: size * 0.54,
              decoration: const BoxDecoration(
                color: Color(0xFF8E78E6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
