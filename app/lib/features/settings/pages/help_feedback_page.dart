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
      question: 'KAIZO 是做什么的？',
      answer: 'KAIZO 帮项目方先把需求和预算理顺，再把项目推给更合适的团队，也让团队更快看到适合自己的合作机会。',
    ),
    _FaqItem(
      question: '怎么发布一个项目？',
      answer: '注册后选择「项目方」，跟着引导把方向、需求和预算说清，系统会整理成项目摘要，再继续帮你匹配团队。',
    ),
    _FaqItem(
      question: '团队方怎么开始接项目？',
      answer: '选择「团队方」后，先把团队资料、能力标签和排期补齐，系统会先生成一版团队档案，之后就能进入广场接项目。',
    ),
    _FaqItem(
      question: '项目方怎么选团队？',
      answer: '项目发布后，平台会先给出推荐团队；你也可以查看投标和团队详情，再决定和谁继续聊、继续合作。',
    ),
    _FaqItem(
      question: '我的资料谁能看到？',
      answer: '公开展示的会是合作判断需要的内容，联系方式这类敏感信息不会随意暴露。具体规则可以看隐私政策。',
    ),
    _FaqItem(
      question: '如何修改个人资料？',
      answer: '进入「我的」页面后，可以继续完善资料，也能顺手查看钱包、通知和收藏。',
    ),
    _FaqItem(
      question: '遇到问题怎么办？',
      answer: '可以直接在这个页面提交反馈，或者发邮件给我们。我们会尽快看并跟进。',
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
              '常见问题',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 0.8,
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
              '联系方式',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 0.8,
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
              '意见反馈',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 0.8,
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
                    hintText: '把问题、建议，或者你卡住的地方写给我们',
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
    VccToast.show(context, message: '邮箱已复制', type: VccToastType.success);
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
