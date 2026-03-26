import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/app_colors.dart';

enum VccAvatarSize { small, medium, large, xlarge }

/// 开造 VCC 头像组件 — 黑白风格
class VccAvatar extends StatelessWidget {
  final String? imageUrl;
  final VccAvatarSize size;
  final bool isCertified;
  final bool isTeam;
  final String? fallbackText;

  const VccAvatar({
    super.key,
    this.imageUrl,
    this.size = VccAvatarSize.medium,
    this.isCertified = false,
    this.isTeam = false,
    this.fallbackText,
  });

  double get _size {
    switch (size) {
      case VccAvatarSize.small:
        return 28;
      case VccAvatarSize.medium:
        return 48;
      case VccAvatarSize.large:
        return 64;
      case VccAvatarSize.xlarge:
        return 80;
    }
  }

  double get _borderRadius => isTeam ? 8 : 999;

  @override
  Widget build(BuildContext context) {
    Widget avatar = ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );

    if (isCertified) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: isTeam ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isTeam ? BorderRadius.circular(_borderRadius + 2) : null,
          border: Border.all(color: AppColors.black, width: 2),
        ),
        child: avatar,
      );
    }

    return SizedBox(
      width: isCertified ? _size + 4 : _size,
      height: isCertified ? _size + 4 : _size,
      child: avatar,
    );
  }

  Widget _buildPlaceholder() {
    if (fallbackText != null && fallbackText!.isNotEmpty) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: Center(
          child: Text(
            fallbackText!.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: _size * 0.4,
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
        ),
      );
    }

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Icon(
        Icons.person_outline,
        size: _size * 0.5,
        color: AppColors.gray400,
      ),
    );
  }
}
