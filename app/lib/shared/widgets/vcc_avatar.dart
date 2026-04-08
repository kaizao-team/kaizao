import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/app_colors.dart';

enum VccAvatarSize { small, medium, large, xlarge }

final RegExp _userAvatarIdPattern = RegExp(r'^user_avatar_[mf]_\d{2}$');

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

  double get _borderRadius => isTeam ? AppRadius.sm : AppRadius.full;

  @override
  Widget build(BuildContext context) {
    final resolvedImage = _resolveImageValue(imageUrl);
    Widget avatar = ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: resolvedImage != null
          ? _buildImage(resolvedImage)
          : _buildPlaceholder(),
    );

    if (isCertified) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: isTeam ? BoxShape.rectangle : BoxShape.circle,
          borderRadius:
              isTeam ? BorderRadius.circular(_borderRadius + 2) : null,
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

  Widget _buildImage(_ResolvedAvatarImage image) {
    if (image.isAsset) {
      return Image.asset(
        image.value,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: image.value,
      width: _size,
      height: _size,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  _ResolvedAvatarImage? _resolveImageValue(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _ResolvedAvatarImage.network(value);
    }

    final normalized =
        value.startsWith('/assets/') ? value.substring(1) : value;

    if (normalized.startsWith('assets/')) {
      return _ResolvedAvatarImage.asset(normalized);
    }

    if (_userAvatarIdPattern.hasMatch(value)) {
      return _ResolvedAvatarImage.asset('assets/avatars/users/$value.png');
    }

    if (_userAvatarIdPattern.hasMatch(value.replaceAll('.png', ''))) {
      return _ResolvedAvatarImage.asset(
        'assets/avatars/users/${value.replaceAll('.png', '')}.png',
      );
    }

    return _ResolvedAvatarImage.network(value);
  }

  Widget _buildPlaceholder() {
    if (fallbackText != null && fallbackText!.isNotEmpty) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: AppColors.surfaceStrong,
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
        color: AppColors.surfaceStrong,
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

class _ResolvedAvatarImage {
  final String value;
  final bool isAsset;

  const _ResolvedAvatarImage._({required this.value, required this.isAsset});

  const _ResolvedAvatarImage.asset(String value)
      : this._(value: value, isAsset: true);

  const _ResolvedAvatarImage.network(String value)
      : this._(value: value, isAsset: false);
}
