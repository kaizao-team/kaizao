import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class ChatSwipeAction extends StatelessWidget {
  final Widget child;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const ChatSwipeAction({
    super.key,
    required this.child,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(child.hashCode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async => false,
      background: const SizedBox.shrink(),
      secondaryBackground: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onMarkRead,
            child: Container(
              width: 72,
              alignment: Alignment.center,
              color: AppColors.info,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, color: AppColors.white, size: 20),
                  SizedBox(height: 2),
                  Text('已读',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.white)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 72,
              alignment: Alignment.center,
              color: AppColors.error,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: AppColors.white, size: 20),
                  SizedBox(height: 2),
                  Text('删除',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
