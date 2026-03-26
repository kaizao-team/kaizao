import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/task_card_message.dart';
import '../widgets/message_input_bar.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatDetailPage({super.key, required this.conversationId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    ref
        .read(chatDetailProvider(widget.conversationId).notifier)
        .sendMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailProvider(widget.conversationId));

    ref.listen<ChatDetailState>(
      chatDetailProvider(widget.conversationId),
      (previous, next) {
        if ((previous?.messages.length ?? 0) < next.messages.length) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('张开发',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text('在线',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.gray500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : state.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off,
                                size: 48, color: AppColors.gray300),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => ref
                                  .read(chatDetailProvider(
                                          widget.conversationId)
                                      .notifier)
                                  .loadMessages(),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index < state.messages.length - 1
                                    ? 12
                                    : 0),
                            child: Row(
                              mainAxisAlignment: msg.isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!msg.isMe) ...[
                                  const VccAvatar(
                                    size: VccAvatarSize.small,
                                    fallbackText: '张',
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(child: _buildMessage(msg)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          MessageInputBar(
            controller: _inputController,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    if (msg.type == MessageType.taskCard && msg.taskExtra != null) {
      return TaskCardMessage(task: msg.taskExtra!);
    }
    return MessageBubble(
      message: msg,
      onRetry: () => ref
          .read(chatDetailProvider(widget.conversationId).notifier)
          .retryMessage(msg.id),
      onDelete: () => ref
          .read(chatDetailProvider(widget.conversationId).notifier)
          .deleteMessage(msg.id),
    );
  }
}
