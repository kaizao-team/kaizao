import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vibebuild_app/core/utils/rsa_cipher.dart';

class TeamSeed {
  final String nickname;
  final String bio;
  final List<String> skills;
  final List<String> tools;
  final String availability;
  final double hourlyRate;

  const TeamSeed({
    required this.nickname,
    required this.bio,
    required this.skills,
    required this.tools,
    required this.availability,
    required this.hourlyRate,
  });
}

class CreatedAccount {
  final String username;
  final String password;
  final String userId;
  final String nickname;

  const CreatedAccount({
    required this.username,
    required this.password,
    required this.userId,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'user_id': userId,
        'nickname': nickname,
      };
}

const _defaultBaseUrl = 'http://47.236.165.75:39527';
const _defaultPassword = 'SeedTeam!2026';

final _seedPool = <TeamSeed>[
  const TeamSeed(
    nickname: '星桥协作',
    bio: '我们做 AI 产品与移动端交付，擅长把模糊想法快速推成可上线版本。',
    skills: ['Flutter', 'AI/ML', '全栈'],
    tools: ['Figma', 'Python'],
    availability: '随时',
    hourlyRate: 180,
  ),
  const TeamSeed(
    nickname: '雾岚体验',
    bio: '我们偏前端体验与设计协作，适合做品牌官网、活动页和产品改版。',
    skills: ['React', 'UI设计'],
    tools: ['Figma', 'Vue.js'],
    availability: '1周内',
    hourlyRate: 220,
  ),
  const TeamSeed(
    nickname: '北屿后端',
    bio: '我们做后端架构、数据服务和 AI 工作流集成，擅长复杂系统落地。',
    skills: ['后端', 'Python', 'Go'],
    tools: ['AI/ML', 'Rust'],
    availability: '1-2周',
    hourlyRate: 260,
  ),
  const TeamSeed(
    nickname: '潮汐产品',
    bio: '我们是全栈偏产品型团队，适合从 0 到 1 做 MVP、后台和增长工具。',
    skills: ['全栈', 'Vue.js', 'Flutter'],
    tools: ['Python', 'Figma'],
    availability: '1个月内',
    hourlyRate: 200,
  ),
  const TeamSeed(
    nickname: '白石视觉',
    bio: '我们专注数据可视化和运营系统，也能配合项目完成品牌与交互升级。',
    skills: ['React', 'UI设计', 'Python'],
    tools: ['Figma', 'AI/ML'],
    availability: '随时',
    hourlyRate: 240,
  ),
  const TeamSeed(
    nickname: '云栈工程',
    bio: '我们偏工程效率和基础设施，适合做中后台、接口治理和交付流程自动化。',
    skills: ['Go', 'Rust', '后端'],
    tools: ['Python', 'AI/ML'],
    availability: '1周内',
    hourlyRate: 280,
  ),
];

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final dio = Dio(
    BaseOptions(
      baseUrl: options.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Device-Type': 'ios',
        'X-App-Version': '1.0.0',
      },
    ),
  );

  final registered = <CreatedAccount>[];
  final seeded = <CreatedAccount>[];
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final count = options.count < 1 ? 1 : options.count;

  stdout.writeln(
    'Seeding $count team accounts to ${options.baseUrl} '
    '(register_role=${options.registerRole}${options.registerOnly ? ', register_only=true' : ''}${options.roleOnlyUpdate ? ', role_only_update=true' : ''})',
  );

  for (var i = 0; i < count; i++) {
    final seed = _seedPool[i % _seedPool.length];
    final nickname = _buildNickname(seed.nickname, i + 1);
    final username = _buildUsername(
      prefix: options.prefix,
      timestamp: timestamp,
      index: i + 1,
    );
    stdout.writeln('[$username] registering...');

    try {
      stdout.writeln('[$username] fetching password key...');
      final publicKeyPem = await _fetchPasswordKey(dio);
      final passwordCipher = RsaCipher.encrypt(options.password, publicKeyPem);
      stdout.writeln('[$username] register-password...');
      final registerData = await _registerAccount(
        dio: dio,
        username: username,
        nickname: nickname,
        passwordCipher: passwordCipher,
        role: options.registerRole,
      );
      final token = _readAccessToken(registerData);
      final userId = _readUserId(registerData);

      if (token.isEmpty || userId.isEmpty) {
        throw Exception(
          'register-password 响应缺少 token 或 user id: $registerData',
        );
      }

      final account = CreatedAccount(
        username: username,
        password: options.password,
        userId: userId,
        nickname: nickname,
      );
      registered.add(account);

      final authed = Dio(
        BaseOptions(
          baseUrl: options.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'X-Device-Type': 'ios',
            'X-App-Version': '1.0.0',
          },
        ),
      );

      if (options.registerOnly) {
        stdout.writeln('[$username] register-only, skipping team bootstrap');
        continue;
      }

      stdout.writeln('[$username] users/me role+pricing update...');
      final roleUpdatePayload = <String, dynamic>{
        'role': options.targetRole,
        'nickname': nickname,
      };
      if (!options.roleOnlyUpdate) {
        roleUpdatePayload['hourly_rate'] = seed.hourlyRate;
        roleUpdatePayload['available_status'] =
            _mapAvailabilityStatus(seed.availability);
      }
      await authed.put(
        '/api/v1/users/me',
        data: roleUpdatePayload,
      );

      stdout.writeln('[$username] users/me/skills update...');
      await authed.put(
        '/api/v1/users/me/skills',
        data: {
          'skills': _buildExpertSkills(
            skills: seed.skills,
            tools: seed.tools,
          ),
        },
      );

      stdout.writeln('[$username] users/me bio update...');
      await authed.put(
        '/api/v1/users/me',
        data: {'bio': seed.bio},
      );

      seeded.add(account);

      stdout.writeln('[$username] done');
    } on DioException catch (error) {
      final responseBody = error.response?.data;
      stderr.writeln('[$username] request failed: ${error.message}');
      stderr.writeln(
        '[$username] ${error.requestOptions.method} '
        '${error.requestOptions.path}',
      );
      final requestData = error.requestOptions.data;
      if (requestData != null) {
        stderr.writeln(
          const JsonEncoder.withIndent('  ').convert(requestData),
        );
      }
      if (responseBody != null) {
        stderr
            .writeln(const JsonEncoder.withIndent('  ').convert(responseBody));
      }
      exitCode = 1;
    } catch (error) {
      stderr.writeln('[$username] failed: $error');
      exitCode = 1;
    }
  }

  stdout.writeln('');
  stdout.writeln('Registered accounts:');
  stdout.writeln(
    const JsonEncoder.withIndent('  ')
        .convert(registered.map((item) => item.toJson()).toList()),
  );
  stdout.writeln('');
  stdout.writeln('Fully seeded accounts:');
  stdout.writeln(
    const JsonEncoder.withIndent('  ')
        .convert(seeded.map((item) => item.toJson()).toList()),
  );
}

Future<String> _fetchPasswordKey(Dio dio) async {
  final response = await dio.get('/api/v1/auth/password-key');
  final data = _unwrapData(response.data);
  final publicKeyPem = data['public_key_pem'] as String? ?? '';
  if (publicKeyPem.isEmpty) {
    throw Exception('password-key 响应缺少 public_key_pem: ${response.data}');
  }
  return publicKeyPem;
}

Future<Map<String, dynamic>> _registerAccount({
  required Dio dio,
  required String username,
  required String nickname,
  required String passwordCipher,
  required int role,
}) async {
  final response = await dio.post(
    '/api/v1/auth/register-password',
    data: {
      'username': username,
      'password_cipher': passwordCipher,
      'nickname': nickname,
      'role': role,
    },
  );
  return _unwrapData(response.data);
}

Map<String, dynamic> _unwrapData(dynamic payload) {
  if (payload is! Map<String, dynamic>) {
    throw Exception('unexpected payload: $payload');
  }
  final data = payload['data'];
  if (data is! Map<String, dynamic>) {
    throw Exception('response.data is not a map: $payload');
  }
  return data;
}

String _readAccessToken(Map<String, dynamic> data) {
  return data['access_token'] as String? ?? '';
}

String _readUserId(Map<String, dynamic> data) {
  final user = data['user'];
  if (user is Map<String, dynamic>) {
    final fromUser = user['uuid'] as String?;
    if (fromUser != null && fromUser.isNotEmpty) {
      return fromUser;
    }
  }
  return data['user_id'] as String? ?? '';
}

int? _mapAvailabilityStatus(String availability) {
  switch (availability) {
    case '随时':
    case '1周内':
      return 1;
    case '1-2周':
      return 2;
    case '1个月内':
      return 3;
    default:
      return null;
  }
}

String _categoryForSkill(String value) {
  switch (value) {
    case 'Flutter':
    case 'React':
    case 'Vue.js':
      return 'framework';
    case 'Python':
    case 'Go':
    case 'Rust':
      return 'language';
    case 'UI设计':
    case 'Figma':
      return 'design';
    case 'AI/ML':
      return 'tool';
    case '后端':
    case '全栈':
      return 'other';
    default:
      return 'tool';
  }
}

List<Map<String, dynamic>> _buildExpertSkills({
  required List<String> skills,
  required List<String> tools,
}) {
  final items = <Map<String, dynamic>>[];
  final seen = <String>{};

  void add(String raw) {
    final name = raw.trim();
    if (name.isEmpty || seen.contains(name)) return;
    seen.add(name);
    items.add({
      'name': name,
      'category': _categoryForSkill(name),
      'is_primary': items.isEmpty,
    });
  }

  for (final skill in skills) {
    add(skill);
  }
  for (final tool in tools) {
    add(tool);
  }

  return items;
}

String _buildUsername({
  required String prefix,
  required int timestamp,
  required int index,
}) {
  const minLength = 4;
  const maxLength = 32;
  final cleaned = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  final suffix = '_${timestamp}_$index';
  final maxPrefixLength = maxLength - suffix.length;

  if (maxPrefixLength <= 0) {
    throw ArgumentError('prefix is too long for generated username suffix');
  }

  var safePrefix = cleaned;
  if (safePrefix.length > maxPrefixLength) {
    safePrefix = safePrefix.substring(0, maxPrefixLength);
  }
  if (safePrefix.length < minLength) {
    safePrefix = safePrefix.padRight(minLength, 'x');
  }

  return '$safePrefix$suffix';
}

String _buildNickname(String base, int index) {
  final suffix = index.toString().padLeft(2, '0');
  final candidate = '$base$suffix';
  if (candidate.runes.length <= 20) {
    return candidate;
  }

  final keep = 20 - suffix.runes.length;
  final truncated = String.fromCharCodes(base.runes.take(keep));
  return '$truncated$suffix';
}

_SeedOptions _parseArgs(List<String> args) {
  var count = 4;
  var baseUrl = _defaultBaseUrl;
  var prefix = 'seed_team';
  var password = _defaultPassword;
  var registerRole = 2;
  var targetRole = 2;
  var registerOnly = true;
  var roleOnlyUpdate = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--count':
        count = int.parse(args[++i]);
      case '--register-role':
        registerRole = int.parse(args[++i]);
      case '--target-role':
        targetRole = int.parse(args[++i]);
      case '--base-url':
        baseUrl = args[++i];
      case '--prefix':
        prefix = args[++i];
      case '--password':
        password = args[++i];
      case '--register-only':
        registerOnly = true;
      case '--bootstrap':
        registerOnly = false;
      case '--role-only-update':
        roleOnlyUpdate = true;
      case '--help':
      case '-h':
        stdout.writeln(
          'Usage: dart run tool/seed_team_accounts.dart '
          '[--count N] [--register-role ROLE] [--target-role ROLE] '
          '[--register-only] [--bootstrap] [--role-only-update] '
          '[--base-url URL] [--prefix PREFIX] [--password PASSWORD]',
        );
        exit(0);
    }
  }

  return _SeedOptions(
    count: count,
    baseUrl: baseUrl,
    prefix: prefix,
    password: password,
    registerRole: registerRole,
    targetRole: targetRole,
    registerOnly: registerOnly,
    roleOnlyUpdate: roleOnlyUpdate,
  );
}

class _SeedOptions {
  final int count;
  final String baseUrl;
  final String prefix;
  final String password;
  final int registerRole;
  final int targetRole;
  final bool registerOnly;
  final bool roleOnlyUpdate;

  const _SeedOptions({
    required this.count,
    required this.baseUrl,
    required this.prefix,
    required this.password,
    required this.registerRole,
    required this.targetRole,
    required this.registerOnly,
    required this.roleOnlyUpdate,
  });
}
