package database

import (
	"github.com/redis/go-redis/v9"
)

func NewRedisClient(url string) *redis.Client {
	opt, _ := redis.ParseURL(url)
	return redis.NewClient(opt)
}
