import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          '通知',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: AppColors.gray300,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '暂无通知',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '有新消息时会在这里提醒你',
              style: TextStyle(fontSize: 13, color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}
