import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

enum LegalDocumentType { userAgreement, privacyPolicy }

class LegalDocumentPage extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentPage.userAgreement({super.key})
      : type = LegalDocumentType.userAgreement;

  const LegalDocumentPage.privacyPolicy({super.key})
      : type = LegalDocumentType.privacyPolicy;

  @override
  Widget build(BuildContext context) {
    final document = _documentFor(type);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.gray50,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(document.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.base,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Text(
                  '更新日期 ${document.updatedAt}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(document.title, style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                document.summary,
                style: AppTextStyles.body1.copyWith(color: AppColors.gray600),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...document.sections.map((section) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: _LegalSection(section: section),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final _LegalSectionData section;

  const _LegalSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.sm),
        ...section.paragraphs.map((paragraph) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              paragraph,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.gray600,
                height: 1.65,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LegalDocument {
  final String title;
  final String updatedAt;
  final String summary;
  final List<_LegalSectionData> sections;

  const _LegalDocument({
    required this.title,
    required this.updatedAt,
    required this.summary,
    required this.sections,
  });
}

class _LegalSectionData {
  final String title;
  final List<String> paragraphs;

  const _LegalSectionData({
    required this.title,
    required this.paragraphs,
  });
}

_LegalDocument _documentFor(LegalDocumentType type) {
  switch (type) {
    case LegalDocumentType.userAgreement:
      return const _LegalDocument(
        title: '用户协议',
        updatedAt: '2026-03-27',
        summary: '本协议说明你在使用 KAIZAO 时的账号、内容、合作与平台规则边界。',
        sections: [
          _LegalSectionData(
            title: '1. 账号与访问',
            paragraphs: [
              '你应使用真实、合法、可正常接收验证码的手机号注册或登录，并妥善保管账号与验证码。',
              '若发现异常登录、批量注册、身份冒用或其他风险行为，平台有权要求补充验证或限制部分能力。',
            ],
          ),
          _LegalSectionData(
            title: '2. 平台服务与使用规范',
            paragraphs: [
              'KAIZAO 提供项目发布、团队展示、沟通协作、撮合与进度管理等服务，平台会持续迭代功能与规则。',
              '你不得发布违法违规、虚假、侵权、骚扰或绕开平台交易的信息；对明显违规行为，平台可直接处置。',
            ],
          ),
          _LegalSectionData(
            title: '3. 责任与终止',
            paragraphs: [
              '合作中的报价、周期、交付与验收应由合作双方自行确认，平台提供撮合与协助，但不保证商业结果。',
              '若你违反协议或平台规则，平台可采取提醒、限流、冻结账号或终止服务等措施。',
            ],
          ),
        ],
      );
    case LegalDocumentType.privacyPolicy:
      return const _LegalDocument(
        title: '隐私政策',
        updatedAt: '2026-03-27',
        summary: '本政策说明 KAIZAO 如何收集、使用、存储并保护你的个人信息。',
        sections: [
          _LegalSectionData(
            title: '1. 我们收集的信息',
            paragraphs: [
              '当你注册、登录或使用服务时，我们可能收集手机号、登录结果、昵称、头像、角色类型、设备与日志信息。',
              '在你主动使用实名认证、支付、消息通知等功能时，我们会收集对应能力所必需的信息。',
            ],
          ),
          _LegalSectionData(
            title: '2. 信息如何使用',
            paragraphs: [
              '我们使用这些信息完成账号登录、识别用户身份、提供撮合与协作服务、改进产品体验并保障系统安全。',
              '在必要范围内，我们可能向短信、云服务、支付或风控合作方共享最小必要信息以完成对应能力。',
            ],
          ),
          _LegalSectionData(
            title: '3. 你的权利',
            paragraphs: [
              '你有权访问、更正、补充与你账号相关的信息，并可根据产品能力关闭部分通知或申请注销账号。',
              '若你对个人信息处理方式有疑问，可通过应用内“帮助与反馈”联系平台。',
            ],
          ),
        ],
      );
  }
}
