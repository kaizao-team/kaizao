import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../models/profile_models.dart';
import '../providers/profile_provider.dart';

class PortfolioFormPage extends ConsumerStatefulWidget {
  final PortfolioItem? existing;

  const PortfolioFormPage({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  ConsumerState<PortfolioFormPage> createState() => _PortfolioFormPageState();
}

class _PortfolioFormPageState extends ConsumerState<PortfolioFormPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _coverCtrl;
  late final TextEditingController _techStackCtrl;
  String _category = 'other';
  bool _isSubmitting = false;

  static const _categories = <String, String>{
    'web-app': 'Web 应用',
    'mobile-app': '移动应用',
    'mini-program': '小程序',
    'desktop': '桌面端',
    'backend': '后端服务',
    'ai-ml': 'AI / ML',
    'other': '其他',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _coverCtrl = TextEditingController(text: e?.coverUrl ?? '');
    _techStackCtrl =
        TextEditingController(text: e?.techStack.join(', ') ?? '');
    _category = e?.category ?? 'other';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _coverCtrl.dispose();
    _techStackCtrl.dispose();
    super.dispose();
  }

  List<String> get _parsedTechStack => _techStackCtrl.text
      .split(RegExp(r'[,，、]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      VccToast.show(context, message: '请输入作品标题');
      return;
    }

    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      'title': title,
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      'category': _category,
      if (_coverCtrl.text.trim().isNotEmpty) 'cover_url': _coverCtrl.text.trim(),
      if (_parsedTechStack.isNotEmpty) 'tech_stack': _parsedTechStack,
    };

    final notifier = ref.read(profileProvider('me').notifier);
    bool ok;
    if (widget.isEdit) {
      ok = await notifier.updatePortfolio(widget.existing!.id, data);
    } else {
      ok = await notifier.createPortfolio(data);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      VccToast.show(context, message: widget.isEdit ? '作品已更新' : '作品创建成功');
      Navigator.pop(context, true);
    } else {
      VccToast.show(context, message: '操作失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: topPadding),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.arrow_back_ios,
                        size: 18, color: Color(0xFF1A1C1C)),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.isEdit ? '编辑作品' : '新增作品',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1C),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('作品标题'),
                  const SizedBox(height: 6),
                  VccInput(
                    hint: '例: 电商小程序',
                    controller: _titleCtrl,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('作品描述'),
                  const SizedBox(height: 6),
                  VccInput(
                    hint: '简要描述你的作品',
                    controller: _descCtrl,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('分类'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.entries.map((entry) {
                      final selected = _category == entry.key;
                      return GestureDetector(
                        onTap: () => setState(() => _category = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.black
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: selected
                                ? null
                                : Border.all(color: AppColors.gray200),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : AppColors.gray600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('封面图 URL'),
                  const SizedBox(height: 6),
                  VccInput(
                    hint: 'https://example.com/cover.jpg',
                    controller: _coverCtrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('技术栈'),
                  const SizedBox(height: 6),
                  VccInput(
                    hint: '用逗号分隔，例: Flutter, Go, MySQL',
                    controller: _techStackCtrl,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 40),
                  VccButton(
                    text: widget.isEdit ? '保存修改' : '创建作品',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1C1C),
        letterSpacing: 0.2,
      ),
    );
  }
}
