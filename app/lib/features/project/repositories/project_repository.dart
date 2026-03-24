import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/project_models.dart';

class ProjectRepository {
  final ApiClient _client = ApiClient();

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
