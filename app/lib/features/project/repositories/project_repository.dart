import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/project_model.dart';
import '../models/project_models.dart';

class ProjectRepository {
  final ApiClient _client = ApiClient();

  /// 获取"我的项目"列表，role: 1=项目方 (owner), 2=团队方 (assignee)
  Future<List<ProjectModel>> fetchMyProjects({int role = 1}) async {
    final response = await _client.get(
      ApiEndpoints.projects,
      queryParameters: {'role': role.toString()},
    );
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ProjectModel.fromJson(e))
        .toList();
  }

  Future<List<KanbanTask>> fetchTasks(String projectId) async {
    final response = await _client.get(ApiEndpoints.projectTasks(projectId));
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => KanbanTask.fromJson(e))
        .toList();
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _client.put(
      ApiEndpoints.taskStatus(taskId),
      data: {'status': newStatus},
    );
  }

  Future<List<Milestone>> fetchMilestones(String projectId) async {
    final response =
        await _client.get(ApiEndpoints.projectMilestones(projectId));
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Milestone.fromJson(e))
        .toList();
  }

  Future<void> completeMilestone(String milestoneId) async {
    await _client.post(ApiEndpoints.milestoneComplete(milestoneId));
  }

  Future<void> deliverProject(
    String projectId, {
    String? note,
    String? previewUrl,
  }) async {
    final data = <String, dynamic>{};
    if (note != null && note.isNotEmpty) data['delivery_note'] = note;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      data['preview_url'] = previewUrl;
    }
    await _client.post(
      ApiEndpoints.projectDeliver(projectId),
      data: data,
    );
  }

  Future<void> confirmAlignment(String projectId) async {
    await _client.post(ApiEndpoints.projectConfirmAlignment(projectId));
  }

  Future<void> startProject(String projectId) async {
    await _client.post(ApiEndpoints.projectStart(projectId));
  }

  Future<List<DailyReport>> fetchDailyReports(String projectId) async {
    final response =
        await _client.get(ApiEndpoints.projectDailyReports(projectId));
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => DailyReport.fromJson(e))
        .toList();
  }

  Future<void> startMilestone(String milestoneId) async {
    await _client.post(ApiEndpoints.milestoneStart(milestoneId));
  }

  Future<void> deliverMilestone(String milestoneId,
      {String? note, String? previewUrl}) async {
    await _client.post(
      ApiEndpoints.milestoneDeliver(milestoneId),
      data: {
        if (note != null) 'note': note,
        if (previewUrl != null) 'preview_url': previewUrl,
      },
    );
  }

  Future<void> acceptMilestone(String milestoneId) async {
    await _client.post(ApiEndpoints.milestoneAccept(milestoneId));
  }

  Future<void> requestRevision(String milestoneId, {String? reason}) async {
    await _client.post(
      ApiEndpoints.milestoneRevision(milestoneId),
      data: {if (reason != null) 'reason': reason},
    );
  }

  Future<List<ProjectFile>> fetchFiles(String projectId,
      {String? fileKind}) async {
    final response = await _client.get(
      ApiEndpoints.projectFiles(projectId),
      queryParameters: {if (fileKind != null) 'file_kind': fileKind},
    );
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ProjectFile.fromJson(e))
        .toList();
  }

  Future<String> fetchFileDownloadUrl(String projectId, String uuid) async {
    final response = await _client.get(
      ApiEndpoints.projectFileDetail(projectId, uuid),
    );
    return (response.data as Map<String, dynamic>?)?['download_url']
            as String? ??
        '';
  }
}
