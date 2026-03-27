class CommentItem {
  final String id;
  final String userId;
  final String userName;
  final String? avatar;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;

  const CommentItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatar,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      likeCount: json['like_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  CommentItem copyWith({bool? isLiked, int? likeCount}) {
    return CommentItem(
      id: id,
      userId: userId,
      userName: userName,
      avatar: avatar,
      content: content,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) return '${createdAt.month}月${createdAt.day}日';
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}
