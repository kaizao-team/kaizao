import 'package:dio/dio.dart';
import '../mock_interceptor.dart';
import 'market_mock.dart';

class PostMock {
  PostMock._();

  static int _draftCount = 0;
  static final _conversationStates = <String, _MockConversationState>{};

  static void register(Map<String, MockHandler> handlers) {
    handlers['POST:/api/v1/projects/ai-chat'] = MockHandler(
      delayMs: 600,
      handler: (options) => _aiChat(options),
    );

    handlers['POST:/api/v1/projects/generate-prd'] = MockHandler(
      delayMs: 2000,
      handler: (options) => _generatePrd(options),
    );

    handlers['POST:/api/v1/projects/draft'] = MockHandler(
      delayMs: 300,
      handler: (options) => _saveDraft(options),
    );

    handlers['PUT:/api/v1/projects/:id'] = MockHandler(
      delayMs: 300,
      handler: (options) => _updateDraft(options),
    );

    handlers['POST:/api/v1/projects/:id/publish'] = MockHandler(
      delayMs: 300,
      handler: (options) => _publishDraft(options),
    );

    handlers['POST:/api/v1/projects'] = MockHandler(
      delayMs: 500,
      handler: (options) => _publishProject(options),
    );
  }

  static final _categoryScripts = <String, List<Map<String, dynamic>>>{
    'data': [
      {
        'reply':
            '收到，你提到「{{userMessage}}」。这次数据项目里最需要先解决的业务问题是什么？是增长、转化、留存，还是某个运营环节的效率判断？',
        'completeness_score': 20,
        'can_generate_prd': false,
      },
      {
        'reply':
            '我先按「{{userMessage}}」理解为一项需要沉淀分析口径的任务。现在请告诉我已有的数据源有哪些，比如业务库、埋点、CRM 或 Excel，口径是否已经统一？',
        'completeness_score': 40,
        'can_generate_prd': false,
      },
      {
        'reply':
            '围绕「{{userMessage}}」，目标已经开始清晰了。还想确认最终交付更偏实时 dashboard、固定周期报告，还是一次专项分析结论？这些信息已经足够先生成 PRD，但补充越细，后面模块越准。',
        'completeness_score': 60,
        'can_generate_prd': true,
      },
      {
        'reply':
            '基于你刚才补充的「{{userMessage}}」，我现在基本能拆出数据接入、指标建模和结果展示三层结构。还差两个关键点：谁是主要查看人，以及期望上线时间或分析周期是什么？现在已经可以生成 PRD。',
        'completeness_score': 80,
        'can_generate_prd': true,
      },
      {
        'reply':
            '我把「{{userMessage}}」相关需求汇总一下：要先明确业务问题，接着梳理数据源与指标口径，最后交付可复用的分析结果或看板。信息已经足够生成完整 PRD，最后请确认是否还有权限、合规、预算或跨部门协作方面的限制？',
        'completeness_score': 100,
        'can_generate_prd': true,
      },
    ],
    'dev': [
      {
        'reply':
            '明白，你提到「{{userMessage}}」。先抓最核心的一层：第一版必须上线的功能有哪些？哪些是没有就不能发布的 P0 功能？',
        'completeness_score': 20,
        'can_generate_prd': false,
      },
      {
        'reply':
            '我先把「{{userMessage}}」视为一个需要快速定义范围的软件项目。目标用户是谁，他们进入产品后最先要完成的关键动作是什么？',
        'completeness_score': 40,
        'can_generate_prd': false,
      },
      {
        'reply':
            '结合你刚补充的「{{userMessage}}」，需求主线已经有了。现在请确认交付平台和技术偏好：是 Web、App、小程序，还是多端一起上？这一步确认后就已经可以先生成 PRD。',
        'completeness_score': 60,
        'can_generate_prd': true,
      },
      {
        'reply':
            '按目前对「{{userMessage}}」的理解，我可以开始拆认证、核心流程和管理后台了。还想补上时间线与约束：预计什么时候上线，是否有现有系统、接口或合规要求需要兼容？现在已经足够生成 PRD。',
        'completeness_score': 80,
        'can_generate_prd': true,
      },
      {
        'reply':
            '我把这轮围绕「{{userMessage}}」的研发需求汇总一下：目标用户、核心功能、交付平台、技术边界和上线节奏都已经基本齐了。信息足够生成完整 PRD，最后请确认是否还存在预算、第三方集成或团队协作上的限制？',
        'completeness_score': 100,
        'can_generate_prd': true,
      },
    ],
    'design': [
      {
        'reply':
            '收到，你说的是「{{userMessage}}」。这次设计项目最先要解决的是什么，品牌识别、界面体验、营销表达，还是转化效率？',
        'completeness_score': 20,
        'can_generate_prd': false,
      },
      {
        'reply':
            '我先按「{{userMessage}}」理解为需要统一视觉方向的一次设计交付。现在是否已经有 logo、品牌色、字体、参考案例或明确不能碰的风格限制？',
        'completeness_score': 40,
        'can_generate_prd': false,
      },
      {
        'reply':
            '围绕「{{userMessage}}」，我已经能初步判断交付范围了。最终你更需要高保真页面、完整品牌视觉包，还是一套可复用的 design system？这些信息已经足够先生成 PRD。',
        'completeness_score': 60,
        'can_generate_prd': true,
      },
      {
        'reply':
            '结合你对「{{userMessage}}」的补充，我可以开始拆品牌、界面和规范三个层级。还差受众场景与执行限制：主要面对谁、在哪些渠道使用、可接受几轮修改，以及是否需要和研发同步落地？现在已经能生成 PRD。',
        'completeness_score': 80,
        'can_generate_prd': true,
      },
      {
        'reply':
            '我把「{{userMessage}}」这类设计需求整理一下：目标、风格方向、交付清单、受众场景与协作方式都已经比较完整。现在足够生成完整 PRD，最后请确认是否还有品牌审批、素材准备或工期上的硬约束？',
        'completeness_score': 100,
        'can_generate_prd': true,
      },
    ],
    'solution': [
      {
        'reply':
            '明白，你提到「{{userMessage}}」。先确认这次方案项目最核心的问题是什么，最终希望解决方向判断、执行路径，还是资源组织效率？',
        'completeness_score': 20,
        'can_generate_prd': false,
      },
      {
        'reply':
            '我先把「{{userMessage}}」理解成一项需要先梳理再落地的咨询任务。当前项目进行到哪一步，已经有哪些前提、资料或既定决策不能动？',
        'completeness_score': 40,
        'can_generate_prd': false,
      },
      {
        'reply':
            '结合你刚才关于「{{userMessage}}」的描述，问题边界已经开始成形。最终输出更偏策略文档、实施路径图、阶段性里程碑，还是陪跑式拆解方案？这些信息已经足够先生成 PRD。',
        'completeness_score': 60,
        'can_generate_prd': true,
      },
      {
        'reply':
            '按目前对「{{userMessage}}」的理解，我可以开始拆研究诊断、策略设计和落地计划了。还想补上关键干系人、决策节奏，以及最大的风险或约束条件是什么。现在已经可以生成 PRD。',
        'completeness_score': 80,
        'can_generate_prd': true,
      },
      {
        'reply':
            '我把围绕「{{userMessage}}」的解决方案需求汇总一下：问题定义、现状前提、输出形式、关键干系人与落地约束都已经比较明确。信息足够生成完整 PRD，最后请确认是否还要纳入预算、组织协同或阶段验收方面的要求？',
        'completeness_score': 100,
        'can_generate_prd': true,
      },
    ],
  };

  static const _categoryLabels = <String, String>{
    'data': '数据分析',
    'dev': '软件研发',
    'design': '视觉设计',
    'visual': '视觉设计',
    'solution': '解决方案',
  };

  static Map<String, dynamic> _aiChat(RequestOptions options) {
    final data = options.data as Map<String, dynamic>? ?? {};
    final userMessage = data['message'] as String? ?? '';
    final category = _normalizeCategory(data['category'] as String?);
    final scripts = _categoryScripts[category] ?? _categoryScripts['dev']!;
    final conversationKey = _resolveConversationKey(data);
    final turnCount = conversationKey == null
        ? 1
        : _nextConversationTurn(
            conversationKey: conversationKey,
            category: category,
          );
    final scriptIndex =
        turnCount <= scripts.length ? turnCount - 1 : scripts.length - 1;
    final script = scripts[scriptIndex];
    final safeMessage =
        userMessage.trim().isEmpty ? _defaultUserMessage(category) : userMessage.trim();
    final reply = (script['reply'] as String? ?? '')
        .replaceAll('{{userMessage}}', safeMessage);
    final completenessScore = script['completeness_score'] as int? ?? 0;
    final canGeneratePrd =
        script['can_generate_prd'] as bool? ?? completenessScore >= 60;

    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'reply': reply,
        'can_generate_prd': canGeneratePrd,
        'completeness_score': completenessScore,
        'turn': turnCount,
      },
    };
  }

  static Map<String, dynamic> _generatePrd(RequestOptions options) {
    final data = options.data as Map<String, dynamic>? ?? {};
    final category = _normalizeCategory(data['category'] as String?);
    final chatHistory = data['chat_history'] as List? ?? const [];
    final focus = _extractFocus(chatHistory, category);
    final prd = _buildPrd(category, focus, chatHistory);

    return {
      'code': 0,
      'message': 'ok',
      'data': prd,
    };
  }

  static String _normalizeCategory(String? category) {
    final normalized = category?.trim().toLowerCase();
    if (normalized == 'visual') {
      return 'design';
    }
    if (_categoryScripts.containsKey(normalized)) {
      return normalized!;
    }
    return 'dev';
  }

  static String? _resolveConversationKey(Map<String, dynamic> data) {
    final candidates = [
      data['project_id'],
      data['draft_id'],
      data['uuid'],
      data['id'],
      data['session_id'],
    ];
    for (final candidate in candidates) {
      final key = candidate?.toString().trim();
      if (key != null && key.isNotEmpty) {
        return key;
      }
    }
    return 'legacy:${data['category']?.toString().trim().toLowerCase() ?? 'dev'}';
  }

  static int _nextConversationTurn({
    required String conversationKey,
    required String category,
  }) {
    final current = _conversationStates[conversationKey];
    final nextTurn = current == null || current.category != category
        ? 1
        : current.turnCount + 1;
    _conversationStates[conversationKey] = _MockConversationState(
      category: category,
      turnCount: nextTurn,
    );
    return nextTurn;
  }

  static String _defaultUserMessage(String category) {
    return '${_categoryLabels[category] ?? '项目'}需求';
  }

  static String _extractFocus(List<dynamic> chatHistory, String category) {
    final userMessages = chatHistory
        .whereType<Map<String, dynamic>>()
        .where((item) => item['role'] == 'user')
        .map((item) => item['content']?.toString().trim() ?? '')
        .where((text) => text.isNotEmpty)
        .toList();

    if (userMessages.isEmpty) {
      return _defaultUserMessage(category);
    }

    final raw = userMessages.first
        .replaceAll('\n', ' ')
        .replaceAll('，', ' ')
        .replaceAll('。', ' ')
        .replaceAll('？', ' ')
        .replaceAll('！', ' ')
        .replaceAll('、', ' ')
        .replaceAll(',', ' ')
        .replaceAll('.', ' ')
        .trim();
    final compact = raw.replaceAll(RegExp(r'\s+'), ' ');

    if (compact.isEmpty) {
      return _defaultUserMessage(category);
    }

    return compact.length > 16 ? compact.substring(0, 16) : compact;
  }

  static String _conversationBrief(List<dynamic> chatHistory, String category) {
    final userMessages = chatHistory
        .whereType<Map<String, dynamic>>()
        .where((item) => item['role'] == 'user')
        .map((item) => item['content']?.toString().trim() ?? '')
        .where((text) => text.isNotEmpty)
        .toList();

    if (userMessages.isEmpty) {
      return '当前主要围绕${_categoryLabels[category] ?? '项目需求'}展开';
    }

    final summary = userMessages.take(2).join('；');
    return summary.length > 48 ? '${summary.substring(0, 48)}...' : summary;
  }

  static Map<String, dynamic> _buildPrd(
    String category,
    String focus,
    List<dynamic> chatHistory,
  ) {
    final brief = _conversationBrief(chatHistory, category);

    switch (category) {
      case 'data':
        return {
          'prd_id': 'prd_data_001',
          'title': '$focus 数据分析项目 PRD',
          'modules': _buildDataModules(focus, brief),
          'budget_suggestion': {
            'min': 12000,
            'max': 24000,
            'reason': '围绕「$focus」的数据项目通常包含数据接入、指标建模与结果展示三层工作，建议预算控制在 ¥12,000 - ¥24,000。',
          },
        };
      case 'design':
        return {
          'prd_id': 'prd_design_001',
          'title': '$focus 设计项目 PRD',
          'modules': _buildDesignModules(focus, brief),
          'budget_suggestion': {
            'min': 8000,
            'max': 18000,
            'reason': '结合「$focus」的品牌与界面交付范围，建议预算区间为 ¥8,000 - ¥18,000，能覆盖视觉探索、页面输出与规范沉淀。',
          },
        };
      case 'solution':
        return {
          'prd_id': 'prd_solution_001',
          'title': '$focus 解决方案 PRD',
          'modules': _buildSolutionModules(focus, brief),
          'budget_suggestion': {
            'min': 12000,
            'max': 28000,
            'reason': '围绕「$focus」的咨询方案通常需要研究诊断、策略设计与实施路径三段投入，建议预算区间为 ¥12,000 - ¥28,000。',
          },
        };
      case 'dev':
      default:
        return {
          'prd_id': 'prd_dev_001',
          'title': '$focus 软件产品 PRD',
          'modules': _buildDevModules(focus, brief),
          'budget_suggestion': {
            'min': 18000,
            'max': 48000,
            'reason': '结合「$focus」的软件研发范围，建议预算区间为 ¥18,000 - ¥48,000，可覆盖认证、核心功能与后台管理交付。',
          },
        };
    }
  }

  static List<Map<String, dynamic>> _buildDataModules(
    String focus,
    String brief,
  ) {
    return [
      _buildModule(
        id: 'mod_data_pipeline',
        name: '数据管道',
        cards: [
          _buildCard(
            id: 'card_data_001',
            moduleId: 'mod_data_pipeline',
            title: '$focus 数据源接入',
            type: 'event',
            priority: 'P0',
            description: '梳理并接入与「$focus」相关的核心数据源，支撑后续分析链路。当前对话摘要：$brief',
            event: '项目启动并确认数据清单',
            action: '接入业务库、埋点表、外部表格或 CRM 数据',
            response: '形成统一的数据接入清单和同步方式',
            stateChange: '数据源状态从分散变为可统一拉取',
            acceptanceCriteria: [
              '至少完成 2 类核心数据源接入',
              '明确更新频率与负责人',
              '缺失字段与异常值有记录方案',
            ],
            roles: ['data', 'backend'],
            effortHours: 14,
            techTags: ['ETL', 'SQL'],
          ),
          _buildCard(
            id: 'card_data_002',
            moduleId: 'mod_data_pipeline',
            title: '$focus 指标口径定义',
            type: 'state',
            priority: 'P0',
            description: '为核心业务问题建立统一指标口径和计算逻辑。',
            event: '分析目标确认后',
            action: '沉淀指标定义、维度字段和口径说明',
            response: '输出可复用的指标字典',
            stateChange: '指标解释从口头约定变为文档化标准',
            acceptanceCriteria: [
              '核心指标均提供公式说明',
              '维度拆分规则可追溯',
              '业务方确认关键口径',
            ],
            roles: ['data', 'pm'],
            effortHours: 10,
            dependencies: ['card_data_001'],
            techTags: ['Metric', 'BI'],
          ),
          _buildCard(
            id: 'card_data_003',
            moduleId: 'mod_data_pipeline',
            title: '$focus 数据质量监控',
            type: 'response',
            priority: 'P1',
            description: '对关键表与核心指标建立质量检查与异常提醒。',
            event: '数据每日同步完成',
            action: '执行完整性、及时性和异常波动检测',
            response: '出现异常时生成提醒与修复清单',
            stateChange: '数据可用性从被动发现变为主动监控',
            acceptanceCriteria: [
              '每日自动校验任务可运行',
              '异常记录可回溯到字段级',
              '关键问题 1 小时内可见',
            ],
            roles: ['data'],
            effortHours: 8,
            dependencies: ['card_data_002'],
            techTags: ['Monitor', 'Alert'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_data_dashboard',
        name: 'Dashboard',
        cards: [
          _buildCard(
            id: 'card_data_004',
            moduleId: 'mod_data_dashboard',
            title: '$focus 核心看板',
            type: 'response',
            priority: 'P0',
            description: '为业务方提供面向核心目标的可视化看板。',
            event: '用户进入数据看板首页',
            action: '展示核心指标、趋势图和关键说明',
            response: '业务方可快速判断当前表现',
            stateChange: '核心数据从离散表格变为可视化总览',
            acceptanceCriteria: [
              '首页展示 5-8 个核心指标',
              '支持按时间筛选',
              '空状态和加载态完整',
            ],
            roles: ['data', 'design', 'frontend'],
            effortHours: 16,
            dependencies: ['card_data_002'],
            techTags: ['Dashboard', 'Charts'],
          ),
          _buildCard(
            id: 'card_data_005',
            moduleId: 'mod_data_dashboard',
            title: '$focus 下钻分析',
            type: 'action',
            priority: 'P1',
            description: '支持从总览进一步查看维度拆解与异常来源。',
            event: '用户点击某个核心指标',
            action: '按渠道、地区、产品或时间维度展开分析',
            response: '定位问题来源并支持导出视图',
            stateChange: '分析路径从单层查看变为多维探索',
            acceptanceCriteria: [
              '至少支持 3 个维度下钻',
              '筛选条件之间可以联动',
              '导出内容与页面一致',
            ],
            roles: ['data', 'frontend'],
            effortHours: 12,
            dependencies: ['card_data_004'],
            techTags: ['BI', 'Charts'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_data_reporting',
        name: 'Reporting',
        cards: [
          _buildCard(
            id: 'card_data_006',
            moduleId: 'mod_data_reporting',
            title: '$focus 定期报告',
            type: 'event',
            priority: 'P1',
            description: '将分析结果整理为固定节奏的周报或月报。',
            event: '到达约定汇报周期',
            action: '自动汇总指标并生成结构化报告',
            response: '输出适合分享给管理层的结论摘要',
            stateChange: '汇报材料从人工整理变为模板化输出',
            acceptanceCriteria: [
              '支持周报和月报两种模板',
              '结论区包含异常说明',
              '可导出 PDF 或图片',
            ],
            roles: ['data', 'pm'],
            effortHours: 8,
            dependencies: ['card_data_004'],
            techTags: ['Report', 'Export'],
          ),
          _buildCard(
            id: 'card_data_007',
            moduleId: 'mod_data_reporting',
            title: '$focus 异常预警',
            type: 'response',
            priority: 'P1',
            description: '对重点指标建立阈值预警与提醒规则。',
            event: '指标触发波动阈值',
            action: '生成异常提醒并附上关联数据说明',
            response: '相关人及时收到预警消息',
            stateChange: '异常响应从延迟发现变为即时通知',
            acceptanceCriteria: [
              '支持按指标配置阈值',
              '提醒对象可配置',
              '预警记录可追踪',
            ],
            roles: ['data', 'backend'],
            effortHours: 6,
            dependencies: ['card_data_003'],
            techTags: ['Alert', 'Notification'],
          ),
        ],
      ),
    ];
  }

  static List<Map<String, dynamic>> _buildDevModules(
    String focus,
    String brief,
  ) {
    return [
      _buildModule(
        id: 'mod_dev_auth',
        name: 'Auth',
        cards: [
          _buildCard(
            id: 'card_dev_001',
            moduleId: 'mod_dev_auth',
            title: '$focus 账号注册登录',
            type: 'event',
            priority: 'P0',
            description: '建立基础登录注册流程，为「$focus」项目提供可控身份入口。当前对话摘要：$brief',
            event: '用户首次进入产品',
            action: '支持手机号或邮箱完成注册与登录',
            response: '成功进入主流程，失败提供明确反馈',
            stateChange: '用户从访客状态切换为已登录状态',
            acceptanceCriteria: [
              '注册登录流程可闭环完成',
              '错误提示覆盖常见异常',
              '支持基础安全校验',
            ],
            roles: ['frontend', 'backend'],
            effortHours: 12,
            techTags: ['Auth', 'JWT'],
          ),
          _buildCard(
            id: 'card_dev_002',
            moduleId: 'mod_dev_auth',
            title: '$focus 权限角色',
            type: 'state',
            priority: 'P1',
            description: '按用户角色控制页面和功能权限。',
            event: '用户登录并进入系统',
            action: '根据角色加载不同权限范围',
            response: '不同身份看到对应菜单和数据',
            stateChange: '访问控制从统一入口变为分角色治理',
            acceptanceCriteria: [
              '至少支持 2 类角色',
              '菜单与接口权限一致',
              '权限变更可即时生效',
            ],
            roles: ['backend', 'frontend'],
            effortHours: 8,
            dependencies: ['card_dev_001'],
            techTags: ['RBAC', 'Security'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_dev_core',
        name: 'Core Features',
        cards: [
          _buildCard(
            id: 'card_dev_003',
            moduleId: 'mod_dev_core',
            title: '$focus 核心业务流程',
            type: 'action',
            priority: 'P0',
            description: '实现围绕「$focus」的主流程交互与关键页面。',
            event: '用户完成登录后进入产品',
            action: '按核心路径完成浏览、提交、查看或处理动作',
            response: '形成 MVP 可验证的业务闭环',
            stateChange: '产品从静态页面变为可用主流程',
            acceptanceCriteria: [
              '核心流程可从头到尾跑通',
              '关键页面状态完整',
              '异常流程有兜底处理',
            ],
            roles: ['frontend', 'backend', 'pm'],
            effortHours: 24,
            dependencies: ['card_dev_001'],
            techTags: ['Flutter', 'API'],
          ),
          _buildCard(
            id: 'card_dev_004',
            moduleId: 'mod_dev_core',
            title: '$focus 消息通知',
            type: 'response',
            priority: 'P1',
            description: '在关键节点提供站内消息或推送提醒。',
            event: '用户状态或任务发生变化',
            action: '触发消息模板并投递到对应渠道',
            response: '用户能及时感知重要事件',
            stateChange: '系统反馈从被动查看变为主动提醒',
            acceptanceCriteria: [
              '覆盖至少 3 类核心通知',
              '已读未读状态可区分',
              '通知内容支持跳转详情',
            ],
            roles: ['frontend', 'backend'],
            effortHours: 10,
            dependencies: ['card_dev_003'],
            techTags: ['Message', 'Push'],
          ),
          _buildCard(
            id: 'card_dev_005',
            moduleId: 'mod_dev_core',
            title: '$focus 数据列表与详情',
            type: 'response',
            priority: 'P1',
            description: '沉淀主对象的列表、筛选和详情展示能力。',
            event: '用户查看业务对象',
            action: '支持搜索、筛选、排序和详情查看',
            response: '信息浏览效率提升并可继续操作',
            stateChange: '数据访问从零散状态变为结构化管理',
            acceptanceCriteria: [
              '支持分页与筛选',
              '详情信息字段完整',
              '列表性能满足常规数据量',
            ],
            roles: ['frontend', 'backend'],
            effortHours: 14,
            dependencies: ['card_dev_003'],
            techTags: ['List', 'Detail'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_dev_admin',
        name: 'Admin',
        cards: [
          _buildCard(
            id: 'card_dev_006',
            moduleId: 'mod_dev_admin',
            title: '$focus 管理后台',
            type: 'event',
            priority: 'P1',
            description: '为运营或管理员提供基础管理入口。',
            event: '管理员进入后台',
            action: '查看业务数据、处理异常和维护配置',
            response: '后台能支撑日常运营动作',
            stateChange: '运营支持从手工处理变为后台管理',
            acceptanceCriteria: [
              '后台菜单结构清晰',
              '关键操作有确认机制',
              '核心数据可查询',
            ],
            roles: ['frontend', 'backend'],
            effortHours: 16,
            dependencies: ['card_dev_002', 'card_dev_003'],
            techTags: ['Admin', 'Dashboard'],
          ),
          _buildCard(
            id: 'card_dev_007',
            moduleId: 'mod_dev_admin',
            title: '$focus 配置中心',
            type: 'state',
            priority: 'P2',
            description: '支持维护基础配置、标签、文案或业务规则。',
            event: '管理员调整业务参数',
            action: '更新配置并记录变更',
            response: '前台逻辑按新配置生效',
            stateChange: '配置从写死代码变为后台可维护',
            acceptanceCriteria: [
              '关键配置可增删改查',
              '变更记录可回溯',
              '错误配置有校验',
            ],
            roles: ['backend', 'frontend'],
            effortHours: 10,
            dependencies: ['card_dev_006'],
            techTags: ['Config', 'Ops'],
          ),
        ],
      ),
    ];
  }

  static List<Map<String, dynamic>> _buildDesignModules(
    String focus,
    String brief,
  ) {
    return [
      _buildModule(
        id: 'mod_design_brand',
        name: '品牌识别',
        cards: [
          _buildCard(
            id: 'card_design_001',
            moduleId: 'mod_design_brand',
            title: '$focus 品牌方向定义',
            type: 'event',
            priority: 'P0',
            description: '梳理「$focus」项目的品牌定位、调性和核心视觉方向。当前对话摘要：$brief',
            event: '设计项目启动',
            action: '整理品牌目标、受众和参考案例',
            response: '输出清晰的视觉方向说明',
            stateChange: '品牌表达从模糊描述变为可执行方向',
            acceptanceCriteria: [
              '产出 1 份方向说明',
              '包含关键词与风格边界',
              '业务方完成方向确认',
            ],
            roles: ['design', 'pm'],
            effortHours: 8,
            techTags: ['Brand'],
          ),
          _buildCard(
            id: 'card_design_002',
            moduleId: 'mod_design_brand',
            title: '$focus 基础视觉资产',
            type: 'response',
            priority: 'P1',
            description: '建立 logo、色彩、字体等基础视觉元素。',
            event: '品牌方向确认后',
            action: '输出核心视觉资产与组合规范',
            response: '形成可复用的品牌基础物料',
            stateChange: '视觉元素从零散素材变为统一资产',
            acceptanceCriteria: [
              '颜色与字体方案完整',
              '主视觉样式可复用',
              '资产导出格式齐全',
            ],
            roles: ['design'],
            effortHours: 12,
            dependencies: ['card_design_001'],
            techTags: ['Visual', 'Brand'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_design_ui',
        name: 'UI 设计',
        cards: [
          _buildCard(
            id: 'card_design_003',
            moduleId: 'mod_design_ui',
            title: '$focus 关键页面高保真',
            type: 'action',
            priority: 'P0',
            description: '完成围绕核心流程的关键页面高保真设计。',
            event: '交互流程明确后',
            action: '输出首页、详情页、转化页等关键页面方案',
            response: '关键路径具备统一且可评审的视觉方案',
            stateChange: '页面从线框或概念变为高保真交付',
            acceptanceCriteria: [
              '至少交付 3 个关键页面',
              '页面状态覆盖正常与异常情况',
              '设计稿可直接进入评审',
            ],
            roles: ['design'],
            effortHours: 18,
            dependencies: ['card_design_001'],
            techTags: ['Figma', 'UI'],
          ),
          _buildCard(
            id: 'card_design_004',
            moduleId: 'mod_design_ui',
            title: '$focus 交互状态设计',
            type: 'state',
            priority: 'P1',
            description: '补齐按钮、表单、反馈、空状态等交互细节。',
            event: '页面视觉方案初稿完成',
            action: '沉淀关键交互组件与状态说明',
            response: '研发与业务能准确理解页面行为',
            stateChange: '交互逻辑从隐含设想变为明确规范',
            acceptanceCriteria: [
              '关键组件状态完整',
              '操作反馈有说明',
              '异常场景不留空白',
            ],
            roles: ['design', 'frontend'],
            effortHours: 10,
            dependencies: ['card_design_003'],
            techTags: ['Interaction', 'Prototype'],
          ),
          _buildCard(
            id: 'card_design_005',
            moduleId: 'mod_design_ui',
            title: '$focus 设计交付包',
            type: 'response',
            priority: 'P1',
            description: '整理页面文件、切图说明与评审备注，便于后续落地。',
            event: '设计阶段收尾',
            action: '输出可交接的设计文件和说明',
            response: '研发或合作方可以直接接手制作',
            stateChange: '交付从设计稿变为可执行资产包',
            acceptanceCriteria: [
              '文件命名统一',
              '导出资源齐全',
              '关键说明可追溯',
            ],
            roles: ['design'],
            effortHours: 6,
            dependencies: ['card_design_004'],
            techTags: ['Handoff', 'Asset'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_design_system',
        name: 'Design System',
        cards: [
          _buildCard(
            id: 'card_design_006',
            moduleId: 'mod_design_system',
            title: '$focus 组件规范',
            type: 'response',
            priority: 'P1',
            description: '提炼可复用组件、间距和排版规则。',
            event: '页面稿达到稳定阶段',
            action: '整理按钮、输入框、卡片、列表等组件规范',
            response: '后续页面设计与开发能保持一致',
            stateChange: '组件使用从单页重复绘制变为系统复用',
            acceptanceCriteria: [
              '基础组件至少 8 类',
              '组件含尺寸与状态说明',
              '命名与层级可复用',
            ],
            roles: ['design', 'frontend'],
            effortHours: 12,
            dependencies: ['card_design_003'],
            techTags: ['Design System'],
          ),
          _buildCard(
            id: 'card_design_007',
            moduleId: 'mod_design_system',
            title: '$focus 设计 Token',
            type: 'state',
            priority: 'P2',
            description: '沉淀颜色、字号、圆角、阴影等基础 token。',
            event: '组件规范确认后',
            action: '建立设计 token 表并映射组件用法',
            response: '设计和研发之间的表达更统一',
            stateChange: '视觉规则从经验使用变为系统化参数',
            acceptanceCriteria: [
              '核心 token 分类完整',
              '支持主题扩展',
              '与组件规范保持一致',
            ],
            roles: ['design', 'frontend'],
            effortHours: 8,
            dependencies: ['card_design_006'],
            techTags: ['Token', 'System'],
          ),
        ],
      ),
    ];
  }

  static List<Map<String, dynamic>> _buildSolutionModules(
    String focus,
    String brief,
  ) {
    return [
      _buildModule(
        id: 'mod_solution_research',
        name: 'Research',
        cards: [
          _buildCard(
            id: 'card_solution_001',
            moduleId: 'mod_solution_research',
            title: '$focus 现状调研',
            type: 'event',
            priority: 'P0',
            description: '围绕「$focus」梳理当前业务现状、问题来源与已有材料。当前对话摘要：$brief',
            event: '方案项目立项',
            action: '访谈关键角色并收集已有资料',
            response: '形成现状诊断输入清单',
            stateChange: '问题信息从分散输入变为系统收集',
            acceptanceCriteria: [
              '明确访谈对象名单',
              '已有材料完成归档',
              '问题描述形成初稿',
            ],
            roles: ['consulting', 'pm'],
            effortHours: 12,
            techTags: ['Research'],
          ),
          _buildCard(
            id: 'card_solution_002',
            moduleId: 'mod_solution_research',
            title: '$focus 问题诊断',
            type: 'response',
            priority: 'P0',
            description: '基于调研结果梳理核心问题、成因与优先级。',
            event: '调研资料收集完成',
            action: '进行问题归类、根因分析和优先级判断',
            response: '输出结构化诊断结论',
            stateChange: '问题判断从感性认知变为结构化诊断',
            acceptanceCriteria: [
              '至少识别 3 类核心问题',
              '每类问题有原因说明',
              '优先级排序可解释',
            ],
            roles: ['consulting'],
            effortHours: 10,
            dependencies: ['card_solution_001'],
            techTags: ['Diagnosis'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_solution_strategy',
        name: 'Strategy',
        cards: [
          _buildCard(
            id: 'card_solution_003',
            moduleId: 'mod_solution_strategy',
            title: '$focus 策略路径设计',
            type: 'action',
            priority: 'P0',
            description: '根据诊断结果设计中短期可执行策略。',
            event: '诊断结论确认后',
            action: '拆解目标、路径与关键动作',
            response: '形成阶段性策略方案',
            stateChange: '方向讨论从抽象建议变为具体路径',
            acceptanceCriteria: [
              '策略路径分阶段呈现',
              '每阶段有目标与动作',
              '方案可供管理层评审',
            ],
            roles: ['consulting', 'pm'],
            effortHours: 16,
            dependencies: ['card_solution_002'],
            techTags: ['Strategy'],
          ),
          _buildCard(
            id: 'card_solution_004',
            moduleId: 'mod_solution_strategy',
            title: '$focus 优先级矩阵',
            type: 'state',
            priority: 'P1',
            description: '将策略项按价值、难度和依赖关系排序。',
            event: '策略项初步成型',
            action: '建立优先级矩阵与取舍依据',
            response: '帮助团队确定先做什么、后做什么',
            stateChange: '执行顺序从主观判断变为标准化排序',
            acceptanceCriteria: [
              '优先级标准清晰',
              '关键依赖关系可见',
              '低优先级项有暂缓说明',
            ],
            roles: ['consulting', 'pm'],
            effortHours: 8,
            dependencies: ['card_solution_003'],
            techTags: ['Prioritization'],
          ),
          _buildCard(
            id: 'card_solution_005',
            moduleId: 'mod_solution_strategy',
            title: '$focus 干系人对齐',
            type: 'response',
            priority: 'P1',
            description: '让核心决策人对目标、边界与投入达成一致。',
            event: '策略方案进入评审阶段',
            action: '准备汇报材料并组织对齐会议',
            response: '关键干系人确认方案方向',
            stateChange: '方案从单方输出变为共识性方案',
            acceptanceCriteria: [
              '评审材料结构完整',
              '关键争议点有结论',
              '责任边界得到确认',
            ],
            roles: ['consulting', 'pm'],
            effortHours: 6,
            dependencies: ['card_solution_004'],
            techTags: ['Alignment'],
          ),
        ],
      ),
      _buildModule(
        id: 'mod_solution_plan',
        name: 'Implementation Plan',
        cards: [
          _buildCard(
            id: 'card_solution_006',
            moduleId: 'mod_solution_plan',
            title: '$focus 实施里程碑',
            type: 'event',
            priority: 'P0',
            description: '将策略方案拆成可执行的阶段与里程碑。',
            event: '方案确认后进入落地阶段',
            action: '定义阶段目标、时间节点和验收标准',
            response: '项目进入可跟踪推进状态',
            stateChange: '执行从原则建议变为里程碑管理',
            acceptanceCriteria: [
              '阶段划分清晰',
              '每阶段有验收标准',
              '关键节点具备责任人',
            ],
            roles: ['consulting', 'pm'],
            effortHours: 12,
            dependencies: ['card_solution_003'],
            techTags: ['Plan', 'Milestone'],
          ),
          _buildCard(
            id: 'card_solution_007',
            moduleId: 'mod_solution_plan',
            title: '$focus 风险与资源安排',
            type: 'response',
            priority: 'P1',
            description: '识别实施阶段的关键风险、资源缺口与应对建议。',
            event: '实施计划编制过程中',
            action: '列出风险项、资源需求和缓解动作',
            response: '团队能够提前准备资源与预案',
            stateChange: '风险管理从事后补救变为前置控制',
            acceptanceCriteria: [
              '列出主要风险清单',
              '每项风险有应对策略',
              '资源需求可直接评估',
            ],
            roles: ['consulting'],
            effortHours: 8,
            dependencies: ['card_solution_006'],
            techTags: ['Risk', 'Resource'],
          ),
        ],
      ),
    ];
  }

  static Map<String, dynamic> _buildModule({
    required String id,
    required String name,
    required List<Map<String, dynamic>> cards,
  }) {
    return {
      'id': id,
      'name': name,
      'cards': cards,
    };
  }

  static Map<String, dynamic> _buildCard({
    required String id,
    required String moduleId,
    required String title,
    required String type,
    required String priority,
    required String description,
    required String event,
    required String action,
    required String response,
    required String stateChange,
    required List<String> acceptanceCriteria,
    required List<String> roles,
    required int effortHours,
    List<String> dependencies = const [],
    List<String> techTags = const [],
  }) {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'type': type,
      'priority': priority,
      'description': description,
      'event': event,
      'action': action,
      'response': response,
      'state_change': stateChange,
      'acceptance_criteria': acceptanceCriteria
          .asMap()
          .entries
          .map(
            (entry) => {
              'id': '${id}_ac_${(entry.key + 1).toString().padLeft(2, '0')}',
              'content': entry.value,
              'checked': false,
            },
          )
          .toList(),
      'roles': roles,
      'effort_hours': effortHours,
      'dependencies': dependencies,
      'tech_tags': techTags,
      'status': 'pending',
    };
  }

  static Map<String, dynamic> _saveDraft(RequestOptions options) {
    _draftCount += 1;
    final data = options.data as Map<String, dynamic>? ?? {};
    final now = DateTime.now().toIso8601String();
    final projectId = 'proj_draft_${_draftCount.toString().padLeft(3, '0')}';

    final project = <String, dynamic>{
      'id': projectId,
      'uuid': projectId,
      'owner_id': 'user_001',
      'owner_name': 'KAIZAO 用户',
      'title': '未命名需求草稿',
      'description': '项目方正在完善项目描述，发布后会补充完整的业务背景、目标与交付要求。',
      'category': data['category']?.toString() ?? 'web',
      'budget_min': (data['budget_min'] as num?)?.toDouble() ?? 1000,
      'budget_max': (data['budget_max'] as num?)?.toDouble() ?? 5000,
      'match_mode': data['match_mode'] as int? ?? 1,
      'status': 1,
      'status_text': '草稿',
      'tech_requirements': <String>[],
      'view_count': 0,
      'bid_count': 0,
      'created_at': now,
    };
    _conversationStates.remove(projectId);
    MarketMock.upsertProject(project);

    return {
      'code': 0,
      'message': '草稿已保存',
      'data': {
        ...project,
        'saved_at': now,
      },
    };
  }

  static Map<String, dynamic> _updateDraft(RequestOptions options) {
    final path = options.path;
    final projectId = path.split('/').last;
    final current = MarketMock.findProject(projectId) ??
        <String, dynamic>{
          'id': projectId,
          'uuid': projectId,
          'owner_id': 'user_001',
          'owner_name': 'KAIZAO 用户',
          'status': 1,
          'created_at': DateTime.now().toIso8601String(),
          'tech_requirements': <String>[],
          'view_count': 0,
          'bid_count': 0,
        };
    final data = options.data as Map<String, dynamic>? ?? {};

    final updated = <String, dynamic>{
      ...current,
      ...data,
      'id': current['id'] ?? projectId,
      'uuid': current['uuid'] ?? projectId,
      'status': current['status'] ?? 1,
      'status_text': '草稿',
    };
    MarketMock.upsertProject(updated);

    return {
      'code': 0,
      'message': '草稿更新成功',
      'data': updated,
    };
  }

  static Map<String, dynamic> _publishDraft(RequestOptions options) {
    final pathParts = options.path.split('/');
    final projectId = pathParts[pathParts.length - 2];
    final current = MarketMock.findProject(projectId) ??
        <String, dynamic>{
          'id': projectId,
          'uuid': projectId,
          'owner_id': 'user_001',
          'owner_name': 'KAIZAO 用户',
          'title': '未命名需求',
          'description': '项目方正在完善项目描述，发布后会补充完整的业务背景、目标与交付要求。',
          'category': 'web',
          'budget_min': 1000,
          'budget_max': 5000,
          'match_mode': 1,
          'tech_requirements': <String>[],
          'view_count': 0,
          'bid_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        };
    final published = <String, dynamic>{
      ...current,
      'status': 2,
      'status_text': '已发布',
      'published_at': DateTime.now().toIso8601String(),
    };
    MarketMock.upsertProject(published);

    return {
      'code': 0,
      'message': '项目发布成功',
      'data': published,
    };
  }

  static Map<String, dynamic> _publishProject(RequestOptions options) {
    final data = options.data as Map<String, dynamic>? ?? {};
    _draftCount += 1;
    final now = DateTime.now().toIso8601String();
    final projectId = 'proj_new_${_draftCount.toString().padLeft(3, '0')}';
    final project = <String, dynamic>{
      'id': projectId,
      'uuid': projectId,
      'owner_id': 'user_001',
      'owner_name': 'KAIZAO 用户',
      'title': data['title'] ?? 'AI 生成需求',
      'description': data['description'] ?? '来自发布流的需求描述',
      'category': data['category']?.toString() ?? 'web',
      'budget_min': (data['budget_min'] as num?)?.toDouble() ?? 5000,
      'budget_max': (data['budget_max'] as num?)?.toDouble() ?? 15000,
      'match_mode': data['match_mode'] as int? ?? 1,
      'status': 2,
      'status_text': '已发布',
      'tech_requirements': <String>[],
      'view_count': 0,
      'bid_count': 0,
      'published_at': now,
      'created_at': now,
    };
    MarketMock.upsertProject(project);

    return {
      'code': 0,
      'message': '项目发布成功',
      'data': project,
    };
  }
}

class _MockConversationState {
  final String category;
  final int turnCount;

  const _MockConversationState({
    required this.category,
    required this.turnCount,
  });
}
