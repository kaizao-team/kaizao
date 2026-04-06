import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_toast.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _feedbackController = TextEditingController();

  static const _faqItems = <_FaqItem>[
    _FaqItem(
      question: 'KAIZO 是什么？',
      answer:
          'KAIZO（开造）是一个 AI 驱动的软件项目撮合平台。项目方可以通过 AI 对话快速梳理需求，平台智能匹配合适的团队方，帮助双方高效对接与协作。',
    ),
    _FaqItem(
      question: '如何发布一个项目？',
      answer:
          '登录后选择「项目方」角色，点击首页的「创建项目」，通过 AI 对话描述你的需求，系统会自动生成项目概览并为你推荐合适的团队。',
    ),
    _FaqItem(
      question: '如何成为团队方接单？',
      answer:
          '登录后选择「团队方」角色，完善团队资料和技能标签，即可在项目广场浏览项目并提交投标。',
    ),
    _FaqItem(
      question: '项目方如何选择团队？',
      answer:
          '项目发布后，平台会智能推荐匹配的团队。你也可以在收到投标后查看团队详情，选择最合适的团队方进行合作。',
    ),
    _FaqItem(
      question: '我的信息安全吗？',
      answer:
          '我们严格保护用户数据，所有通信均采用加密传输，项目信息仅对相关方可见。详情请参阅我们的隐私政策。',
    ),
    _FaqItem(
      question: '如何修改个人资料？',
      answer: '进入「我的」页面，点击头像或个人信息区域即可编辑。',
    ),
    _FaqItem(
      question: '遇到问题怎么办？',
      answer: '你可以通过页面底部的反馈入口或客服邮箱联系我们，我们会在 24 小时内回复。',
    ),
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          '帮助与反馈',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 24 + bottomPadding),
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'FAQ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: _faqItems.asMap().entries.map((entry) {
                final isLast = entry.key == _faqItems.length - 1;
                return _FaqTile(item: entry.value, isLast: isLast);
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'CONTACT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _copyEmail(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '客服邮箱',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1A1C1C),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'liangyutao.good@163.com',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.copy_outlined,
                      size: 14,
                      color: AppColors.gray300,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'FEEDBACK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1C1C),
                  ),
                  decoration: InputDecoration(
                    hintText: '请输入你的问题或建议...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray400.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9F9F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _submitFeedback(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1C1C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '提交反馈',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitFeedback(BuildContext context) {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      VccToast.show(context, message: '请输入反馈内容');
      return;
    }
    _feedbackController.clear();
    FocusScope.of(context).unfocus();
    VccToast.show(context,
        message: '感谢你的反馈，我们会尽快处理', type: VccToastType.success);
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'liangyutao.good@163.com'));
    VccToast.show(context,
        message: '邮箱已复制', type: VccToastType.success);
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  final bool isLast;
  const _FaqTile({required this.item, required this.isLast});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1C1C),
                      height: 1.3,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Text(
              widget.item.answer,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray500,
                height: 1.6,
              ),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!widget.isLast)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            height: 0.5,
            color: const Color(0xFFF3F3F3),
          ),
      ],
    );
  }
}
