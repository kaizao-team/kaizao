import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'vcc_avatar.dart';

final RegExp _localAvatarKeyPattern = RegExp(r'^user_avatar_[mf]_\d{2}$');

class LocalAvatarOption {
  final String value;
  final String groupKey;

  const LocalAvatarOption({
    required this.value,
    required this.groupKey,
  });
}

class LocalAvatarGroup {
  final String key;
  final String label;
  final List<LocalAvatarOption> options;

  const LocalAvatarGroup({
    required this.key,
    required this.label,
    required this.options,
  });
}

class LocalAvatarCatalog {
  LocalAvatarCatalog._();

  static final List<LocalAvatarOption> male = List<LocalAvatarOption>.generate(
    9,
    (index) => LocalAvatarOption(
      value: 'user_avatar_m_${(index + 1).toString().padLeft(2, '0')}.png',
      groupKey: 'male',
    ),
  );

  static final List<LocalAvatarOption> female =
      List<LocalAvatarOption>.generate(
    9,
    (index) => LocalAvatarOption(
      value: 'user_avatar_f_${(index + 1).toString().padLeft(2, '0')}.png',
      groupKey: 'female',
    ),
  );

  static final List<LocalAvatarGroup> groups = [
    LocalAvatarGroup(key: 'male', label: '男', options: male),
    LocalAvatarGroup(key: 'female', label: '女', options: female),
  ];

  static String? normalizeValue(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    var value = trimmed;
    if (value.startsWith('/assets/')) {
      value = value.substring(1);
    }

    if (value.startsWith('assets/avatars/users/')) {
      value = value.substring('assets/avatars/users/'.length);
    }

    final withoutExtension = value.replaceAll('.png', '');
    if (_localAvatarKeyPattern.hasMatch(withoutExtension)) {
      return '$withoutExtension.png';
    }

    return null;
  }

  static bool containsValue(String? raw) => normalizeValue(raw) != null;

  static String initialGroupFor(String? raw) {
    final normalized = normalizeValue(raw);
    if (normalized == null) return groups.first.key;
    return normalized.contains('_f_') ? 'female' : 'male';
  }
}

class LocalAvatarPickerResult {
  final String? avatarUrl;

  const LocalAvatarPickerResult(this.avatarUrl);
}

class LocalAvatarPickerTrigger extends StatelessWidget {
  final String? value;
  final String title;
  final String hint;
  final ValueChanged<String?> onChanged;
  final String sheetTitle;
  final double avatarDiameter;
  final IconData emptyIcon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final BoxDecoration? decoration;
  final bool showEditBadge;

  const LocalAvatarPickerTrigger({
    super.key,
    required this.value,
    required this.title,
    required this.hint,
    required this.onChanged,
    this.sheetTitle = '选择头像',
    this.avatarDiameter = 56,
    this.emptyIcon = Icons.person_outline_rounded,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.base,
      vertical: AppSpacing.md,
    ),
    this.decoration,
    this.showEditBadge = true,
  });

  Future<void> _handleTap(BuildContext context) async {
    final result = await showLocalAvatarPickerSheet(
      context,
      initialAvatarUrl: value,
      title: sheetTitle,
    );
    if (result == null) return;
    onChanged(result.avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedValue = LocalAvatarCatalog.normalizeValue(value) ?? value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _handleTap(context),
        child: Container(
          padding: padding,
          decoration: decoration ??
              BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.gray200),
              ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _AvatarPreview(
                    value: resolvedValue,
                    diameter: avatarDiameter,
                    emptyIcon: emptyIcon,
                  ),
                  if (showEditBadge)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 12,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hint,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.gray400,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<LocalAvatarPickerResult?> showLocalAvatarPickerSheet(
  BuildContext context, {
  String? initialAvatarUrl,
  String title = '选择头像',
}) {
  return showModalBottomSheet<LocalAvatarPickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (_) => _LocalAvatarPickerSheet(
      initialAvatarUrl: initialAvatarUrl,
      title: title,
    ),
  );
}

class _LocalAvatarPickerSheet extends StatefulWidget {
  final String? initialAvatarUrl;
  final String title;

  const _LocalAvatarPickerSheet({
    required this.initialAvatarUrl,
    required this.title,
  });

  @override
  State<_LocalAvatarPickerSheet> createState() =>
      _LocalAvatarPickerSheetState();
}

class _LocalAvatarPickerSheetState extends State<_LocalAvatarPickerSheet> {
  late String? _selectedAvatarUrl;
  late String _activeGroupKey;

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = LocalAvatarCatalog.normalizeValue(
      widget.initialAvatarUrl,
    );
    _activeGroupKey = LocalAvatarCatalog.initialGroupFor(
      widget.initialAvatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentGroup = LocalAvatarCatalog.groups.firstWhere(
      (group) => group.key == _activeGroupKey,
      orElse: () => LocalAvatarCatalog.groups.first,
    );
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.base + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.title,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '头像会保存到你的资料里，之后也能随时改。',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: LocalAvatarCatalog.groups.map((group) {
              final isActive = group.key == _activeGroupKey;
              return Padding(
                padding: EdgeInsets.only(
                  right: group == LocalAvatarCatalog.groups.last
                      ? 0
                      : AppSpacing.sm,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _activeGroupKey = group.key),
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    curve: AppCurves.standard,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.black : AppColors.gray100,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      group.label,
                      style: AppTextStyles.body2.copyWith(
                        color: isActive ? AppColors.white : AppColors.gray700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = AppSpacing.md;
              final itemWidth = (constraints.maxWidth - spacing * 3) / 4;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: currentGroup.options.map((option) {
                  final isSelected = option.value == _selectedAvatarUrl;
                  return SizedBox(
                    width: itemWidth,
                    child: _AvatarOptionButton(
                      value: option.value,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedAvatarUrl = option.value);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (_selectedAvatarUrl != null)
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(const LocalAvatarPickerResult(null));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gray700,
                      backgroundColor: AppColors.gray100,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('移除头像'),
                  ),
                ),
              if (_selectedAvatarUrl != null)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(LocalAvatarPickerResult(_selectedAvatarUrl));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('使用这个头像'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarOptionButton extends StatelessWidget {
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarOptionButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: AppCurves.standard,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isSelected ? AppColors.black : AppColors.gray200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: VccAvatar(
                    imageUrl: value,
                    size: VccAvatarSize.large,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.white,
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

class _AvatarPreview extends StatelessWidget {
  final String? value;
  final double diameter;
  final IconData emptyIcon;

  const _AvatarPreview({
    required this.value,
    required this.diameter,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = diameter >= 72
        ? VccAvatarSize.xlarge
        : (diameter >= 60 ? VccAvatarSize.large : VccAvatarSize.medium);

    if (value != null && value!.isNotEmpty) {
      return SizedBox(
        width: diameter,
        height: diameter,
        child: FittedBox(
          fit: BoxFit.contain,
          child: VccAvatar(
            imageUrl: value,
            size: avatarSize,
          ),
        ),
      );
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Icon(
        emptyIcon,
        size: diameter * 0.42,
        color: AppColors.gray400,
      ),
    );
  }
}
