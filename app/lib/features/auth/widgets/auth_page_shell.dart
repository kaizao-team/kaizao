import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'auth_form_sections.dart';

class AuthPageShell extends StatelessWidget {
  final bool compact;
  final double keyboardInset;
  final Animation<double>? heroScale;
  final Animation<double>? heroLift;
  final String heroSubtitle;
  final Widget form;
  final Widget primaryAction;
  final Widget agreement;
  final Widget footer;

  const AuthPageShell({
    super.key,
    required this.compact,
    required this.keyboardInset,
    required this.form,
    required this.primaryAction,
    required this.agreement,
    required this.footer,
    this.heroScale,
    this.heroLift,
    this.heroSubtitle = 'KAIZO，连接新的生产力',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 392),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        bottom: keyboardInset > 0 ? AppSpacing.lg : 0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: compact ? AppSpacing.sm : AppSpacing.md,
                            ),
                            const AuthMetaBar(),
                            SizedBox(height: compact ? 32 : 52),
                            AuthBrandHero(
                              compact: compact,
                              scale: heroScale,
                              lift: heroLift,
                              subtitle: heroSubtitle,
                            ),
                            SizedBox(
                              height: compact ? AppSpacing.xl : AppSpacing.xxxl,
                            ),
                            form,
                            SizedBox(
                              height: keyboardInset > 0
                                  ? AppSpacing.xl
                                  : (compact ? AppSpacing.xxl : 48),
                            ),
                            primaryAction,
                            const SizedBox(height: AppSpacing.base),
                            agreement,
                            const SizedBox(height: AppSpacing.md),
                            footer,
                            SizedBox(
                              height: keyboardInset > 0
                                  ? AppSpacing.xl
                                  : AppSpacing.lg,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
