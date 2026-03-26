import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

/// 登录结果数据
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final int userRole;
  final bool isNewUser;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.userRole,
    required this.isNewUser,
  });
}

/// 认证数据仓库
class AuthRepository {
  final ApiClient _client = ApiClient();

  LoginResult _parseLoginResult(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>? ?? const {};
    final userRole = user['role'] as int? ?? data['role'] as int? ?? 0;

    return LoginResult(
      accessToken: data['access_token'] as String? ?? '',
      refreshToken: data['refresh_token'] as String? ?? '',
      userId: user['uuid'] as String? ?? data['user_id'] as String? ?? '',
      userRole: userRole,
      isNewUser: data['is_new_user'] as bool? ?? userRole == 0,
    );
  }

  /// 发送短信验证码
  Future<void> sendSmsCode(String phone) async {
    await _client.post(
      ApiEndpoints.sendSmsCode,
      data: {'phone': phone, 'purpose': 2},
    );
  }

  /// 手机号验证码登录
  Future<LoginResult> loginWithPhone(String phone, String code) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'phone': phone,
        'sms_code': code,
        'code': code,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );

    return _parseLoginResult(response.data ?? const {});
  }

  /// 微信登录
  Future<LoginResult> loginWithWechat(String code) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.wechatLogin,
      data: {'code': code},
      fromJson: (data) => data as Map<String, dynamic>,
    );

    return _parseLoginResult(response.data ?? const {});
  }

  /// 选择角色
  Future<void> selectRole(int role) async {
    await _client.put(
      ApiEndpoints.currentUser,
      data: {'role': role},
    );
  }

  /// 退出登录
  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout);
  }
}
