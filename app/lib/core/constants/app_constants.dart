/// 应用全局常量
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = '开造';
  static const String appNameEn = 'VCC';
  static const String appVersion = '1.0.0';
  static const String slogan = '点亮每一个想法';

  // 分页
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 验证码
  static const int smsCodeLength = 6;
  static const int smsCountdownSeconds = 60;
  static const int smsExpireSeconds = 300;

  // 文件上传限制
  static const int maxImageSizeMB = 5;
  static const int maxFileSizeMB = 20;
  static const int maxChatFileSizeMB = 50;
  static const int maxAttachmentCount = 10;
  static const int maxPortfolioCount = 50;

  // 文本长度限制
  static const int maxBioLength = 500;
  static const int maxReviewLength = 500;
  static const int maxNicknameLength = 50;
  static const int minDemandDescLength = 20;
  static const int maxSkillCount = 20;

  // 支付
  static const double maxSingleTransaction = 50000.00;
  static const double newUserFirstOrderLimit = 5000.00;
  static const double minWithdrawAmount = 1.00;
  static const int maxDailyWithdrawCount = 3;
  static const double platformFeeRate = 0.12;

  // 用户角色
  static const int roleUnselected = 0;
  static const int roleDemander = 1;
  static const int roleProvider = 2;
  static const int roleDual = 3;
  static const int roleAdmin = 9;

  // 项目复杂度
  static const String complexityS = 'S';
  static const String complexityM = 'M';
  static const String complexityL = 'L';
  static const String complexityXL = 'XL';

  // 项目分类
  static const String categoryApp = 'app';
  static const String categoryWeb = 'web';
  static const String categoryMiniprogram = 'miniprogram';
  static const String categoryDesign = 'design';
  static const String categoryData = 'data';
  static const String categoryConsult = 'consult';

  // EARS类型
  static const String earsUbiquitous = 'ubiquitous';
  static const String earsEvent = 'event';
  static const String earsState = 'state';
  static const String earsOptional = 'optional';
  static const String earsUnwanted = 'unwanted';
}
