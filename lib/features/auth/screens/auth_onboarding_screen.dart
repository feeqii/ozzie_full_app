import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/theme/onboarding_tokens.dart';
import '../../onboarding/ui/onboarding_button.dart';
import '../../onboarding/ui/onboarding_hero_tile.dart';
import '../../onboarding/ui/onboarding_scaffold.dart';
import '../../onboarding/ui/onboarding_theme_toggle.dart';

class AuthOnboardingScreen extends StatefulWidget {
  const AuthOnboardingScreen({super.key});

  @override
  State<AuthOnboardingScreen> createState() => _AuthOnboardingScreenState();
}

class _AuthOnboardingScreenState extends State<AuthOnboardingScreen> {
  static final List<_SlideData> _slides = [
    _SlideData(
      title: 'A warm start for every recitation',
      description:
          'Ozzie helps your child build a joyful, steady Quran rhythm with short sessions that feel achievable each day.',
      icon: Icons.auto_stories_rounded,
      accent: OnboardingPalette.orange,
      highlights: [
        'Small daily wins, not pressure',
        'Clear guidance for each session',
      ],
    ),
    _SlideData(
      title: 'Designed for focus and consistency',
      description:
          'Practice is structured in a calm flow so attention stays on understanding, memory, and confident recitation.',
      icon: Icons.track_changes_rounded,
      accent: OnboardingPalette.blue,
      highlights: [
        'Friendly pacing from first verses onward',
        'Progress your family can actually feel',
      ],
    ),
    _SlideData(
      title: 'Parents stay in control',
      description:
          'Secure parent access and child profiles keep the experience safe, simple, and tailored to your household.',
      icon: Icons.family_restroom_rounded,
      accent: OnboardingPalette.green,
      highlights: [
        'Private parent PIN access',
        'Child profiles and guided setup',
      ],
    ),
  ];

  final PageController _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index == _slides.length - 1) {
      if (!mounted) {
        return;
      }
      context.go('/auth/entry');
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _previous() async {
    if (_index == 0) {
      return;
    }
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return OnboardingScaffold(
      trailing: const OnboardingThemeToggle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: index == _index ? 1 : 0.82,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: OnboardingSpacing.md,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _HeroOrb(icon: slide.icon, accent: slide.accent),
                              const SizedBox(height: OnboardingSpacing.xl),
                              Text(
                                slide.title,
                                style: OnboardingTypography.display(
                                  colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: OnboardingSpacing.md),
                              Text(
                                slide.description,
                                style: OnboardingTypography.body(
                                  colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: OnboardingSpacing.lg),
                              ...slide.highlights.map(
                                (text) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: OnboardingSpacing.sm,
                                  ),
                                  child: OnboardingHeroTile(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: text,
                                    accent: slide.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: OnboardingSpacing.sm),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (dotIndex) {
              final selected = dotIndex == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
          const SizedBox(height: OnboardingSpacing.lg),
          OnboardingButton(
            label: _index == _slides.length - 1 ? 'Get Started' : 'Next',
            onPressed: _next,
          ),
          const SizedBox(height: OnboardingSpacing.xs),
          if (_index > 0)
            OnboardingButton(
              label: 'Back',
              variant: OnboardingButtonVariant.text,
              onPressed: _previous,
            )
          else
            const SizedBox(height: 36),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Align(
      child: Container(
        width: 124,
        height: 124,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.88), colors.surfaceMuted],
          ),
          border: Border.all(color: colors.border, width: 1.2),
        ),
        child: Icon(icon, color: colors.textPrimary, size: 44),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.highlights,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<String> highlights;
}
