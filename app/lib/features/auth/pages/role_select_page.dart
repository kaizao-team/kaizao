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
        return '你会先进入项目创建路径，把想法、预算和方向收拢成一份能推进的 brief。';
      case 2:
        return '你会先进入团队建档路径，把能力、案例和协作方式压成一张可承接项目的画像。';
      default:
        return '先挑一个更顺手的入口。选中后，版面会顺势展开，后面的引导也会直接接上。';
    }
  }

  String get _buttonText {
    switch (_selectedRole) {
      case 1:
        return '以项目方身份继续';
      case 2:
        return '以团队方身份继续';
      default:
        return '下一步';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: _RoleSelectionBackdrop(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'KAIZAO',
                        style: AppTextStyles.onboardingWordmark,
                      ),
                      const Spacer(),
                      _RolePageStatus(selectedRole: _selectedRole),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    '你想怎样进入 KAIZAO',
                    style: AppTextStyles.onboardingTitle.copyWith(
                      fontSize: 36,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      style: AppTextStyles.onboardingBody,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _PaperRoleBranch(
                    serial: '01',
                    title: '我是项目方',
                    titleTag: '发布路径',
                    shortDescription: '带着想法、目标和预算进来。',
                    expandedDescription: '先定方向，再收 brief，系统会把项目推到更合适的团队面前。',
                    icon: Icons.wb_incandescent_outlined,
                    pathLabel: '项目方路径',
                    steps: const ['创建项目', '整理 brief', '匹配团队'],
                    isSelected: _selectedRole == 1,
                    onTap: () => setState(() => _selectedRole = 1),
                  ),
                  const SizedBox(height: 18),
                  _PaperRoleBranch(
                    serial: '02',
                    title: '我是团队方',
                    titleTag: '建档路径',
                    shortDescription: '带着能力、案例和协作方式进来。',
                    expandedDescription: '先建立团队画像，再把能力信号、案例和协作节奏整理成可承接项目的入口。',
                    icon: Icons.code_rounded,
                    pathLabel: '团队方路径',
                    steps: const ['展示能力', '补案例', '开始接单'],
                    isSelected: _selectedRole == 2,
                    onTap: () => setState(() => _selectedRole = 2),
                  ),
                  const SizedBox(height: 22),
                  VccButton(
                    text: _buttonText,
                    onPressed: _selectedRole != null ? _confirm : null,
                    isLoading: isLoading,
                    icon: _selectedRole == null
                        ? null
                        : Icons.arrow_forward_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePageStatus extends StatelessWidget {
  final int? selectedRole;

  const _RolePageStatus({
    required this.selectedRole,
  });

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
            locked ? '入口已准备' : '等待你定方向',
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
        final panelLeftInset = isCompact ? 96.0 : 112.0;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 460),
            curve: AppCurves.standard,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 460),
                        curve: AppCurves.standard,
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          panelLeftInset,
                          24,
                          isCompact ? 18 : 22,
                          20,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.black
                              : AppColors.onboardingSurface,
                          borderRadius: BorderRadius.circular(
                            isSelected ? 30 : 24,
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
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h2.copyWith(
                                fontSize: isCompact ? 20 : 22,
                                color: textColor,
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
                                maxLines: isSelected ? 4 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body2.copyWith(
                                  color: bodyColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _RoleTitleTag(
                                  label: titleTag,
                                  isSelected: isSelected,
                                ),
                                Text(
                                  isSelected ? '已经沿这条路径展开' : '轻触展开这条路径',
                                  style: AppTextStyles.caption.copyWith(
                                    color: metaColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                                  isCompact ? 34 : 42,
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
                    left: isCompact ? 16 : 22,
                    top: -10,
                    child: _PaperSerialTag(
                      serial: serial,
                      isSelected: isSelected,
                    ),
                  ),
                  Positioned(
                    left: isCompact ? -2 : 0,
                    top: isCompact ? 44 : 46,
                    child: _MorphRoleChip(
                      icon: icon,
                      isSelected: isSelected,
                    ),
                  ),
                  Positioned(
                    right: isCompact ? 12 : 16,
                    top: -8,
                    child: _PaperSelectionSeal(
                      isSelected: isSelected,
                    ),
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

  const _RoleTitleTag({
    required this.label,
    required this.isSelected,
  });

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
        borderRadius: BorderRadius.circular(AppRadius.full),
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

  const _PaperSerialTag({
    required this.serial,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 460),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : AppColors.onboardingSurfaceMuted,
        borderRadius: BorderRadius.circular(isSelected ? 16 : 14),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.8),
        ),
      ),
      child: Text(
        serial,
        style: AppTextStyles.onboardingMeta.copyWith(
          color: AppColors.gray400,
        ),
      ),
    );
  }
}

class _MorphRoleChip extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _MorphRoleChip({
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 460),
      curve: AppCurves.standard,
      width: isSelected ? 108 : 54,
      height: isSelected ? 58 : 54,
      padding: EdgeInsets.all(isSelected ? 6 : 0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(isSelected ? 20 : 18),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: 18,
                          height: 6,
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
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.black,
                ),
              ),
      ),
    );
  }
}

class _PaperSelectionSeal extends StatelessWidget {
  final bool isSelected;

  const _PaperSelectionSeal({
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 460),
      curve: AppCurves.standard,
      width: isSelected ? 82 : 28,
      height: 28,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: isSelected ? 9 : 0),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.onboardingHairline,
        ),
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
                      '选中',
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
                  border: Border.all(
                    color: AppColors.gray300,
                  ),
                ),
              ),
      ),
    );
  }
}

class _DetachedPathStrip extends StatelessWidget {
  final String pathLabel;
  final List<String> steps;

  const _DetachedPathStrip({
    required this.pathLabel,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final stepSummary = steps.join(' / ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.9),
        ),
        boxShadow: AppShadows.shadow1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.onboardingSurfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              pathLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          top: -18,
          right: -44,
          child: Transform.rotate(
            angle: 0.06,
            child: Container(
              width: 196,
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 118,
          left: 24,
          right: 24,
          child: Container(
            height: 1,
            color: AppColors.onboardingHairline.withValues(alpha: 0.42),
          ),
        ),
        Positioned(
          left: 46,
          top: 152,
          bottom: 86,
          child: Container(
            width: 1,
            color: AppColors.onboardingHairline.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          right: 28,
          bottom: 96,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 118,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
