import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../providers/chat_provider.dart';
import '../models/chat_models.dart';
import '../widgets/chat_swipe_action.dart';

class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : state.errorMessage != null
              ? _buildError(context, ref, state.errorMessage!)
              : state.conversations.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(conversationListProvider.notifier)
                          .loadConversations(),
                      child: ListView.separated(
                        itemCount: state.conversations.length,
                        separatorBuilder: (_, __) =>
                            const Divider(indent: 76, height: 0.5),
                        itemBuilder: (context, index) {
                          final conv = state.conversations[index];
                          return ChatSwipeAction(
                            onMarkRead: () => ref
                                .read(conversationListProvider.notifier)
                                .markRead(conv.id),
                            onDelete: () =>
                                _confirmDelete(context, ref, conv.id),
                            child: _ConversationTile(conversation: conv),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.gray300),
          const SizedBox(height: 12),
          Text('加载失败', style: TextStyle(color: AppColors.gray500)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref
                .read(conversationListProvider.notifier)
                .loadConversations(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.gray300),
          SizedBox(height: 12),
          Text('暂无消息',
              style: TextStyle(fontSize: 16, color: AppColors.gray500)),
          SizedBox(height: 4),
          Text('项目合作消息会显示在这里',
              style: TextStyle(fontSize: 13, color: AppColors.gray400)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(conversationListProvider.notifier)
                  .deleteConversation(id);
            },
            child: const Text('删除',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  String get _timeLabel {
    try {
      final dt = DateTime.parse(conversation.lastMessageTime);
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: VccAvatar(
        size: VccAvatarSize.medium,
        fallbackText: conversation.peerName.isNotEmpty
            ? conversation.peerName[0]
            : '?',
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.peerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800),
            ),
          ),
          Text(_timeLabel,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.gray400)),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.projectTitle != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                conversation.projectTitle!,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: conversation.unreadCount > 0
                    ? AppColors.gray800
                    : AppColors.gray500,
              ),
            ),
          ),
        ],
      ),
      trailing: conversation.unreadCount > 0
          ? Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  conversation.unreadCount > 99
                      ? '99+'
                      : '${conversation.unreadCount}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            )
          : null,
      onTap: () => context.push('/chat/${conversation.id}'),
    );
  }
}
