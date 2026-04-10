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
}
