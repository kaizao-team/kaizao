import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_input.dart';

class AuthMetaBar extends StatelessWidget {
  const AuthMetaBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'KAIZO',
        style: AppTextStyles.overline.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: AppColors.black,
        ),
      ),
    );
  }
}

class AuthBrandHero extends StatelessWidget {
  final bool compact;
  final Animation<double>? scale;
  final Animation<double>? lift;

  const AuthBrandHero({
    super.key,
    required this.compact,
    this.scale,
    this.lift,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 140.0 : 160.0;
    final logo = Image.asset(
      'assets/branding/app_launch_static_transparent_cropped.png',
      width: logoSize,
      height: logoSize,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        animatedLogo,
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        Text(
          'KAIZO，连接新的生产力',
          textAlign: TextAlign.center,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.gray500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class AuthFieldShell extends StatelessWidget {
  final String label;
  final Widget child;

  const AuthFieldShell({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.xs),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
        ),
        Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              hintStyle: AppTextStyles.inputHint.copyWith(
                color: AppColors.gray300,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.gray200,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.black,
                  width: 1.4,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.gray200,
                  width: 1.2,
                ),
              ),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class AuthPhonePanel extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final FocusNode phoneFocus;
  final FocusNode codeFocus;
  final int countdown;
  final bool isPhoneValid;
  final bool isSendingCode;
  final bool compact;
  final VoidCallback onSendCode;

  const AuthPhonePanel({
    super.key,
    required this.phoneController,
    required this.codeController,
    required this.phoneFocus,
    required this.codeFocus,
    required this.countdown,
    required this.isPhoneValid,
    required this.isSendingCode,
    required this.compact,
    required this.onSendCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldShell(
          label: '手机号',
          child: VccInput(
            hint: '请输入手机号',
            controller: phoneController,
            focusNode: phoneFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '+86',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ),
            onSubmitted: (_) => codeFocus.requestFocus(),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.base),
        AuthFieldShell(
          label: '验证码',
          child: VccInput(
            hint: '请输入短信验证码',
            controller: codeController,
            focusNode: codeFocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            suffixIcon: TextButton(
              onPressed: isPhoneValid && countdown == 0 && !isSendingCode
                  ? onSendCode
                  : null,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isSendingCode
                    ? '发送中...'
                    : countdown > 0
                        ? '${countdown}s'
                        : '获取验证码',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPhoneValid && countdown == 0 && !isSendingCode
                      ? AppColors.black
                      : AppColors.gray400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthAgreementRow extends StatelessWidget {
  final bool isChecked;
  final String prefixText;
  final VoidCallback onToggle;
  final VoidCallback onUserAgreementTap;
  final VoidCallback onPrivacyPolicyTap;

  const AuthAgreementRow({
    super.key,
    required this.isChecked,
    required this.prefixText,
    required this.onToggle,
    required this.onUserAgreementTap,
    required this.onPrivacyPolicyTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: isChecked ? AppColors.black : AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: isChecked ? AppColors.black : AppColors.gray300,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 12, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '$prefixText ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                _InlineLegalLink(
                  text: '《用户协议》',
                  onTap: onUserAgreementTap,
                ),
                Text(
                  ' 与 ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                _InlineLegalLink(
                  text: '《隐私政策》',
                  onTap: onPrivacyPolicyTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLegalLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _InlineLegalLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
