/// 应用环境配置
/// 通过 --dart-define=APP_ENV=dev|staging|prod 注入
/// Mock 开关通过 --dart-define=USE_MOCK=true 开启（默认关闭，仅 dev 环境生效）
enum AppEnvironment { dev, staging, prod }

class AppEnv {
  static late AppEnvironment current;

  static String get baseUrl => switch (current) {
        AppEnvironment.dev => 'http://47.236.165.75:39527',
        AppEnvironment.staging => 'http://47.236.165.75:39527',
        AppEnvironment.prod => 'https://api.vibebuild.com',
      };

  static String get wsUrl => switch (current) {
        AppEnvironment.dev => 'ws://47.236.165.75:39527',
        AppEnvironment.staging => 'ws://47.236.165.75:39527',
        AppEnvironment.prod => 'wss://ws.vibebuild.com',
      };

  static bool get useMock =>
      current == AppEnvironment.dev &&
      const bool.fromEnvironment('USE_MOCK', defaultValue: false);

  static bool get isProduction => current == AppEnvironment.prod;

  static void init() {
    const envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    current = AppEnvironment.values.firstWhere(
      (e) => e.name == envName,
      orElse: () => AppEnvironment.dev,
    );
  }
}
