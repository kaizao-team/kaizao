import '../config/app_env.dart';

/// 所有 API 端点常量
/// 从技术架构文档和API设计文档提取
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => AppEnv.baseUrl;
  static String get wsUrl => AppEnv.wsUrl;

  // ============================================================
  // 认证模块 /api/v1/auth
  // ============================================================
  static const String sendSmsCode = '/api/v1/auth/sms-code';
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String wechatLogin = '/api/v1/auth/wechat';
  static const String refreshToken = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String passwordKey = '/api/v1/auth/password-key';
  static const String captcha = '/api/v1/auth/captcha';
  static const String loginPassword = '/api/v1/auth/login-password';
  static const String registerPassword = '/api/v1/auth/register-password';

  // ============================================================
  // 用户模块 /api/v1/users
  // ============================================================
  static String userInfo(String id) => '/api/v1/users/$id';
  static String updateUser(String id) => '/api/v1/users/$id';
  static String userProfile(String id) => '/api/v1/users/$id/profile';
  static String userCertifications(String id) =>
      '/api/v1/users/$id/certifications';
  static String userVerification(String id) => '/api/v1/users/$id/verification';
  static String userReviews(String id) => '/api/v1/users/$id/reviews';
  static String userCredit(String id) => '/api/v1/users/$id/credit';
  static String userSkills(String id) => '/api/v1/users/$id/skills';
  static String userPortfolios(String id) => '/api/v1/users/$id/portfolios';
  static const String currentUser = '/api/v1/users/me';

  // ============================================================
  // 首页聚合 /api/v1/home
  // ============================================================
  static const String homeDemander = '/api/v1/home/demander';
  static const String homeExpert = '/api/v1/home/expert';

  // ============================================================
  // 需求广场 /api/v1/market
  // ============================================================
  static const String marketProjects = '/api/v1/market/projects';
  static const String marketExperts = '/api/v1/market/experts';

  // ============================================================
  // 需求发布 /api/v1/projects (POST 模块)
  // ============================================================
  static const String projectAiChat = '/api/v1/projects/ai-chat';
  static const String projectGeneratePrd = '/api/v1/projects/generate-prd';
  static const String projectDraft = '/api/v1/projects/draft';

  // ============================================================
  // PRD 视图 /api/v1/projects/:id/prd
  // ============================================================
  static String projectPrd(String id) => '/api/v1/projects/$id/prd';
  static String prdCardUpdate(String projectId, String cardId) =>
      '/api/v1/projects/$projectId/prd/cards/$cardId';

  // ============================================================
  // 项目/需求模块 /api/v1/projects
  // ============================================================
  static const String projects = '/api/v1/projects';
  static String projectDetail(String id) => '/api/v1/projects/$id';
  static String projectPublish(String id) => '/api/v1/projects/$id/publish';
  static String projectOverview(String id) => '/api/v1/projects/$id/overview';
  static String projectTasks(String id) => '/api/v1/projects/$id/tasks';
  static String projectMilestones(String id) =>
      '/api/v1/projects/$id/milestones';
  static String projectReviews(String id) => '/api/v1/projects/$id/reviews';
  static String projectDailyReports(String id) =>
      '/api/v1/projects/$id/daily-reports';
  static String projectAiAssist(String id) => '/api/v1/projects/$id/ai-assist';
  static String projectAttachments(String id) =>
      '/api/v1/projects/$id/attachments';
  static String projectClose(String id) => '/api/v1/projects/$id/close';
  static const String projectSearch = '/api/v1/projects/search';

  // ============================================================
  // 任务卡片模块 /api/v1/tasks
  // ============================================================
  static String taskDetail(String id) => '/api/v1/tasks/$id';
  static String taskStatus(String id) => '/api/v1/tasks/$id/status';

  // ============================================================
  // 里程碑模块 /api/v1/milestones
  // ============================================================
  static String milestoneDeliver(String id) => '/api/v1/milestones/$id/deliver';
  static String milestoneAccept(String id) => '/api/v1/milestones/$id/accept';
  static String milestoneAcceptance(String id) =>
      '/api/v1/milestones/$id/acceptance';
  static String milestoneRevision(String id) =>
      '/api/v1/milestones/$id/revision';

  // ============================================================
  // 评论模块 /api/v1/projects/:id/comments
  // ============================================================
  static String projectComments(String projectId) =>
      '/api/v1/projects/$projectId/comments';

  // ============================================================
  // 投标/撮合模块 /api/v1/bids
  // ============================================================
  static String projectAiSuggestion(String projectId) =>
      '/api/v1/projects/$projectId/ai-suggestion';
  static String projectBids(String projectId) =>
      '/api/v1/projects/$projectId/bids';
  static String bidAccept(String id) => '/api/v1/bids/$id/accept';
  static String bidReject(String id) => '/api/v1/bids/$id/reject';
  static String projectRecommendations(String projectId) =>
      '/api/v1/projects/$projectId/recommendations';
  static String recommendedProjects(String userId) =>
      '/api/v1/users/$userId/recommended-projects';
  static String quickMatch(String projectId) =>
      '/api/v1/projects/$projectId/quick-match';

  // ============================================================
  // 交易/支付模块 /api/v1/orders
  // ============================================================
  static const String orders = '/api/v1/orders';
  static String orderPrepay(String id) => '/api/v1/orders/$id/prepay';
  static String orderRelease(String id) => '/api/v1/orders/$id/release';
  static String orderRefund(String id) => '/api/v1/orders/$id/refund';
  static String orderSplit(String id) => '/api/v1/orders/$id/split';
  static String orderDetail(String id) => '/api/v1/orders/$id';
  static String orderStatus(String id) => '/api/v1/orders/$id/status';
  static const String coupons = '/api/v1/coupons';
  static const String walletBalance = '/api/v1/wallet/balance';
  static const String walletWithdraw = '/api/v1/wallet/withdraw';
  static const String walletTransactions = '/api/v1/wallet/transactions';

  // ============================================================
  // 消息/沟通模块 /api/v1/conversations
  // ============================================================
  static const String conversations = '/api/v1/conversations';
  static String conversationDetail(String id) => '/api/v1/conversations/$id';
  static String conversationMessages(String id) =>
      '/api/v1/conversations/$id/messages';
  static String conversationRead(String id) => '/api/v1/conversations/$id/read';
  static const String messageUpload = '/api/v1/messages/upload';

  // ============================================================
  // 通知模块 /api/v1/notifications
  // ============================================================
  static const String notifications = '/api/v1/notifications';
  static String notificationRead(String id) => '/api/v1/notifications/$id/read';
  static const String notificationReadAll = '/api/v1/notifications/read-all';

  // ============================================================
  // 评价模块 /api/v1/reviews
  // ============================================================
  static const String reviews = '/api/v1/reviews';

  // ============================================================
  // 团队模块 /api/v1/teams
  // ============================================================
  static const String teams = '/api/v1/teams';
  static String teamDetail(String id) => '/api/v1/teams/$id';
  static String teamInvite(String id) => '/api/v1/teams/$id/invite';
  static String teamSplitRatio(String id) => '/api/v1/teams/$id/split-ratio';
  static String teamInviteRespond(String id) => '/api/v1/team-invites/$id';
  static const String teamPosts = '/api/v1/team-posts';
  static const String teamAiRecommend = '/api/v1/teams/ai-recommend';
  static String teamBid(String projectId) =>
      '/api/v1/projects/$projectId/team-bids';

  // ============================================================
  // 举报/仲裁
  // ============================================================
  static const String reports = '/api/v1/reports';
  static const String arbitrations = '/api/v1/arbitrations';

  // ============================================================
  // 收藏
  // ============================================================
  static const String favorites = '/api/v1/favorites';

  // ============================================================
  // AI Agent 会话
  // ============================================================
  static const String agentSessions = '/api/v1/agent-sessions';
  static String agentSessionDetail(String id) => '/api/v1/agent-sessions/$id';
  static String agentSessionMessage(String id) =>
      '/api/v1/agent-sessions/$id/message';

  // ============================================================
  // Pipeline v2 (project lifecycle)
  // ============================================================
  static const String pipelineStart = '/api/v2/pipeline/start';
  static String pipelineStatus(String projectId) =>
      '/api/v2/pipeline/$projectId/status';

  // ============================================================
  // AI Agent v2 (Python service, direct connection)
  // ============================================================
  static const String aiAgentStart = '/api/v2/requirement/start';
  static String aiAgentMessage(String projectId) =>
      '/api/v2/requirement/$projectId/message';
  static String aiAgentConfirm(String projectId) =>
      '/api/v2/requirement/$projectId/confirm';
  static String aiAgentDecompose(String projectId) =>
      '/api/v2/requirement/$projectId/decompose';

  // SSE streaming variants
  static const String aiAgentStartStream = '/api/v2/requirement/start/stream';
  static String aiAgentMessageStream(String projectId) =>
      '/api/v2/requirement/$projectId/message/stream';
  static String aiAgentDecomposeStream(String projectId) =>
      '/api/v2/requirement/$projectId/decompose/stream';

  // Requirement document
  static String requirementDocument(String projectId) =>
      '/api/v2/requirement/$projectId/document';

  // Match / recommend
  static const String matchRecommend = '/api/v2/match/recommend';

  // ============================================================
  // 文件上传
  // ============================================================
  static const String uploadFile = '/api/v1/upload';
  static const String uploadImage = '/api/v1/upload/image';
}
