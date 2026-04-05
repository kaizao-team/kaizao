package errcode

// 认证模块 10001-10999
const (
	ErrPhoneFormat         = 10001
	ErrSMSCodeExpired      = 10002
	ErrSMSCodeInvalid      = 10003
	ErrPhoneAlreadyUsed    = 10004
	ErrLoginFailed         = 10005
	ErrWechatAuthFailed    = 10006
	ErrTokenExpired        = 10007
	ErrTokenInvalid        = 10008
	ErrRefreshTokenExpired = 10009
	ErrAccountFrozen       = 10010
	ErrDeviceLimitReached   = 10011
	ErrInviteRequired       = 10012
	ErrInviteInvalid        = 10013
	ErrInviteExhausted      = 10014
	ErrOnboardingPending    = 10015
	ErrOnboardingRejected   = 10016
	ErrRegisterRequired            = 10017
	ErrOnboardingAlreadyApproved = 10018
	ErrOnboardingNeedExpertRole  = 10019
	ErrUsernameInvalid           = 10020
	ErrUsernameTaken             = 10021
	ErrPasswordWeak              = 10022
	ErrPasswordPlaintextForbidden = 10023
	ErrPasswordCipherInvalid     = 10024
	ErrPasswordNotSet            = 10025
	ErrCaptchaInvalid            = 10026
	ErrCaptchaExpired            = 10027
)

// 用户模块 11001-11999
const (
	ErrUserNotFound           = 11001
	ErrNicknameUsed           = 11002
	ErrVerificationIncomplete = 11003
	ErrVerificationPending    = 11004
	ErrSkillsExceedLimit      = 11005
	ErrAvatarFormatInvalid    = 11006
	ErrAvatarSizeExceed       = 11007
	ErrBioTooLong             = 11008
	ErrPortfolioExceedLimit   = 11009
	ErrUserDeactivated              = 11010
	ErrOnboardingApplicationInvalid = 11011
	ErrTeamNotFound                 = 11012
	ErrObjectStorageDisabled        = 11013
	ErrUploadFileTooLarge           = 11014
	ErrTeamFileForbidden            = 11015
	ErrObjectUploadFailed           = 11016
	ErrUploadEmptyFile              = 11017
	ErrUploadInvalidFileType        = 11018
)

// 项目模块（需求） 20001-20999
const (
	ErrProjectNotFound       = 20001
	ErrProjectStatusInvalid  = 20002
	ErrProjectTitleEmpty     = 20003
	ErrProjectDescTooShort   = 20004
	ErrBudgetRangeInvalid    = 20005
	ErrAttachmentExceedLimit = 20006
	ErrAttachmentSizeExceed  = 20007
	ErrCategoryInvalid       = 20008
	ErrProjectOwnerOnly      = 20009
	ErrProjectAlreadyClosed  = 20010
)

// 项目模块（项目管理） 21001-21999
const (
	ErrProjectMgmtNotFound       = 21001
	ErrProjectMgmtStatusInvalid  = 21002
	ErrMilestoneNotFound         = 21003
	ErrTaskNotFound              = 21004
	ErrEarsTypeInvalid           = 21005
	ErrTaskDependencyCycle       = 21006
	ErrMilestonePaymentRatioSum  = 21007
	ErrProjectParticipantOnly    = 21008
	ErrDeliveryAlreadySubmitted       = 21009
	ErrPredecessorTaskIncomplete      = 21010
	ErrTaskAssigneeInvalid            = 21011
	ErrMilestoneStatusInvalid         = 21012
	ErrMilestoneDeliverProviderOnly   = 21013
	ErrMilestoneDeliverNotReady       = 21014
	ErrProjectFileNotFound            = 21015
	ErrProjectFileKindInvalid         = 21016
)

// 匹配模块 30001-30999
const (
	ErrBidNotFound         = 30001
	ErrBidOwnProject       = 30002
	ErrBidClosed           = 30003
	ErrBidDuplicate        = 30004
	ErrBidPriceExceed      = 30005
	ErrProjectAlreadyMatched = 30006
	ErrTeamBidLeaderOnly   = 30007
	ErrFavoriteExceedLimit   = 30008
	ErrQuickMatchNoCandidate = 30009
	ErrFavoriteExpertInvalid = 30010
)

// 交易/支付模块 40001-40999
const (
	ErrOrderNotFound         = 40001
	ErrOrderStatusInvalid    = 40002
	ErrPaymentAmountMismatch = 40003
	ErrPaymentTimeout        = 40004
	ErrRefundExceedPaid      = 40005
	ErrWithdrawExceedBalance = 40006
	ErrWithdrawMinAmount     = 40007
	ErrWithdrawDailyLimit    = 40008
	ErrPaymentChannelError   = 40009
	ErrSplitRatioInvalid     = 40010
	ErrOrderAmountExceed     = 40011
	ErrNewUserOrderLimit     = 40012
	ErrOrderAlreadyExists    = 40013
)

// AI服务模块 50001-50999
const (
	ErrAIServiceUnavailable = 50001
	ErrAITimeout            = 50002
	ErrDescriptionTooShort  = 50003
	ErrAIDailyLimitReached  = 50004
	ErrPRDGenerating        = 50005
	ErrAIDegraded           = 50006
)

// 消息/沟通模块 60001-60999
const (
	ErrConversationNotFound  = 60001
	ErrConversationForbidden = 60002
	ErrMessageContentEmpty   = 60003
	ErrFileSizeExceed        = 60004
	ErrFileTypeUnsupported   = 60005
	ErrMessageRateLimit      = 60006
)

// 评价模块 70001-70999
const (
	ErrReviewDuplicate      = 70001
	ErrRatingOutOfRange     = 70002
	ErrReviewBeforeComplete = 70003
	ErrReviewSensitiveWord  = 70004
	ErrReviewContentTooLong = 70005
)

// 通知模块 80001-80999
const (
	ErrNotificationNotFound    = 80001
	ErrNotificationAlreadyRead = 80002
)

// 管理后台模块 90001-90999
const (
	ErrNoAdminPermission      = 90001
	ErrAdminTargetNotFound    = 90002
	ErrCannotFreezeSuperAdmin = 90003
	ErrAuditActionInvalid     = 90004
)

// 通用模块 99001-99999
const (
	ErrParamInvalid = 99001
)

// ErrorMessages 错误码对应的中文消息
var ErrorMessages = map[int]string{
	ErrPhoneFormat:          "手机号格式不正确",
	ErrSMSCodeExpired:       "验证码已过期",
	ErrSMSCodeInvalid:       "验证码错误",
	ErrPhoneAlreadyUsed:     "该手机号已注册",
	ErrLoginFailed:          "账号或密码错误",
	ErrWechatAuthFailed:     "微信授权失败",
	ErrTokenExpired:         "Token已过期",
	ErrTokenInvalid:         "Token无效",
	ErrRefreshTokenExpired:  "Refresh Token已过期，请重新登录",
	ErrAccountFrozen:        "账号已被冻结",
	ErrDeviceLimitReached:   "登录设备数已达上限",
	ErrInviteRequired:       "该角色注册需要邀请码",
	ErrInviteInvalid:        "邀请码无效或已过期",
	ErrInviteExhausted:      "邀请码使用次数已用尽",
	ErrOnboardingPending:    "账号审核中，请稍后再试",
	ErrOnboardingRejected:   "注册申请未通过审核",
	ErrRegisterRequired:            "请先完成注册后再登录",
	ErrOnboardingAlreadyApproved:   "已完成入驻审核",
	ErrOnboardingNeedExpertRole:    "仅专家角色可提交入驻或兑换团队邀请码",
	ErrUsernameInvalid:             "用户名格式不正确（4-32位字母数字下划线）",
	ErrUsernameTaken:               "用户名已被占用",
	ErrPasswordWeak:                "密码强度不足（8-72位且须含字母与数字）",
	ErrPasswordPlaintextForbidden:  "禁止在请求体中传输明文密码字段",
	ErrPasswordCipherInvalid:       "密码密文无效或无法解密",
	ErrPasswordNotSet:              "该账号未设置密码登录",
	ErrCaptchaInvalid:              "图形验证码错误",
	ErrCaptchaExpired:              "图形验证码已过期",
	ErrOnboardingApplicationInvalid: "请至少提供简历链接或有效作品集",
	ErrTeamNotFound:                "团队不存在",
	ErrObjectStorageDisabled:       "对象存储未启用或配置不完整",
	ErrUploadFileTooLarge:          "上传文件超过大小限制",
	ErrTeamFileForbidden:         "仅团队成员可操作团队文件",
	ErrObjectUploadFailed:        "文件上传失败",
	ErrUploadEmptyFile:           "上传文件不能为空",
	ErrUploadInvalidFileType:     "不支持的文件类型，仅支持常见图片格式",
	ErrUserNotFound:         "用户不存在",
	ErrNicknameUsed:         "昵称已被使用",
	ErrSkillsExceedLimit:    "技能标签数量超过上限",
	ErrPortfolioExceedLimit: "作品集数量超过上限",
	ErrBioTooLong:           "个人简介长度超限",
	ErrUserDeactivated:      "用户已注销",
	ErrProjectNotFound:       "项目不存在",
	ErrProjectStatusInvalid:  "项目状态不允许此操作",
	ErrProjectTitleEmpty:     "需求标题不能为空",
	ErrProjectDescTooShort:  "需求描述长度不足",
	ErrBudgetRangeInvalid:   "预算范围不合法",
	ErrProjectOwnerOnly:     "仅需求发布者可操作",
	ErrProjectAlreadyClosed: "需求已关闭",
	ErrMilestoneNotFound:          "里程碑不存在",
	ErrMilestonePaymentRatioSum:   "里程碑付款比例累计不可超过100%",
	ErrDeliveryAlreadySubmitted:   "该里程碑已提交交付，请等待验收或处理后再试",
	ErrMilestoneStatusInvalid:     "当前里程碑状态不允许此操作",
	ErrMilestoneDeliverProviderOnly: "仅已选服务方可提交里程碑交付",
	ErrMilestoneDeliverNotReady:     "里程碑须为进行中或已打回后方可提交交付",
	ErrProjectParticipantOnly:     "仅项目需求方、已选服务方或项目团队成员可操作",
	ErrProjectFileNotFound:        "项目文件不存在",
	ErrProjectFileKindInvalid:     "file_kind 须为 reference、process 或 deliverable",
	ErrTaskNotFound:         "任务卡片不存在",
	ErrTaskAssigneeInvalid:  "任务指派人须为项目需求方、已选服务方或项目团队成员",
	ErrEarsTypeInvalid:     "EARS 类型不合法",
	ErrBidNotFound:          "投标不存在",
	ErrBidOwnProject:        "不能对自己的需求投标",
	ErrBidDuplicate:         "已对该需求投标，不可重复",
	ErrBidClosed:               "投标已关闭或已处理",
	ErrProjectAlreadyMatched:   "项目已撮合或已选定服务方",
	ErrQuickMatchNoCandidate:   "未找到可撮合的造物者，请稍后再试或手动选标",
	ErrFavoriteExpertInvalid:   "该用户不是可收藏的专家",
	ErrOrderNotFound:        "订单不存在",
	ErrOrderStatusInvalid:   "订单状态不允许当前操作",
	ErrOrderAlreadyExists:   "该项目已有待支付订单",
	ErrConversationNotFound: "会话不存在",
	ErrMessageContentEmpty:  "消息内容不能为空",
	ErrReviewDuplicate:      "重复评价",
	ErrRatingOutOfRange:     "评分范围须为1-5",
	ErrAIServiceUnavailable: "AI服务暂不可用",
	ErrNoAdminPermission:    "无管理员权限",
	ErrParamInvalid:         "参数错误",
	ErrNotificationNotFound: "通知不存在",
	ErrNotificationAlreadyRead: "通知已读",
}

// GetMessage 获取错误码对应的消息
func GetMessage(code int) string {
	if msg, ok := ErrorMessages[code]; ok {
		return msg
	}
	return "未知错误"
}
