import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/home_models.dart';
import 'home_section_header.dart';

const _categoryTileBorderColor = Color.fromRGBO(17, 17, 17, 0.08);

class HomeCategoryGrid extends StatelessWidget {
  final List<CategoryItem> categories;
  final void Function(String categoryKey) onCategoryTap;

  const HomeCategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final featured = categories.first;
    final secondary = categories.skip(1).take(3).toList();
    final compact = categories.skip(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: '预设类型',
          subtitle: '从类型进入项目广场。',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final leftWidth = secondary.length > 1
                  ? (constraints.maxWidth - 12) * 0.58
                  : constraints.maxWidth;
              final rightWidth = constraints.maxWidth - 12 - leftWidth;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeaturedCategoryTile(
                    category: featured,
                    onTap: () => onCategoryTap(featured.key),
                  ),
                  if (secondary.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: leftWidth,
                          child: _CategoryFocusTile(
                            category: secondary[0],
                            onTap: () => onCategoryTap(secondary[0].key),
                          ),
                        ),
                        if (secondary.length > 1) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: rightWidth,
                            child: Column(
                              children: [
                                _SideCategoryTile(
                                  category: secondary[1],
                                  onTap: () => onCategoryTap(secondary[1].key),
                                ),
                                if (secondary.length > 2) ...[
                                  const SizedBox(height: 10),
                                  _SideCategoryTile(
                                    category: secondary[2],
                                    onTap: () =>
                                        onCategoryTap(secondary[2].key),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (compact.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _CompactCategoryRows(
                      categories: compact,
                      leftWidth: leftWidth,
                      rightWidth: rightWidth,
                      onCategoryTap: onCategoryTap,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedCategoryTile extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const _FeaturedCategoryTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: AppColors.black.withValues(alpha: 0.04),
        ),
      ),
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _CategoryEyebrow(
                    label: '推荐入口',
                    inverted: true,
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.north_east_rounded,
                      size: 18,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.count > 0 ? '${category.count} 个项目正在浏览' : '直接进入项目广场',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color.fromRGBO(255, 255, 255, 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFocusTile extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const _CategoryFocusTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _categoryTileBorderColor),
      ),
      shadowColor: AppColors.black.withValues(alpha: 0.04),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 146,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CategoryEyebrow(label: '探索方向'),
                const Spacer(),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.count > 0 ? '${category.count} 个项目' : '直接进入广场',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.north_east_rounded,
                      size: 16,
                      color: AppColors.gray400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideCategoryTile extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const _SideCategoryTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _categoryTileBorderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category.count > 0 ? '${category.count} 个项目' : '直接进入广场',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactCategoryLink extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const _CompactCategoryLink({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _categoryTileBorderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.count > 0 ? '${category.count} 个项目' : '直接进入广场',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: AppColors.gray400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryEyebrow extends StatelessWidget {
  final String label;
  final bool inverted;

  const _CategoryEyebrow({
    required this.label,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inverted
            ? AppColors.white.withValues(alpha: 0.14)
            : AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: inverted
              ? AppColors.white.withValues(alpha: 0.24)
              : _categoryTileBorderColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: inverted ? AppColors.white : AppColors.gray600,
        ),
      ),
    );
  }
}

class _CompactCategoryRows extends StatelessWidget {
  final List<CategoryItem> categories;
  final double leftWidth;
  final double rightWidth;
  final void Function(String categoryKey) onCategoryTap;

  const _CompactCategoryRows({
    required this.categories,
    required this.leftWidth,
    required this.rightWidth,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <List<CategoryItem>>[];
    for (var index = 0; index < categories.length; index += 2) {
      rows.add(categories.skip(index).take(2).toList());
    }

    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leftWidth,
                child: _CompactCategoryLink(
                  category: rows[rowIndex][0],
                  onTap: () => onCategoryTap(rows[rowIndex][0].key),
                ),
              ),
              if (rows[rowIndex].length > 1) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: rightWidth,
                  child: _CompactCategoryLink(
                    category: rows[rowIndex][1],
                    onTap: () => onCategoryTap(rows[rowIndex][1].key),
                  ),
                ),
              ],
            ],
          ),
          if (rowIndex != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
