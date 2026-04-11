enum NotificationKind {
  matchSuccess,
  payReminder,
  milestoneDelivered,
  newBid,
  system,
}

extension NotificationKindX on NotificationKind {
  String get label {
    switch (this) {
      case NotificationKind.matchSuccess:
        return '合作确认';
      case NotificationKind.payReminder:
        return '支付提醒';
      case NotificationKind.milestoneDelivered:
        return '验收提醒';
      case NotificationKind.newBid:
        return '新投标';
      case NotificationKind.system:
        return '系统提醒';
    }
  }

  int get displayOrder {
    switch (this) {
      case NotificationKind.newBid:
        return 0;
      case NotificationKind.matchSuccess:
        return 1;
      case NotificationKind.payReminder:
        return 2;
      case NotificationKind.milestoneDelivered:
        return 3;
      case NotificationKind.system:
        return 4;
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final int notificationType;
  final bool isRead;
  final DateTime createdAt;
  final String? targetType;
  final String? targetId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.targetType,
    this.targetId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['content']?.toString() ?? '',
      notificationType: _readNotificationType(json),
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetType: json['target_type']?.toString(),
      targetId: json['target_uuid']?.toString() ?? json['target_id']?.toString(),
    );
  }

  static int _readNotificationType(Map<String, dynamic> json) {
    final raw = json['notification_type'] ?? json['type'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      notificationType: notificationType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      targetType: targetType,
      targetId: targetId,
    );
  }

  bool get hasTarget => targetType != null && targetId != null;

  NotificationKind get kind {
    switch (notificationType) {
      case 20:
        return NotificationKind.matchSuccess;
      case 21:
        return NotificationKind.payReminder;
      case 22:
        return NotificationKind.milestoneDelivered;
      case 23:
        return NotificationKind.newBid;
      default:
        return NotificationKind.system;
    }
  }

  String get categoryLabel {
    return kind.label;
  }

  String? get actionLabel {
    switch (targetType) {
      case 'project':
        return '进入项目';
      default:
        return null;
    }
  }

  bool get canOpenTarget {
    switch (targetType) {
      case 'project':
        return targetId != null && targetId!.isNotEmpty;
      default:
        return false;
    }
  }

  String? get unsupportedTargetMessage {
    switch (targetType) {
      case 'conversation':
      case 'order':
      case 'milestone':
        return '该通知暂时无法直接打开。';
      default:
        return null;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 7) return '${createdAt.month}月${createdAt.day}日';
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}
