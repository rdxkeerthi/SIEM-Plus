package config

import (
	"os"
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	Kafka    KafkaConfig
}

type ServerConfig struct {
	Port int
	Mode string
}

type DatabaseConfig struct {
	URL string
}

type RedisConfig struct {
	URL string
}

type JWTConfig struct {
	Secret     string
	Expiration int
}

type KafkaConfig struct {
	Brokers     []string
	Topic       string
	AlertsTopic string
}

func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("/etc/siem-plus/")

	// Set defaults
	viper.SetDefault("server.port", 8080)
	viper.SetDefault("server.mode", "development")
	viper.SetDefault("database.url", "postgres://siem_admin:siem_password_dev@localhost:5432/siem_plus?sslmode=disable")
	viper.SetDefault("redis.url", "redis://localhost:6379")
	viper.SetDefault("jwt.secret", "change-this-secret-in-production")
	viper.SetDefault("jwt.expiration", 3600)
	viper.SetDefault("kafka.brokers", []string{"localhost:9092"})
	viper.SetDefault("kafka.topic", "events")
	viper.SetDefault("kafka.alertsTopic", "alerts")

	// Environment variables
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, err
		}
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, err
	}

	if brokers := os.Getenv("KAFKA_BROKERS"); brokers != "" {
		config.Kafka.Brokers = strings.Split(brokers, ",")
	}

	if alertsTopic := os.Getenv("KAFKA_ALERTSTOPIC"); alertsTopic != "" {
		config.Kafka.AlertsTopic = alertsTopic
	}

	return &config, nil
}
