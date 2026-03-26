import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class MarketMock {
  MarketMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/market/projects'] = MockHandler(
      delayMs: 500,
      handler: (options) => _marketProjects(options),
    );

    handlers['GET:/api/v1/projects/:id'] = MockHandler(
      delayMs: 300,
      handler: (options) => _projectDetail(options),
    );

    handlers['GET:/api/v1/market/experts'] = MockHandler(
      delayMs: 400,
      handler: (_) => _expertList(),
    );
  }

  static Map<String, dynamic> _expertList() {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': 'exp_01',
          'nickname': '阿杰',
          'avatar_url': null,
          'rating': 4.9,
          'skills': ['Flutter', 'Dart', 'Firebase'],
          'completed_projects': 23,
          'hourly_rate': 300,
          'tagline': '全栈移动端开发专家'
        },
        {
          'id': 'exp_02',
          'nickname': '小李',
          'avatar_url': null,
          'rating': 4.8,
          'skills': ['React', 'TypeScript', 'Next.js'],
          'completed_projects': 18,
          'hourly_rate': 250,
          'tagline': '前端架构师'
        },
        {
          'id': 'exp_03',
          'nickname': '王五',
          'avatar_url': null,
          'rating': 4.7,
          'skills': ['Go', 'PostgreSQL', 'gRPC'],
          'completed_projects': 31,
          'hourly_rate': 350,
          'tagline': '高性能后端开发'
        },
        {
          'id': 'exp_04',
          'nickname': '赵六',
          'avatar_url': null,
          'rating': 4.6,
          'skills': ['Python', 'AI/ML', 'LangChain'],
          'completed_projects': 15,
          'hourly_rate': 280,
          'tagline': 'AI 应用开发者'
        },
        {
          'id': 'exp_05',
          'nickname': '孙七',
          'avatar_url': null,
          'rating': 4.5,
          'skills': ['UI设计', 'Figma', 'Framer'],
          'completed_projects': 42,
          'hourly_rate': 200,
          'tagline': '高级UI/UX设计师'
        },
        {
          'id': 'exp_06',
          'nickname': '周八',
          'avatar_url': null,
          'rating': 4.8,
          'skills': ['Vue.js', 'Nuxt', 'TailwindCSS'],
          'completed_projects': 26,
          'hourly_rate': 260,
          'tagline': 'Vue 生态专家'
        },
        {
          'id': 'exp_07',
          'nickname': '钱九',
          'avatar_url': null,
          'rating': 4.4,
          'skills': ['微信小程序', 'Taro', 'uni-app'],
          'completed_projects': 35,
          'hourly_rate': 220,
          'tagline': '小程序全栈开发'
        },
        {
          'id': 'exp_08',
          'nickname': '林十',
          'avatar_url': null,
          'rating': 4.9,
          'skills': ['Rust', 'WebAssembly', 'Go'],
          'completed_projects': 12,
          'hourly_rate': 400,
          'tagline': '系统级开发专家'
        },
      ],
      'meta': {'page': 1, 'page_size': 20, 'total': 8, 'total_pages': 1},
    };
  }

  static final List<Map<String, dynamic>> _allProjects = [
    {
      'id': '10',
      'uuid': 'proj_010',
      'owner_id': 'user_010',
      'owner_name': '张明',
      'title': '在线教育平台',
      'description': '开发一款支持直播、录播、互动课堂的教育平台，包含学生端和教师端',
      'category': 'app',
      'budget_min': 8000,
      'budget_max': 15000,
      'match_score': 92,
      'status': 2,
      'tech_requirements': ['Flutter', 'WebRTC', 'Node.js'],
      'view_count': 56,
      'bid_count': 2,
      'created_at': '2026-03-20T09:00:00Z'
    },
    {
      'id': '11',
      'uuid': 'proj_011',
      'owner_id': 'user_011',
      'owner_name': '李华',
      'title': 'SaaS 管理后台',
      'description': '企业级SaaS后台管理系统，包含权限管理、数据看板、工单系统',
      'category': 'web',
      'budget_min': 5000,
      'budget_max': 12000,
      'match_score': 87,
      'status': 2,
      'tech_requirements': ['React', 'TypeScript', 'Go'],
      'view_count': 43,
      'bid_count': 4,
      'created_at': '2026-03-19T15:00:00Z'
    },
    {
      'id': '12',
      'uuid': 'proj_012',
      'owner_id': 'user_012',
      'owner_name': '王芳',
      'title': '智能家居控制App',
      'description': '物联网智能家居手机控制端，支持蓝牙和WiFi连接',
      'category': 'app',
      'budget_min': 6000,
      'budget_max': 10000,
      'match_score': 78,
      'status': 2,
      'tech_requirements': ['Flutter', 'MQTT', 'BLE'],
      'view_count': 28,
      'bid_count': 1,
      'created_at': '2026-03-21T11:00:00Z'
    },
    {
      'id': '13',
      'uuid': 'proj_013',
      'owner_id': 'user_013',
      'owner_name': '陈强',
      'title': '社区团购小程序',
      'description': '社区团购微信小程序，含团长端、用户端和后台管理',
      'category': 'miniprogram',
      'budget_min': 3000,
      'budget_max': 6000,
      'match_score': 71,
      'status': 2,
      'tech_requirements': ['微信小程序', 'Node.js'],
      'view_count': 92,
      'bid_count': 7,
      'created_at': '2026-03-17T08:00:00Z'
    },
    {
      'id': '14',
      'uuid': 'proj_014',
      'owner_id': 'user_014',
      'owner_name': '刘洋',
      'title': '品牌官网视觉升级',
      'description': '科技公司品牌官网全面视觉升级，含动效和3D展示',
      'category': 'design',
      'budget_min': 4000,
      'budget_max': 8000,
      'match_score': 65,
      'status': 2,
      'tech_requirements': ['Figma', 'Three.js', 'Framer Motion'],
      'view_count': 35,
      'bid_count': 3,
      'created_at': '2026-03-18T10:00:00Z'
    },
    {
      'id': '15',
      'uuid': 'proj_015',
      'owner_id': 'user_015',
      'owner_name': '赵静',
      'title': '电商数据大屏',
      'description': '实时数据可视化大屏，展示销售、库存、物流等核心指标',
      'category': 'data',
      'budget_min': 5000,
      'budget_max': 9000,
      'match_score': 83,
      'status': 2,
      'tech_requirements': ['ECharts', 'Vue.js', 'WebSocket'],
      'view_count': 41,
      'bid_count': 2,
      'created_at': '2026-03-16T14:00:00Z'
    },
    {
      'id': '16',
      'uuid': 'proj_016',
      'owner_id': 'user_016',
      'owner_name': '孙伟',
      'title': '健身打卡App',
      'description': '运动健身社交App，含课程跟练、打卡、社区功能',
      'category': 'app',
      'budget_min': 7000,
      'budget_max': 13000,
      'match_score': 89,
      'status': 2,
      'tech_requirements': ['Flutter', 'Firebase', 'HealthKit'],
      'view_count': 67,
      'bid_count': 5,
      'created_at': '2026-03-15T09:00:00Z'
    },
    {
      'id': '17',
      'uuid': 'proj_017',
      'owner_id': 'user_017',
      'owner_name': '周敏',
      'title': 'AI 写作助手',
      'description': '基于大语言模型的AI写作辅助工具，支持多种文体',
      'category': 'app',
      'budget_min': 10000,
      'budget_max': 20000,
      'match_score': 95,
      'status': 2,
      'tech_requirements': ['Flutter', 'GPT-4', 'Python'],
      'view_count': 112,
      'bid_count': 8,
      'created_at': '2026-03-14T16:00:00Z'
    },
    {
      'id': '18',
      'uuid': 'proj_018',
      'owner_id': 'user_018',
      'owner_name': '吴磊',
      'title': '企业内训平台',
      'description': '企业内部培训学习平台，支持视频课程、考试、证书生成',
      'category': 'web',
      'budget_min': 6000,
      'budget_max': 11000,
      'match_score': 74,
      'status': 2,
      'tech_requirements': ['Vue.js', 'Go', 'PostgreSQL'],
      'view_count': 29,
      'bid_count': 1,
      'created_at': '2026-03-13T11:00:00Z'
    },
    {
      'id': '19',
      'uuid': 'proj_019',
      'owner_id': 'user_019',
      'owner_name': '郑琳',
      'title': '宠物社区App',
      'description': '宠物爱好者社区，含宠物档案、医疗记录、社交功能',
      'category': 'app',
      'budget_min': 5000,
      'budget_max': 9000,
      'match_score': 68,
      'status': 2,
      'tech_requirements': ['Flutter', 'Supabase'],
      'view_count': 78,
      'bid_count': 6,
      'created_at': '2026-03-12T14:00:00Z'
    },
    {
      'id': '20',
      'uuid': 'proj_020',
      'owner_id': 'user_020',
      'owner_name': '冯涛',
      'title': '餐饮点单系统',
      'description': '餐厅自助点单系统，含扫码点单、后厨打印、会员管理',
      'category': 'miniprogram',
      'budget_min': 4000,
      'budget_max': 7000,
      'match_score': 72,
      'status': 2,
      'tech_requirements': ['微信小程序', 'Spring Boot'],
      'view_count': 54,
      'bid_count': 3,
      'created_at': '2026-03-11T09:00:00Z'
    },
    {
      'id': '21',
      'uuid': 'proj_021',
      'owner_id': 'user_021',
      'owner_name': '黄雯',
      'title': '知识库问答系统',
      'description': '企业知识库RAG问答系统，支持文档上传和智能检索',
      'category': 'app',
      'budget_min': 12000,
      'budget_max': 25000,
      'match_score': 91,
      'status': 2,
      'tech_requirements': ['Python', 'LangChain', 'Flutter'],
      'view_count': 88,
      'bid_count': 4,
      'created_at': '2026-03-10T10:00:00Z'
    },
    {
      'id': '22',
      'uuid': 'proj_022',
      'owner_id': 'user_022',
      'owner_name': '何超',
      'title': '物流追踪平台',
      'description': '物流配送全链路追踪系统，含司机端、客户端和调度后台',
      'category': 'web',
      'budget_min': 8000,
      'budget_max': 16000,
      'match_score': 76,
      'status': 2,
      'tech_requirements': ['React', 'Go', '高德地图API'],
      'view_count': 33,
      'bid_count': 2,
      'created_at': '2026-03-09T15:00:00Z'
    },
    {
      'id': '23',
      'uuid': 'proj_023',
      'owner_id': 'user_023',
      'owner_name': '谢婷',
      'title': '心理健康App',
      'description': '心理健康自助平台，含情绪记录、冥想引导、在线咨询',
      'category': 'app',
      'budget_min': 6000,
      'budget_max': 11000,
      'match_score': 81,
      'status': 2,
      'tech_requirements': ['Flutter', 'Firebase', 'WebRTC'],
      'view_count': 45,
      'bid_count': 3,
      'created_at': '2026-03-08T13:00:00Z'
    },
    {
      'id': '24',
      'uuid': 'proj_024',
      'owner_id': 'user_024',
      'owner_name': '马飞',
      'title': '汽车维修预约',
      'description': '汽车维修保养预约平台，含门店管理和技师排班',
      'category': 'miniprogram',
      'budget_min': 3500,
      'budget_max': 6500,
      'match_score': 63,
      'status': 2,
      'tech_requirements': ['微信小程序', 'Node.js', 'MongoDB'],
      'view_count': 21,
      'bid_count': 1,
      'created_at': '2026-03-07T08:00:00Z'
    },
  ];

  static Map<String, dynamic>? findProject(String id) {
    for (final project in _allProjects) {
      if (project['id'] == id || project['uuid'] == id) {
        return Map<String, dynamic>.from(project);
      }
    }
    return null;
  }

  static void upsertProject(Map<String, dynamic> project) {
    final projectId = project['id'];
    final projectUuid = project['uuid'];
    final index = _allProjects.indexWhere(
      (item) =>
          (projectId != null && item['id'] == projectId) ||
          (projectUuid != null && item['uuid'] == projectUuid),
    );

    final normalized = Map<String, dynamic>.from(project);
    normalized['id'] = normalized['id'] ?? normalized['uuid'];

    if (index >= 0) {
      _allProjects[index] = {
        ..._allProjects[index],
        ...normalized,
      };
      return;
    }

    _allProjects.insert(0, normalized);
  }

  static Map<String, dynamic> _marketProjects(RequestOptions options) {
    final queryParams = options.queryParameters;
    final page = int.tryParse(queryParams['page']?.toString() ?? '1') ?? 1;
    final pageSize =
        int.tryParse(queryParams['page_size']?.toString() ?? '10') ?? 10;
    final category = queryParams['category']?.toString();
    final sort = queryParams['sort']?.toString() ?? 'latest';
    final budgetMin =
        double.tryParse(queryParams['budget_min']?.toString() ?? '');
    final budgetMax =
        double.tryParse(queryParams['budget_max']?.toString() ?? '');

    var filtered = List<Map<String, dynamic>>.from(_allProjects);

    if (category != null && category.isNotEmpty && category != 'all') {
      filtered = filtered.where((p) => p['category'] == category).toList();
    }

    if (budgetMin != null) {
      filtered =
          filtered.where((p) => (p['budget_max'] as num) >= budgetMin).toList();
    }
    if (budgetMax != null) {
      filtered =
          filtered.where((p) => (p['budget_min'] as num) <= budgetMax).toList();
    }

    switch (sort) {
      case 'budget_desc':
        filtered.sort((a, b) =>
            ((b['budget_max'] as num) - (a['budget_max'] as num)).toInt());
      case 'match':
        filtered.sort((a, b) => ((b['match_score'] as num?) ?? 0)
            .compareTo((a['match_score'] as num?) ?? 0));
      default:
        filtered.sort((a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String));
    }

    final total = filtered.length;
    final totalPages = (total / pageSize).ceil();
    final start = (page - 1) * pageSize;
    final end = start + pageSize > total ? total : start + pageSize;
    final pageData =
        start < total ? filtered.sublist(start, end) : <Map<String, dynamic>>[];

    return {
      'code': 0,
      'message': 'ok',
      'data': pageData,
      'meta': {
        'page': page,
        'page_size': pageSize,
        'total': total,
        'total_pages': totalPages,
      },
    };
  }

  static Map<String, dynamic> _projectDetail(RequestOptions options) {
    final path = options.path;
    final id = path.split('/').last;

    final project =
        findProject(id) ?? Map<String, dynamic>.from(_allProjects.first);

    final detail = Map<String, dynamic>.from(project);
    detail['milestones'] = [
      {'id': 'm1', 'title': '需求确认', 'status': 'completed', 'progress': 100},
      {'id': 'm2', 'title': 'UI设计', 'status': 'in_progress', 'progress': 60},
      {'id': 'm3', 'title': '前端开发', 'status': 'pending', 'progress': 0},
      {'id': 'm4', 'title': '测试上线', 'status': 'pending', 'progress': 0},
    ];
    detail['prd_summary'] =
        '本项目需要实现${project['title']}的核心功能，技术栈包括${(project['tech_requirements'] as List).join("、")}。项目周期预计4-6周。';

    return {
      'code': 0,
      'message': 'ok',
      'data': detail,
    };
  }
}
