import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _projectUpdates = true;
  bool _matchUpdates = true;
  bool _systemNotices = true;
  bool _marketingPush = false;
  bool _sound = true;
  bool _vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '通知设置',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        children: [
          _buildGroupTitle('消息推送'),
          _buildSwitch(
            '项目动态',
            '里程碑、验收、状态变更等',
            _projectUpdates,
            (v) => setState(() => _projectUpdates = v),
          ),
          _buildSwitch(
            '撮合进展',
            '投标、选定与协作提醒',
            _matchUpdates,
            (v) => setState(() => _matchUpdates = v),
          ),
          _buildSwitch(
            '系统通知',
            '平台公告、账号安全等',
            _systemNotices,
            (v) => setState(() => _systemNotices = v),
          ),
          _buildSwitch(
            '营销推送',
            '优惠活动、推荐内容',
            _marketingPush,
            (v) => setState(() => _marketingPush = v),
          ),
          const SizedBox(height: 24),
          _buildGroupTitle('提醒方式'),
          _buildSwitch(
            '声音',
            null,
            _sound,
            (v) => setState(() => _sound = v),
          ),
          _buildSwitch(
            '震动',
            null,
            _vibration,
            (v) => setState(() => _vibration = v),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.gray400,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.gray800,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
