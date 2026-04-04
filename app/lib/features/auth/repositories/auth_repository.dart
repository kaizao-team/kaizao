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

/// RSA 公钥信息
class PasswordKeyResult {
  final String keyId;
  final String algorithm;
  final String publicKeyPem;

  const PasswordKeyResult({
    required this.keyId,
    required this.algorithm,
    required this.publicKeyPem,
  });
}

/// 图形验证码
class CaptchaResult {
  final String captchaId;
  final String imageBase64;
  final int expiresIn;

  const CaptchaResult({
    required this.captchaId,
    required this.imageBase64,
    required this.expiresIn,
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
  /// [purpose] 1=注册绑定 2=登录
  Future<void> sendSmsCode(String phone, {int purpose = 2}) async {
    await _client.post(
      ApiEndpoints.sendSmsCode,
      data: {'phone': phone, 'purpose': purpose},
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

  /// 获取 RSA 公钥
  Future<PasswordKeyResult> getPasswordKey() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.passwordKey,
      fromJson: (data) => data as Map<String, dynamic>,
    );
    final data = response.data ?? const {};
    return PasswordKeyResult(
      keyId: data['key_id'] as String? ?? 'v1',
      algorithm: data['algorithm'] as String? ?? 'RSA-OAEP-SHA256',
      publicKeyPem: data['public_key_pem'] as String? ?? '',
    );
  }

  /// 获取图形验证码
  Future<CaptchaResult> getCaptcha() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.captcha,
      fromJson: (data) => data as Map<String, dynamic>,
    );
    final data = response.data ?? const {};
    return CaptchaResult(
      captchaId: data['captcha_id'] as String? ?? '',
      imageBase64: data['image_base64'] as String? ?? '',
      expiresIn: data['expires_in'] as int? ?? 300,
    );
  }

  /// 账号密码登录
  Future<LoginResult> loginWithPassword({
    required String loginType,
    required String identity,
    required String passwordCipher,
    required String captchaId,
    required String captchaCode,
    String? deviceType,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.loginPassword,
      data: {
        'login_type': loginType,
        'identity': identity,
        'password_cipher': passwordCipher,
        'captcha_id': captchaId,
        'captcha_code': captchaCode,
        if (deviceType != null) 'device_type': deviceType,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return _parseLoginResult(response.data ?? const {});
  }

  /// 账号密码注册
  Future<LoginResult> registerWithPassword({
    required String username,
    required String passwordCipher,
    String? nickname,
    int? role,
    String? phone,
    String? smsCode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.registerPassword,
      data: {
        'username': username,
        'password_cipher': passwordCipher,
        if (nickname != null) 'nickname': nickname,
        if (role != null) 'role': role,
        if (phone != null) 'phone': phone,
        if (smsCode != null) 'sms_code': smsCode,
      },
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
