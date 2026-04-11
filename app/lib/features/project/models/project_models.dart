class KanbanTask {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assignee;
  final String? milestoneId;
  final int effortHours;
  final bool isAtRisk;
  final String createdAt;
  final String? completedAt;
  final String? taskCode;
  final String? featureItemId;
  final String? earsType;

  const KanbanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.assignee,
    this.milestoneId,
    required this.effortHours,
    required this.isAtRisk,
    required this.createdAt,
    this.completedAt,
    this.taskCode,
    this.featureItemId,
    this.earsType,
  });

  bool get isTodo => status == 'todo';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  KanbanTask copyWith({String? status}) {
    return KanbanTask(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority,
      assignee: assignee,
      milestoneId: milestoneId,
      effortHours: effortHours,
      isAtRisk: isAtRisk,
      createdAt: createdAt,
      completedAt: status == 'completed' ? DateTime.now().toIso8601String() : completedAt,
      taskCode: taskCode,
      featureItemId: featureItemId,
      earsType: earsType,
    );
  }

  factory KanbanTask.fromJson(Map<String, dynamic> json) {
    return KanbanTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      assignee: json['assignee'] as String?,
      milestoneId: json['milestone_id'] as String?,
      effortHours: json['effort_hours'] as int? ?? 0,
      isAtRisk: json['is_at_risk'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
      taskCode: json['task_code'] as String?,
      featureItemId: json['feature_item_id'] as String?,
      earsType: json['ears_type'] as String?,
    );
  }
}

class Milestone {
  final String id;
  final String title;
  final String? description;
  final String status;
  final int progress;
  final String dueDate;
  final double amount;
  final int taskCount;
  final int completedTaskCount;
  final List<String> featureItemIds;
  final List<Map<String, dynamic>> phases;
  final double? estimatedDays;
  final double? paymentRatio;

  const Milestone({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.progress,
    required this.dueDate,
    required this.amount,
    required this.taskCount,
    required this.completedTaskCount,
    this.featureItemIds = const [],
    this.phases = const [],
    this.estimatedDays,
    this.paymentRatio,
  });

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';
  bool get isDelivered => status == 'delivered';
  bool get isRevisionRequested => status == 'revision_requested';

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      progress: json['progress'] as int? ?? 0,
      dueDate: json['due_date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      taskCount: json['task_count'] as int? ?? 0,
      completedTaskCount: json['completed_task_count'] as int? ?? 0,
      featureItemIds: (json['feature_item_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      phases: (json['phases'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [],
      estimatedDays: (json['estimated_days'] as num?)?.toDouble(),
      paymentRatio: (json['payment_ratio'] as num?)?.toDouble(),
    );
  }
}

class DailyReport {
  final String id;
  final String date;
  final String summary;
  final List<String> completedTasks;
  final List<String> inProgressTasks;
  final List<String> riskItems;
  final String tomorrowPlan;

  const DailyReport({
    required this.id,
    required this.date,
    required this.summary,
    this.completedTasks = const [],
    this.inProgressTasks = const [],
    this.riskItems = const [],
    required this.tomorrowPlan,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id'] as String,
      date: json['date'] as String,
      summary: json['summary'] as String,
      completedTasks: (json['completed_tasks'] as List?)?.cast<String>() ?? [],
      inProgressTasks:
          (json['in_progress_tasks'] as List?)?.cast<String>() ?? [],
      riskItems: (json['risk_items'] as List?)?.cast<String>() ?? [],
      tomorrowPlan: json['tomorrow_plan'] as String,
    );
  }
}

enum ProjectTab { kanban, milestone, prd, files, report }

class ProjectFile {
  final String uuid;
  final String fileKind;
  final String originalName;
  final String contentType;
  final int sizeBytes;
  final String? milestoneId;
  final String? uploadedByNickname;
  final DateTime createdAt;
  final String? downloadUrl;

  const ProjectFile({
    required this.uuid,
    required this.fileKind,
    required this.originalName,
    required this.contentType,
    required this.sizeBytes,
    this.milestoneId,
    this.uploadedByNickname,
    required this.createdAt,
    this.downloadUrl,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      uuid: json['uuid'] as String? ?? '',
      fileKind: json['file_kind'] as String? ?? 'reference',
      originalName: json['original_name'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      sizeBytes: json['size_bytes'] as int? ?? 0,
      milestoneId: json['milestone_id'] as String?,
      uploadedByNickname: json['uploaded_by_nickname'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      downloadUrl: json['download_url'] as String?,
    );
  }

  String get displaySize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}
