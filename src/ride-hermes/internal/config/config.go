package config

import (
	"os"
	"strconv"

	"gopkg.in/yaml.v3"
)

type Config struct {
	Server    ServerConfig    `yaml:"server"`
	Database  DatabaseConfig  `yaml:"database"`
	Redis     RedisConfig     `yaml:"redis"`
	JWT       JWTConfig       `yaml:"jwt"`
	AIService AIServiceConfig `yaml:"ai_service"`
	Dispatch  DispatchConfig  `yaml:"dispatch"`
	Amap      AmapConfig      `yaml:"amap"`
	Log       LogConfig       `yaml:"log"`
}

type ServerConfig struct {
	Port int    `yaml:"port"`
	Mode string `yaml:"mode"`
}

type DatabaseConfig struct {
	Type         string `yaml:"type"`
	Host         string `yaml:"host"`
	Port         int    `yaml:"port"`
	User         string `yaml:"user"`
	Password     string `yaml:"password"`
	DBName       string `yaml:"dbname"`
	MaxIdleConns int    `yaml:"max_idle_conns"`
	MaxOpenConns int    `yaml:"max_open_conns"`
}

type RedisConfig struct {
	Addr     string `yaml:"addr"`
	Password string `yaml:"password"`
	DB       int    `yaml:"db"`
}

type JWTConfig struct {
	Secret        string `yaml:"secret"`
	AccessExpire  int    `yaml:"access_expire"`
	RefreshExpire int    `yaml:"refresh_expire"`
}

type AIServiceConfig struct {
	Addr    string `yaml:"addr"`
	Timeout int    `yaml:"timeout"`
}

type DispatchConfig struct {
	ResponseTimeout      int `yaml:"response_timeout"`
	HeartbeatInterval    int `yaml:"heartbeat_interval"`
	LocationSaveInterval int `yaml:"location_save_interval"`
}

type AmapConfig struct {
	APIKey string `yaml:"api_key"`
}

type LogConfig struct {
	Level  string `yaml:"level"`
	Format string `yaml:"format"`
}

// getEnv 获取环境变量，支持默认值
func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

// getEnvInt 获取整数环境变量
func getEnvInt(key string, defaultVal int) int {
	if val := os.Getenv(key); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return defaultVal
}

func Load(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	cfg := &Config{}
	if err := yaml.Unmarshal(data, cfg); err != nil {
		return nil, err
	}

	// 环境变量覆盖（优先级高于配置文件）
	// 服务器配置
	cfg.Server.Port = getEnvInt("SERVER_PORT", cfg.Server.Port)
	cfg.Server.Mode = getEnv("GIN_MODE", cfg.Server.Mode)

	// 数据库配置
	cfg.Database.Type = getEnv("DB_TYPE", cfg.Database.Type)
	cfg.Database.Host = getEnv("DB_HOST", cfg.Database.Host)
	cfg.Database.Port = getEnvInt("DB_PORT", cfg.Database.Port)
	cfg.Database.User = getEnv("DB_USER", cfg.Database.User)
	cfg.Database.Password = getEnv("DB_PASSWORD", cfg.Database.Password)
	cfg.Database.DBName = getEnv("DB_NAME", cfg.Database.DBName)

	// Redis 配置
	cfg.Redis.Addr = getEnv("REDIS_ADDR", cfg.Redis.Addr)
	cfg.Redis.Password = getEnv("REDIS_PASSWORD", cfg.Redis.Password)

	// JWT 配置（生产环境必须通过环境变量设置）
	cfg.JWT.Secret = getEnv("JWT_SECRET", cfg.JWT.Secret)

	// AI 服务配置
	cfg.AIService.Addr = getEnv("AI_SERVICE_ADDR", cfg.AIService.Addr)

	// 高德地图 API Key
	cfg.Amap.APIKey = getEnv("AMAP_API_KEY", cfg.Amap.APIKey)

	// 默认值
	if cfg.Server.Port == 0 {
		cfg.Server.Port = 8080
	}
	if cfg.Server.Mode == "" {
		cfg.Server.Mode = "debug"
	}
	if cfg.Database.Type == "" {
		cfg.Database.Type = "mysql"
	}
	if cfg.JWT.AccessExpire == 0 {
		cfg.JWT.AccessExpire = 7200
	}
	if cfg.JWT.RefreshExpire == 0 {
		cfg.JWT.RefreshExpire = 604800
	}
	if cfg.Dispatch.ResponseTimeout == 0 {
		cfg.Dispatch.ResponseTimeout = 15
	}
	if cfg.Dispatch.HeartbeatInterval == 0 {
		cfg.Dispatch.HeartbeatInterval = 30
	}
	if cfg.Dispatch.LocationSaveInterval == 0 {
		cfg.Dispatch.LocationSaveInterval = 10
	}

	return cfg, nil
}
