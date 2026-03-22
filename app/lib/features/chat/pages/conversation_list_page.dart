import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';

class ConversationListPage extends StatelessWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      body: ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const Divider(indent: 76),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const VccAvatar(size: VccAvatarSize.medium, fallbackText: 'A'),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('阿杰', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                Text('14:30', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
              ],
            ),
            subtitle: const Text(
              '好的，我今天先完成看板页面的开发',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: AppColors.gray500),
            ),
            trailing: index == 0
                ? Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  )
                : null,
            onTap: () => context.push('/chat/conv_$index'),
          );
        },
      ),
    );
  }
}
