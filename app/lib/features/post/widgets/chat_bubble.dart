import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/post_models.dart';

class ChatBubble extends StatefulWidget {
  final AiChatMessage message;
  final void Function(String messageId, AiChatOption option)? onOptionSelected;
  final void Function(String messageId, String text)? onCustomOptionSubmitted;
  final void Function(String messageId, List<AiChatOption> options)?
      onMultiOptionsSubmitted;
  final void Function(String messageId, String text)? onFreeTextSubmitted;
  final bool showFreeTextReply;
  final bool isReadOnly;

  const ChatBubble({
    super.key,
    required this.message,
    this.onOptionSelected,
    this.onCustomOptionSubmitted,
    this.onMultiOptionsSubmitted,
    this.onFreeTextSubmitted,
    this.showFreeTextReply = false,
    this.isReadOnly = false,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  late final TextEditingController _customController;
  final Set<String> _multiSelectedKeys = <String>{};
  bool _multiCustomExpanded = false;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
    _hydrateSelectionState();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.isAnswered != widget.message.isAnswered) {
      _hydrateSelectionState();
    }
  }

  void _hydrateSelectionState() {
    _multiSelectedKeys.clear();

    AiChatOption? customSelection;
    for (final option
        in widget.message.optionsSelected ?? const <AiChatOption>[]) {
      if (option.isCustom) {
        customSelection = option;
      } else {
        _multiSelectedKeys.add(option.key);
      }
    }

    _multiCustomExpanded = customSelection != null;
    _customController.text = customSelection?.label ?? '';
  }

  Future<String?> _showReplySheet({
    required String title,
    required String hintText,
    String initialText = '',
    bool allowClear = false,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReplySheet(
        title: title,
        hintText: hintText,
        initialText: initialText,
        allowClear: allowClear,
      ),
    );
  }

  Future<void> _handleCustomReply() async {
    if (widget.isReadOnly) return;
    final text = await _showReplySheet(
      title: '补充你的答案',
      hintText: '把你的补充说明直接写下来',
    );
    if (!mounted || text == null || text.isEmpty) return;
    widget.onCustomOptionSubmitted?.call(widget.message.id, text);
  }

  Future<void> _handleFreeTextReply() async {
    if (widget.isReadOnly) return;
    final text = await _showReplySheet(
      title: '继续补充需求',
      hintText: widget.message.placeholder ?? '目标、场景、流程、限制都可以直接写',
    );
    if (!mounted || text == null || text.isEmpty) return;
    widget.onFreeTextSubmitted?.call(widget.message.id, text);
  }

  void _toggleMultiOption(AiChatOption option) {
    if (widget.message.isAnswered || widget.isReadOnly) return;

    setState(() {
      if (_multiSelectedKeys.contains(option.key)) {
        _multiSelectedKeys.remove(option.key);
      } else if (!_isMultiSelectionAtMax) {
        _multiSelectedKeys.add(option.key);
      }
    });
  }

  Future<void> _toggleMultiCustom() async {
    if (widget.message.isAnswered || widget.isReadOnly) return;
    if (!_multiCustomExpanded && _isMultiSelectionAtMax) return;

    final text = await _showReplySheet(
      title: '补充自定义选项',
      hintText: '把这个自定义选项写清楚',
      initialText: _multiCustomExpanded ? _customController.text.trim() : '',
      allowClear: _multiCustomExpanded,
    );
    if (!mounted || text == null) return;

    setState(() {
      if (text.isEmpty) {
        _multiCustomExpanded = false;
        _customController.clear();
      } else {
        _multiCustomExpanded = true;
        _customController.text = text;
      }
    });
  }

  List<AiChatOption> _collectMultiOptions() {
    final selected = <AiChatOption>[];
    for (final option in widget.message.options ?? const <AiChatOption>[]) {
      if (option.isCustom) continue;
      if (_multiSelectedKeys.contains(option.key)) {
        selected.add(option);
      }
    }

    final customText = _customController.text.trim();
    if (_multiCustomExpanded && customText.isNotEmpty) {
      AiChatOption? customBase;
      for (final option in widget.message.options ?? const <AiChatOption>[]) {
        if (option.isCustom) {
          customBase = option;
          break;
        }
      }

      selected.add(
        AiChatOption(
          key: customBase?.key ?? 'Z',
          label: customText,
          isCustom: true,
        ),
      );
    }

    return selected;
  }

  int get _multiSelectionCount => _collectMultiOptions().length;

  bool get _hasPendingMultiSelection => _isMultiSelectionValid;

  bool get _isMultiSelectionValid {
    final count = _multiSelectionCount;
    final min = widget.message.minSelections;
    final max = widget.message.maxSelections;

    if (count == 0) return false;
    if (min != null && count < min) return false;
    if (max != null && count > max) return false;
    return true;
  }

  bool get _isMultiSelectionAtMax {
    final max = widget.message.maxSelections;
    if (max == null) return false;
    return _multiSelectionCount >= max;
  }

  String? get _multiSelectionHint {
    final min = widget.message.minSelections;
    final max = widget.message.maxSelections;
    if (min == null && max == null) return null;
    if (min != null && max != null) return '请选择 $min-$max 项';
    if (min != null) return '至少选择 $min 项';
    return '最多选择 $max 项';
  }

  double _chipTextMaxWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width * 0.52;
  }

  void _submitMulti() {
    if (widget.isReadOnly) return;
    final selected = _collectMultiOptions();
    if (selected.isEmpty || !_isMultiSelectionValid) return;
    widget.onMultiOptionsSubmitted?.call(widget.message.id, selected);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final hasRealChoiceOption =
        message.options?.any((option) => !option.isCustom) ?? false;
    final hasQuickOptions = message.allowsQuickSelect && hasRealChoiceOption;
    final hasMultiChoicePreview =
        message.hasOptions && message.usesMultiChoice && hasRealChoiceOption;
    final hasFreeTextAnswer = message.usesFreeText &&
        message.freeTextAnswer?.trim().isNotEmpty == true;
    final showFreeTextReply = widget.showFreeTextReply &&
        !widget.isReadOnly &&
        !message.isUser &&
        !hasQuickOptions &&
        !hasMultiChoicePreview &&
        !message.isAnswered;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppColors.black : AppColors.gray100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: message.isUser ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
                if (hasQuickOptions) _buildOptions(),
                if (hasMultiChoicePreview) _buildMultiChoicePreview(),
                if (hasFreeTextAnswer) _buildFreeTextAnswerCard(),
                if (showFreeTextReply) _buildFreeTextReplyCard(),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    final options = widget.message.options!;
    final selected = widget.message.optionSelected;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (options[i].isCustom)
              _buildCustomPill(options[i], selected)
            else
              _buildPill(options[i], selected),
            if (i < options.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMultiChoicePreview() {
    final options = widget.message.options!;
    final submitted = widget.message.optionsSelected ?? const <AiChatOption>[];
    AiChatOption? submittedCustom;
    for (final option in submitted) {
      if (option.isCustom) {
        submittedCustom = option;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  option.isCustom
                      ? _buildMultiCustomChip(option, submittedCustom)
                      : _buildMultiChoiceChip(
                          option: option,
                          isSelected: widget.message.isAnswered
                              ? submitted.any((item) => item.key == option.key)
                              : _multiSelectedKeys.contains(option.key),
                          isDisabled: widget.isReadOnly ||
                              widget.message.isAnswered ||
                              (_isMultiSelectionAtMax &&
                                  !_multiSelectedKeys.contains(option.key)),
                        ),
              ],
            ),
            const SizedBox(height: 10),
            if (!widget.message.isAnswered &&
                !widget.isReadOnly &&
                _multiSelectionHint != null) ...[
              Text(
                '${_multiSelectionHint!}，当前 $_multiSelectionCount 项',
                style: AppTextStyles.caption.copyWith(
                  color: _isMultiSelectionValid
                      ? AppColors.gray500
                      : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.message.isAnswered)
              Text(
                '已提交 ${submitted.length} 项选择',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray500,
                ),
              )
            else if (widget.isReadOnly)
              Text(
                '已进入需求回看模式，当前内容不可再修改',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray500,
                ),
              )
            else
              GestureDetector(
                onTap: _hasPendingMultiSelection ? _submitMulti : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _hasPendingMultiSelection
                        ? AppColors.gray800
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '确认这些选项',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body2.copyWith(
                      color: _hasPendingMultiSelection
                          ? AppColors.white
                          : AppColors.gray500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTextReplyCard() {
    final hintText = widget.message.placeholder?.trim().isNotEmpty == true
        ? widget.message.placeholder!.trim()
        : '把这个问题补充清楚，继续推进需求梳理';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleFreeTextReply,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.gray800,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(17, 17, 17, 0.12),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '点击补充回答',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hintText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.72),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '去填写',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeTextAnswerCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你的回答',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message.freeTextAnswer ?? '',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.gray800,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiChoiceChip({
    required AiChatOption option,
    required bool isSelected,
    required bool isDisabled,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleMultiOption(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray800 : AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gray800 : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.gray500,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _chipTextMaxWidth(context),
              ),
              child: Text(
                option.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.white : AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiCustomChip(
    AiChatOption option,
    AiChatOption? submittedCustom,
  ) {
    final hasDraftCustom =
        _multiCustomExpanded && _customController.text.trim().isNotEmpty;
    final isSelected = widget.message.isAnswered
        ? submittedCustom != null
        : _multiCustomExpanded || hasDraftCustom;
    final label = widget.message.isAnswered
        ? submittedCustom?.label ?? option.label
        : (_customController.text.trim().isNotEmpty
            ? _customController.text.trim()
            : '其他');

    return GestureDetector(
      onTap: widget.message.isAnswered || widget.isReadOnly
          ? null
          : () => _toggleMultiCustom(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray800 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gray800 : AppColors.gray300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.message.isAnswered || hasDraftCustom
                  ? Icons.check_circle_rounded
                  : Icons.edit_outlined,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.gray500,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _chipTextMaxWidth(context),
              ),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.white : AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(AiChatOption option, AiChatOption? selected) {
    final isSelected = selected?.key == option.key;
    final isDisabled = selected != null && !isSelected;

    return GestureDetector(
      onTap: !widget.isReadOnly && selected == null
          ? () => widget.onOptionSelected?.call(widget.message.id, option)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray800 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.gray800
                : isDisabled
                    ? AppColors.gray200
                    : AppColors.gray300,
          ),
        ),
        child: Row(
          children: [
            // Letter badge
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withValues(alpha: 0.15)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  option.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.white : AppColors.gray600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.body2.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : isDisabled
                          ? AppColors.gray400
                          : AppColors.gray800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected == null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.gray400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPill(AiChatOption option, AiChatOption? selected) {
    final isSelected = selected?.isCustom == true;
    final isDisabled = widget.isReadOnly || (selected != null && !isSelected);

    if (selected != null || widget.isReadOnly) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray800 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gray800 : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white.withValues(alpha: 0.15)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.white : AppColors.gray600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSelected
                    ? selected!.label
                    : option.label.isEmpty
                        ? '其他'
                        : option.label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : isDisabled
                          ? AppColors.gray400
                          : AppColors.gray800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isDisabled ? null : _handleCustomReply,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray300),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.label.isEmpty ? '其他，我来补充' : option.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});

  static const List<String> _statusMessages = [
    '正在理解你的需求',
    '正在分析项目方向',
    '正在整理关键信息',
    '正在生成回复',
  ];

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsController;
  Timer? _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _messageIndex =
            (_messageIndex + 1) % AiTypingIndicator._statusMessages.length;
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = AiTypingIndicator._statusMessages[_messageIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: Text(
                    statusText,
                    key: ValueKey<int>(_messageIndex),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final phase = ((_dotsController.value + i * 0.2) % 1.0);
                        final opacity = phase < 0.5 ? phase * 2 : 2 - phase * 2;
                        return Padding(
                          padding: EdgeInsets.only(left: i > 0 ? 3 : 0),
                          child: Opacity(
                            opacity: 0.3 + opacity * 0.7,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.gray400,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplySheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String initialText;
  final bool allowClear;

  const _ReplySheet({
    required this.title,
    required this.hintText,
    required this.initialText,
    required this.allowClear,
  });

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    hintText: widget.hintText,
                    hintStyle: AppTextStyles.body2.copyWith(
                      color: AppColors.gray400,
                    ),
                  ),
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.black,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (widget.allowClear)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(''),
                      child: Text(
                        '移除',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (widget.allowClear) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: canSubmit
                          ? () => Navigator.of(
                                context,
                              ).pop(_controller.text.trim())
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 46,
                        decoration: BoxDecoration(
                          color:
                              canSubmit ? AppColors.gray800 : AppColors.gray200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '提交回答',
                            style: AppTextStyles.body2.copyWith(
                              color: canSubmit
                                  ? AppColors.white
                                  : AppColors.gray500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
