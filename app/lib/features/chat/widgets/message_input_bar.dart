import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAttachment,
            child: const Icon(Icons.add_circle_outline,
                size: 28, color: AppColors.gray400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '输入消息...',
                hintStyle:
                    const TextStyle(fontSize: 15, color: AppColors.gray400),
                filled: true,
                fillColor: AppColors.gray100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              style:
                  const TextStyle(fontSize: 15, color: AppColors.gray800),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: hasText ? onSend : null,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: hasText ? AppColors.black : AppColors.gray300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 16, color: AppColors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
