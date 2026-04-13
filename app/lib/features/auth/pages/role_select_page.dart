import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';

/// FE-AUTH-006: 角色选择页 — 项目方 / 团队方
class RoleSelectPage extends ConsumerStatefulWidget {
  const RoleSelectPage({super.key});

  @override
  ConsumerState<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends ConsumerState<RoleSelectPage> {
  int? _selectedRole;

  Future<void> _confirm() async {
    if (_selectedRole == null) {
      VccToast.show(context, message: '请选择一个角色', type: VccToastType.warning);
      return;
    }

    final success =
        await ref.read(authStateProvider.notifier).selectRole(_selectedRole!);
    if (success && mounted) {
      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      if (_selectedRole == 1) {
        await onboardingNotifier.setRole(OnboardingRole.demander);
        if (mounted) context.go(RoutePaths.demanderOnboarding1);
      } else {
        await onboardingNotifier.setRole(OnboardingRole.expert);
        if (mounted) context.go(RoutePaths.expertOnboarding1);
      }
    }
  }

  String get _headlineBody {
    switch (_selectedRole) {
      case 1:
        return '你会先进入项目路径，把想法、预算和方向整理成一份能继续往前推的项目摘要。';
      case 2:
        return '你会先进入团队路径，把能力、案例和协作方式整理成一份方便接项目的团队资料。';
      default:
        return '先选一个更顺手的入口，后面的步骤会顺着接上。';
    }
  }

  String get _buttonText {
    switch (_selectedRole) {
      case 1:
        return '以项目方身份继续';
      case 2:
        return '以团队方身份继续';
      default:
        return '选好继续';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;
    final viewportHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;
    final compactLayout = viewportHeight < 820;
    final ctaButton = VccButton(
      text: _buttonText,
      onPressed: _selectedRole != null ? _confirm : null,
      isLoading: isLoading,
      icon: _selectedRole == null ? null : Icons.arrow_forward_rounded,
    );

    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _RoleSelectionBackdrop()),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      compactLayout ? 12 : 14,
                      24,
                      compactLayout ? 20 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'KAIZO',
                              style: AppTextStyles.onboardingWordmark,
                            ),
                            const Spacer(),
                            _RolePageStatus(selectedRole: _selectedRole),
                          ],
                        ),
                        SizedBox(height: compactLayout ? 24 : 28),
                        Text(
                          '你想怎样进入 KAIZO',
                          style: AppTextStyles.onboardingTitle.copyWith(
                            fontSize: compactLayout ? 35 : 36,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: AppCurves.standard,
                          switchOutCurve: AppCurves.standard,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _headlineBody,
                            key: ValueKey(_headlineBody),
                            style: AppTextStyles.onboardingBody.copyWith(
                              height: 1.55,
                            ),
                          ),
                        ),
                        SizedBox(height: compactLayout ? 26 : 30),
                        _PaperRoleBranch(
                          serial: '01',
                          title: '我是项目方',
                          titleTag: '发布路径',
                          shortDescription: '带着想法、目标和预算进来。',
                          expandedDescription:
                              '先定方向，再把项目要点说清，后面就会把你带到更合适的团队那边。',
                          icon: Icons.wb_incandescent_outlined,
                          pathLabel: '项目方路径',
                          steps: const ['创建项目', '整理摘要', '匹配团队'],
                          isSelected: _selectedRole == 1,
                          onTap: () => setState(() => _selectedRole = 1),
                        ),
                        SizedBox(height: compactLayout ? 14 : 16),
                        _PaperRoleBranch(
                          serial: '02',
                          title: '我是团队方',
                          titleTag: '建档路径',
                          shortDescription: '带着能力、案例和协作方式进来。',
                          expandedDescription:
                              '先把团队资料立起来，再把能力、案例和协作节奏整理成更好接项目的入口。',
                          icon: Icons.code_rounded,
                          pathLabel: '团队方路径',
                          steps: const ['展示能力', '补案例', '开始接单'],
                          isSelected: _selectedRole == 2,
                          onTap: () => setState(() => _selectedRole = 2),
                        ),
                      ],
                    ),
                  ),
                ),
                _RolePageBottomBar(child: ctaButton),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePageStatus extends StatelessWidget {
  final int? selectedRole;

  const _RolePageStatus({required this.selectedRole});

  @override
  Widget build(BuildContext context) {
    final locked = selectedRole != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: locked ? AppColors.black : AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: locked ? AppColors.black : AppColors.onboardingHairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: AppCurves.standard,
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: locked ? AppColors.white : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            locked ? '入口已就位' : '等你定方向',
            style: AppTextStyles.caption.copyWith(
              color: locked ? AppColors.white : AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperRoleBranch extends StatelessWidget {
  final String serial;
  final String title;
  final String titleTag;
  final String shortDescription;
  final String expandedDescription;
  final IconData icon;
  final String pathLabel;
  final List<String> steps;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaperRoleBranch({
    required this.serial,
    required this.title,
    required this.titleTag,
    required this.shortDescription,
    required this.expandedDescription,
    required this.icon,
    required this.pathLabel,
    required this.steps,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? AppColors.white : AppColors.black;
    final bodyColor = isSelected
        ? AppColors.white.withValues(alpha: 0.72)
        : AppColors.onboardingMutedText;
    final metaColor = isSelected
        ? AppColors.white.withValues(alpha: 0.46)
        : AppColors.gray400;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 352;
        final panelLeftInset = isCompact ? 88.0 : 100.0;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 460),
            curve: AppCurves.standard,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: isSelected ? 12 : 10,
                            top: isSelected ? 10 : 8,
                            right: -2,
                            bottom: -4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2F2F2F)
                                    : const Color(0xFFEAE6DE),
                                borderRadius: BorderRadius.circular(
                                  isSelected ? 24 : 20,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2F2F2F)
                                      : AppColors.onboardingHairline,
                                ),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 460),
                            curve: AppCurves.standard,
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              panelLeftInset,
                              20,
                              isCompact ? 18 : 20,
                              16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.onboardingSurface,
                              borderRadius: BorderRadius.circular(
                                isSelected ? 26 : 22,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.black
                                    : AppColors.onboardingHairline,
                              ),
                              boxShadow: isSelected
                                  ? AppShadows.onboardingLift
                                  : AppShadows.shadow1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 240),
                                  curve: AppCurves.standard,
                                  style: AppTextStyles.h2.copyWith(
                                    fontSize: isSelected
                                        ? (isCompact ? 27 : 30)
                                        : (isCompact ? 20 : 22),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    letterSpacing: isSelected ? -0.5 : -0.3,
                                    color: textColor,
                                  ),
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  switchInCurve: AppCurves.standard,
                                  switchOutCurve: AppCurves.standard,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.08),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    isSelected
                                        ? expandedDescription
                                        : shortDescription,
                                    key: ValueKey(isSelected),
                                    maxLines: isSelected ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body2.copyWith(
                                      color: bodyColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Text(
                                      titleTag,
                                      style: AppTextStyles.caption.copyWith(
                                        color: metaColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 14,
                                      height: 1,
                                      color: isSelected
                                          ? AppColors.white
                                              .withValues(alpha: 0.22)
                                          : AppColors.gray300,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isSelected ? '已经沿这条路径展开' : '轻触展开这条路径',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.caption.copyWith(
                                          color: metaColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: AppCurves.standard,
                        switchOutCurve: AppCurves.standard,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.08),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: isSelected
                            ? Padding(
                                key: ValueKey('${serial}_path_strip'),
                                padding: EdgeInsets.fromLTRB(
                                  isCompact ? 34 : 40,
                                  6,
                                  14,
                                  0,
                                ),
                                child: Transform.translate(
                                  offset: const Offset(0, -8),
                                  child: _DetachedPathStrip(
                                    pathLabel: pathLabel,
                                    steps: steps,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('path_strip_empty'),
                              ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: isCompact ? 16 : 20,
                    top: -8,
                    child: _PaperSerialTag(
                      serial: serial,
                      isSelected: isSelected,
                    ),
                  ),
                  Positioned(
                    left: isCompact ? -2 : 0,
                    top: isCompact ? 42 : 44,
                    child: _MorphRoleChip(icon: icon, isSelected: isSelected),
                  ),
                  Positioned(
                    right: isCompact ? 12 : 16,
                    top: -8,
                    child: _PaperSelectionSeal(isSelected: isSelected),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoleTitleTag extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _RoleTitleTag({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.white.withValues(alpha: 0.12)
            : AppColors.onboardingSurfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isSelected ? AppColors.white : AppColors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaperSerialTag extends StatelessWidget {
  final String serial;
  final bool isSelected;

  const _PaperSerialTag({required this.serial, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 460),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : AppColors.onboardingSurfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.8),
        ),
      ),
      child: Text(
        serial,
        style: AppTextStyles.onboardingMeta.copyWith(color: AppColors.gray400),
      ),
    );
  }
}

class _MorphRoleChip extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _MorphRoleChip({required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 460),
      curve: AppCurves.standard,
      width: isSelected ? 82 : 48,
      height: isSelected ? 50 : 48,
      padding: EdgeInsets.all(isSelected ? 6 : 0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.9),
        ),
        boxShadow: AppShadows.shadow2,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: AppCurves.standard,
        switchOutCurve: AppCurves.standard,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: isSelected
            ? Row(
                key: const ValueKey('morph-expanded'),
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 16,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 10,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                key: const ValueKey('morph-collapsed'),
                child: Icon(icon, size: 22, color: AppColors.black),
              ),
      ),
    );
  }
}

class _PaperSelectionSeal extends StatelessWidget {
  final bool isSelected;

  const _PaperSelectionSeal({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 460),
      curve: AppCurves.standard,
      width: isSelected ? 74 : 28,
      height: 28,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: isSelected ? 8 : 0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onboardingHairline),
        boxShadow: isSelected ? AppShadows.shadow1 : const [],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: AppCurves.standard,
        switchOutCurve: AppCurves.standard,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: isSelected
            ? FittedBox(
                key: const ValueKey('seal-selected'),
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AppColors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '已选',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                key: const ValueKey('seal-empty'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gray300),
                ),
              ),
      ),
    );
  }
}

class _DetachedPathStrip extends StatelessWidget {
  final String pathLabel;
  final List<String> steps;

  const _DetachedPathStrip({required this.pathLabel, required this.steps});

  @override
  Widget build(BuildContext context) {
    final stepSummary = steps.join(' / ');

    return Transform.rotate(
      angle: -0.014,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.onboardingSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.onboardingHairline.withValues(alpha: 0.9),
          ),
          boxShadow: AppShadows.shadow1,
        ),
        child: Row(
          children: [
            _RoleTitleTag(
              label: pathLabel,
              isSelected: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                stepSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelectionBackdrop extends StatelessWidget {
  const _RoleSelectionBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -20,
          right: -42,
          child: Transform.rotate(
            angle: 0.06,
            child: Container(
              width: 184,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 34,
          bottom: 104,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 104,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.44),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RolePageBottomBar extends StatelessWidget {
  final Widget child;

  const _RolePageBottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        bottomSafeArea > 0 ? bottomSafeArea + 12 : 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.onboardingBackground.withValues(alpha: 0),
            AppColors.onboardingBackground.withValues(alpha: 0.92),
            AppColors.onboardingBackground,
          ],
        ),
      ),
      child: child,
    );
  }
}
