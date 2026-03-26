import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.isMe && message.isFailed)
          GestureDetector(
            onTap: () => _showRetryMenu(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 6, bottom: 4),
              child: Icon(Icons.error, size: 18, color: AppColors.error),
            ),
          ),
        if (message.isMe && message.isSending)
          const Padding(
            padding: EdgeInsets.only(right: 6, bottom: 6),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gray400),
              ),
            ),
          ),
        Flexible(
          child: Opacity(
            opacity: message.isFailed ? 0.5 : 1.0,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe ? AppColors.accentLight : AppColors.gray100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isMe ? 14 : 4),
                  topRight: Radius.circular(message.isMe ? 4 : 14),
                  bottomLeft: const Radius.circular(14),
                  bottomRight: const Radius.circular(14),
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ),
        ),
        if (!message.isMe && message.status == MessageStatus.sent)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Icon(Icons.done_all, size: 14, color: AppColors.gray400),
          ),
      ],
    );
  }

  void _showRetryMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.accent),
              title: const Text('重新发送'),
              onTap: () {
                Navigator.pop(ctx);
                onRetry?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('删除'),
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
