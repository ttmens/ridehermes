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
	Secret         string `yaml:"secret"`
	AccessExpire   int    `yaml:"access_expire"`
	RefreshExpire  int    `yaml:"refresh_expire"`
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

func LoadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	// 环境变量覆盖：JWT密钥（生产环境必须设置）
	if envSecret := os.Getenv("RIDEHERMES_JWT_SECRET"); envSecret != "" {
		cfg.JWT.Secret = envSecret
	}
	// 环境变量覆盖：数据库密码
	if envDBPass := os.Getenv("RIDEHERMES_DB_PASSWORD"); envDBPass != "" {
		cfg.Database.Password = envDBPass
	}
	// 环境变量覆盖：Redis密码
	if envRedisPass := os.Getenv("RIDEHERMES_REDIS_PASSWORD"); envRedisPass != "" {
		cfg.Redis.Password = envRedisPass
	}
	// 环境变量覆盖：高德API Key
	if envAmapKey := os.Getenv("RIDEHERMES_AMAP_KEY"); envAmapKey != "" {
		cfg.Amap.APIKey = envAmapKey
	}
	// 环境变量覆盖：服务器端口
	if envPort := os.Getenv("RIDEHERMES_PORT"); envPort != "" {
		if port, err := strconv.Atoi(envPort); err == nil {
			cfg.Server.Port = port
		}
	}

	return &cfg, nil
}

// Load 加载配置（兼容旧版本调用）
func Load(path string) (*Config, error) {
	return LoadConfig(path)
}
