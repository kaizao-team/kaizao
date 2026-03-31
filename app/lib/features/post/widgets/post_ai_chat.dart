import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../models/post_models.dart';
import '../providers/post_provider.dart';
import 'chat_bubble.dart';

class PostAiChat extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final bool showFooter;

  const PostAiChat({
    super.key,
    this.scrollController,
    this.showFooter = true,
  });

  @override
  ConsumerState<PostAiChat> createState() => _PostAiChatState();
}

class _PostAiChatState extends ConsumerState<PostAiChat> {
  final _controller = TextEditingController();
  final _internalScrollController = ScrollController();
  final _focusNode = FocusNode();

  ScrollController get _scrollController =>
      widget.scrollController ?? _internalScrollController;

  @override
  void dispose() {
    _controller.dispose();
    _internalScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(postStateProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postStateProvider);

    // Show typing indicator only for thinking/toolCall — during receiving,
    // the growing text itself provides visual feedback.
    final showTypingIndicator =
        postState.aiStreamPhase == AiStreamPhase.thinking ||
        postState.aiStreamPhase == AiStreamPhase.toolCall;

    ref.listen(postStateProvider, (prev, next) {
      if (widget.scrollController == null &&
          ((prev?.messages.length ?? 0) != next.messages.length ||
              prev?.aiStreamPhase != next.aiStreamPhase)) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            itemCount:
                postState.messages.length + (showTypingIndicator ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == postState.messages.length) {
                return const AiTypingIndicator();
              }
              return ChatBubble(message: postState.messages[index]);
            },
          ),
        ),
        if (widget.showFooter &&
            postState.canGeneratePrd &&
            !postState.isGeneratingPrd)
          _GeneratePrdButton(
            onTap: () => ref.read(postStateProvider.notifier).generatePrd(),
          ),
        if (widget.showFooter)
          _ChatInputBar(
            controller: _controller,
            focusNode: _focusNode,
            isAiTyping: postState.isAiTyping,
            onSend: _send,
          ),
      ],
    );
  }
}

class _GeneratePrdButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GeneratePrdButton({required this.onTap});

  @override
  State<_GeneratePrdButton> createState() => _GeneratePrdButtonState();
}

class _GeneratePrdButtonState extends State<_GeneratePrdButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: AppColors.white),
                  SizedBox(width: 8),
                  Text(
                    '生成 PRD',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAiTyping;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isAiTyping,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isAiTyping,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: '描述你的需求...',
                  hintStyle: TextStyle(color: AppColors.gray400, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.black),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isAiTyping ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isAiTyping ? AppColors.gray300 : AppColors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                size: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
