import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/network/connectivity_provider.dart';

class NetworkStatusBar extends ConsumerWidget {
  final Widget child;

  const NetworkStatusBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: status == NetworkStatus.offline ? 32 : 0,
          color: AppColors.error,
          child: status == NetworkStatus.offline
              ? const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 14,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '网络连接已断开',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        Expanded(child: child),
      ],
    );
  }
}
