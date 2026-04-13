import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'auth_form_sections.dart';

enum AuthScreenMode { login, register }

class AuthPageShell extends StatelessWidget {
  final AuthScreenMode mode;
  final bool compact;
  final double keyboardInset;
  final Animation<double>? heroScale;
  final Animation<double>? heroLift;
  final double heroHeightFactor;
  final String heroTitle;
  final String heroDescription;
  final Widget form;
  final Widget primaryAction;
  final Widget agreement;
  final Widget? footer;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const AuthPageShell({
    super.key,
    required this.mode,
    required this.compact,
    required this.keyboardInset,
    required this.heroTitle,
    required this.heroDescription,
    required this.form,
    required this.primaryAction,
    required this.agreement,
    required this.onLoginTap,
    required this.onRegisterTap,
    this.heroHeightFactor = 1,
    this.footer,
    this.heroScale,
    this.heroLift,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardVisible = keyboardInset > 0;
    final topPadding = mediaQuery.padding.top;
    final bottomSafeArea = mediaQuery.padding.bottom;
    final isRegister = mode == AuthScreenMode.register;
    final baseHeroHeight = keyboardVisible
        ? 148.0
        : compact
            ? 224.0
            : 286.0;
    final heroHeight = baseHeroHeight * heroHeightFactor;
    final panelTopPadding = isRegister ? AppSpacing.base : AppSpacing.lg;
    final formSectionSpacing = isRegister ? AppSpacing.lg : AppSpacing.xl;
    final bottomPadding = keyboardVisible
        ? keyboardInset + AppSpacing.lg
        : bottomSafeArea + (isRegister ? AppSpacing.lg : AppSpacing.xl);
    final footerBottomSpacing = isRegister ? AppSpacing.base : AppSpacing.lg;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: heroHeight + topPadding,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                topPadding + (keyboardVisible ? AppSpacing.md : AppSpacing.xl),
                AppSpacing.xl,
                keyboardVisible ? AppSpacing.md : AppSpacing.lg,
              ),
              child: AuthBrandHero(
                compact: compact,
                keyboardVisible: keyboardVisible,
                scale: heroScale,
                lift: heroLift,
                title: heroTitle,
                description: heroDescription,
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(17, 24, 39, 0.07),
                      blurRadius: 28,
                      offset: Offset(0, -12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      panelTopPadding,
                      AppSpacing.lg,
                      bottomPadding,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 392),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthModeSwitcher(
                              mode: mode,
                              onLoginTap: onLoginTap,
                              onRegisterTap: onRegisterTap,
                            ),
                            SizedBox(height: formSectionSpacing),
                            form,
                            SizedBox(height: formSectionSpacing),
                            primaryAction,
                            const SizedBox(height: AppSpacing.base),
                            agreement,
                            if (footer != null) ...[
                              const SizedBox(height: AppSpacing.base),
                              footer!,
                            ],
                            SizedBox(height: footerBottomSpacing),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthModeSwitcher extends StatelessWidget {
  final AuthScreenMode mode;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const AuthModeSwitcher({
    super.key,
    required this.mode,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthModeSegment(
              label: '登录',
              selected: mode == AuthScreenMode.login,
              onTap: onLoginTap,
            ),
          ),
          Expanded(
            child: _AuthModeSegment(
              label: '注册',
              selected: mode == AuthScreenMode.register,
              onTap: onRegisterTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AuthModeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? AppColors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: selected ? AppColors.white : AppColors.gray500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AuthBrandHero extends StatelessWidget {
  final bool compact;
  final bool keyboardVisible;
  final Animation<double>? scale;
  final Animation<double>? lift;
  final String title;
  final String description;

  const AuthBrandHero({
    super.key,
    required this.compact,
    required this.keyboardVisible,
    required this.title,
    required this.description,
    this.scale,
    this.lift,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tightHero =
            !keyboardVisible && constraints.maxHeight < (compact ? 172 : 210);
        final ultraTightHero =
            !keyboardVisible && constraints.maxHeight < (compact ? 164 : 194);
        final logoSize = keyboardVisible
            ? 104.0
            : compact
                ? (tightHero ? 124.0 : 136.0)
                : (tightHero ? 148.0 : 164.0);
        final titleSpacing = keyboardVisible
            ? AppSpacing.sm
            : (tightHero ? 2.0 : AppSpacing.base);
        final descriptionSpacing =
            tightHero ? 4.0 : (compact ? AppSpacing.sm : AppSpacing.md);
        final showDescription = !keyboardVisible && !ultraTightHero;
        final titleStyle = AppTextStyles.onboardingTitle.copyWith(
          fontSize: keyboardVisible
              ? 24
              : compact
                  ? (tightHero ? 28 : 30)
                  : (tightHero ? 34 : 38),
          height: 1,
          letterSpacing: -1.2,
          color: AppColors.black,
        );

        return Row(
          crossAxisAlignment: keyboardVisible
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthMetaBar(),
                  SizedBox(height: titleSpacing),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  if (showDescription) ...[
                    SizedBox(height: descriptionSpacing),
                    Text(
                      description,
                      maxLines: tightHero ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.gray500,
                        height: compact ? 1.42 : 1.55,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: keyboardVisible ? AppSpacing.md : AppSpacing.base),
            Expanded(
              flex: 9,
              child: Align(
                alignment: keyboardVisible
                    ? Alignment.centerRight
                    : Alignment.bottomRight,
                child: _AuthLogoStage(
                  size: logoSize,
                  scale: scale,
                  lift: lift,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AuthLogoStage extends StatelessWidget {
  final double size;
  final Animation<double>? scale;
  final Animation<double>? lift;

  const _AuthLogoStage({
    required this.size,
    this.scale,
    this.lift,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/branding/auth_logo_transparent.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );

    Widget animatedLogo = logo;
    if (scale != null && lift != null) {
      animatedLogo = AnimatedBuilder(
        animation: Listenable.merge([scale!, lift!]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, lift!.value),
            child: Transform.scale(scale: scale!.value, child: child),
          );
        },
        child: logo,
      );
    }

    return SizedBox(
      width: size + 28,
      height: size + 36,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size + 14,
            height: size + 14,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.info.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.56, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: size * 0.7,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.12),
                    blurRadius: 26,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          animatedLogo,
        ],
      ),
    );
  }
}
