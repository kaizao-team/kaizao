enum MessageType { text, image, taskCard }

enum MessageStatus { sending, sent, failed }

class Conversation {
  final String id;
  final String peerId;
  final String peerName;
  final String? peerAvatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String? projectTitle;

  const Conversation({
    required this.id,
    required this.peerId,
    required this.peerName,
    this.peerAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.projectTitle,
  });

  Conversation copyWith({int? unreadCount}) {
    return Conversation(
      id: id,
      peerId: peerId,
      peerName: peerName,
      peerAvatar: peerAvatar,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      projectTitle: projectTitle,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      peerId: json['peer_id'] as String,
      peerName: json['peer_name'] as String,
      peerAvatar: json['peer_avatar'] as String?,
      lastMessage: json['last_message'] as String,
      lastMessageTime: json['last_message_time'] as String,
      unreadCount: json['unread_count'] as int,
      projectTitle: json['project_title'] as String?,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final String createdAt;
  final TaskCardExtra? taskExtra;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.taskExtra,
  });

  bool get isMe => senderId == 'me';
  bool get isFailed => status == MessageStatus.failed;
  bool get isSending => status == MessageStatus.sending;

  ChatMessage copyWith({MessageStatus? status, String? id}) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId,
      content: content,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      taskExtra: taskExtra,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final statusStr = json['status'] as String? ?? 'sent';

    TaskCardExtra? extra;
    if (typeStr == 'task_card' && json['extra'] != null) {
      extra = TaskCardExtra.fromJson(json['extra'] as Map<String, dynamic>);
    }

    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      type: _parseType(typeStr),
      status: _parseStatus(statusStr),
      createdAt: json['created_at'] as String,
      taskExtra: extra,
    );
  }

  static MessageType _parseType(String s) {
    switch (s) {
      case 'image': return MessageType.image;
      case 'task_card': return MessageType.taskCard;
      default: return MessageType.text;
    }
  }

  static MessageStatus _parseStatus(String s) {
    switch (s) {
      case 'sending': return MessageStatus.sending;
      case 'failed': return MessageStatus.failed;
      default: return MessageStatus.sent;
    }
  }
}

class TaskCardExtra {
  final String taskId;
  final String taskTitle;
  final String taskType;
  final String taskStatus;
  final String taskSummary;

  const TaskCardExtra({
    required this.taskId,
    required this.taskTitle,
    required this.taskType,
    required this.taskStatus,
    required this.taskSummary,
  });

  factory TaskCardExtra.fromJson(Map<String, dynamic> json) {
    return TaskCardExtra(
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String,
      taskType: json['task_type'] as String,
      taskStatus: json['task_status'] as String,
      taskSummary: json['task_summary'] as String,
    );
  }
}
