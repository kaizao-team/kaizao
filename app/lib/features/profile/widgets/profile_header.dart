import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/profile_models.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isSelf;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.isSelf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.black, Color(0xFF2D2D2D)],
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: profile.isVerified ? AppColors.accent : AppColors.white,
                  width: profile.isVerified ? 2.5 : 3,
                ),
              ),
              child: VccAvatar(
                size: VccAvatarSize.xlarge,
                imageUrl: profile.avatar,
                fallbackText: profile.nickname.isNotEmpty
                    ? profile.nickname[0]
                    : 'U',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
