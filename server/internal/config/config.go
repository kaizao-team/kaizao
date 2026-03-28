package config

import (
	"os"
	"strconv"
	"strings"

	"github.com/spf13/viper"
)

// Config 全局配置结构
type Config struct {
	Server       ServerConfig       `mapstructure:"server"`
	Database     DatabaseConfig     `mapstructure:"database"`
	Redis        RedisConfig        `mapstructure:"redis"`
	JWT          JWTConfig          `mapstructure:"jwt"`
	Log          LogConfig          `mapstructure:"log"`
	OSS          OSSConfig          `mapstructure:"oss"`
	SMS          SMSConfig          `mapstructure:"sms"`
	Registration RegistrationConfig `mapstructure:"registration"`
}

// RegistrationConfig 注册 / 邀请码 / 入驻审核
type RegistrationConfig struct {
	DisableAutoRegister  bool  `mapstructure:"disable_auto_register"`
	RequireInviteRoles   []int `mapstructure:"require_invite_roles"`
	RequireApprovalRoles []int `mapstructure:"require_approval_roles"`
}

// RoleNeedsInvite 指定角色是否必须提供邀请码
func (r RegistrationConfig) RoleNeedsInvite(role int) bool {
	return intInSlice(r.RequireInviteRoles, role)
}

// RoleNeedsApproval 指定角色注册后是否待审核（不发 Token）
func (r RegistrationConfig) RoleNeedsApproval(role int) bool {
	return intInSlice(r.RequireApprovalRoles, role)
}

func intInSlice(list []int, v int) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

func parseIntCSV(s string) []int {
	var out []int
	for _, p := range strings.Split(s, ",") {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		n, err := strconv.Atoi(p)
		if err == nil {
			out = append(out, n)
		}
	}
	return out
}

// ServerConfig HTTP 服务配置
type ServerConfig struct {
	Port            int    `mapstructure:"port"`
	Mode            string `mapstructure:"mode"`
	ReadTimeoutSec  int    `mapstructure:"read_timeout_sec"`
	WriteTimeoutSec int    `mapstructure:"write_timeout_sec"`
}

// DatabaseConfig MySQL 配置
type DatabaseConfig struct {
	Host               string `mapstructure:"host"`
	Port               int    `mapstructure:"port"`
	User               string `mapstructure:"user"`
	Password           string `mapstructure:"password"`
	DBName             string `mapstructure:"dbname"`
	Charset            string `mapstructure:"charset"`
	ParseTime          bool   `mapstructure:"parse_time"`
	Loc                string `mapstructure:"loc"`
	MaxIdleConns       int    `mapstructure:"max_idle_conns"`
	MaxOpenConns       int    `mapstructure:"max_open_conns"`
	ConnMaxLifetimeMin int    `mapstructure:"conn_max_lifetime_min"`
}

// RedisConfig Redis 配置
type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

// JWTConfig JWT 配置
type JWTConfig struct {
	Secret           string `mapstructure:"secret"`
	AccessExpireHour int    `mapstructure:"access_expire_hour"`
	RefreshExpireDay int    `mapstructure:"refresh_expire_day"`
	Issuer           string `mapstructure:"issuer"`
}

// LogConfig 日志配置
type LogConfig struct {
	Level  string `mapstructure:"level"`
	Format string `mapstructure:"format"`
}

// OSSConfig 对象存储（MinIO / S3 兼容；团队静态文件等）
type OSSConfig struct {
	Enabled         bool   `mapstructure:"enabled"`
	Endpoint        string `mapstructure:"endpoint"` // host:port，不含协议
	UseSSL          bool   `mapstructure:"use_ssl"`
	Region          string `mapstructure:"region"`
	AccessKeyID     string `mapstructure:"access_key_id"`
	AccessKeySecret string `mapstructure:"access_key_secret"`
	BucketName      string `mapstructure:"bucket_name"`
	BaseURL         string `mapstructure:"base_url"` // 对外访问 URL 前缀，如 https://cdn.example.com/bucket
	MaxUploadMB     int    `mapstructure:"max_upload_mb"`
}

// SMSConfig 短信配置
type SMSConfig struct {
	AccessKeyID     string `mapstructure:"access_key_id"`
	AccessKeySecret string `mapstructure:"access_key_secret"`
	SignName        string `mapstructure:"sign_name"`
	TemplateCode    string `mapstructure:"template_code"`
}

// Load 加载配置
func Load() (*Config, error) {
	v := viper.New()

	// 设置默认值
	v.SetDefault("server.port", 8080)
	v.SetDefault("server.mode", "debug")
	v.SetDefault("server.read_timeout_sec", 10)
	v.SetDefault("server.write_timeout_sec", 10)
	v.SetDefault("database.host", "localhost")
	v.SetDefault("database.port", 3306)
	v.SetDefault("database.user", "root")
	v.SetDefault("database.password", "")
	v.SetDefault("database.dbname", "kaizao")
	v.SetDefault("database.charset", "utf8mb4")
	v.SetDefault("database.parse_time", true)
	v.SetDefault("database.loc", "Local")
	v.SetDefault("database.max_idle_conns", 10)
	v.SetDefault("database.max_open_conns", 100)
	v.SetDefault("database.conn_max_lifetime_min", 30)
	v.SetDefault("redis.host", "localhost")
	v.SetDefault("redis.port", 6379)
	v.SetDefault("redis.password", "")
	v.SetDefault("redis.db", 0)
	v.SetDefault("jwt.secret", "vibebuild-jwt-secret-change-me")
	v.SetDefault("jwt.access_expire_hour", 2)
	v.SetDefault("jwt.refresh_expire_day", 30)
	v.SetDefault("jwt.issuer", "vibebuild")
	v.SetDefault("log.level", "info")
	v.SetDefault("log.format", "json")
	v.SetDefault("registration.disable_auto_register", false)
	v.SetDefault("oss.enabled", false)
	v.SetDefault("oss.use_ssl", false)
	v.SetDefault("oss.max_upload_mb", 32)

	// 配置文件
	v.SetConfigName("config")
	v.SetConfigType("yaml")
	v.AddConfigPath(".")
	v.AddConfigPath("./configs")
	v.AddConfigPath("/etc/vibebuild")

	// 环境变量覆盖：VB_SERVER_PORT -> server.port
	v.SetEnvPrefix("VB")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv()

	// 读取配置文件（不存在也不报错，走默认值 + 环境变量）
	_ = v.ReadInConfig()

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return nil, err
	}

	// 逗号分隔环境变量（覆盖 yaml），便于容器内配置
	if s := os.Getenv("VB_REGISTRATION_REQUIRE_INVITE_ROLES"); s != "" {
		cfg.Registration.RequireInviteRoles = parseIntCSV(s)
	}
	if s := os.Getenv("VB_REGISTRATION_REQUIRE_APPROVAL_ROLES"); s != "" {
		cfg.Registration.RequireApprovalRoles = parseIntCSV(s)
	}
	if os.Getenv("VB_REGISTRATION_DISABLE_AUTO_REGISTER") == "true" || os.Getenv("VB_REGISTRATION_DISABLE_AUTO_REGISTER") == "1" {
		cfg.Registration.DisableAutoRegister = true
	}

	return &cfg, nil
}
