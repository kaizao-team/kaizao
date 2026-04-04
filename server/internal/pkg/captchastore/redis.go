// Package captchastore 为 github.com/dchest/captcha 提供 Redis 存储实现。
package captchastore

import (
	"context"
	"time"

	"github.com/redis/go-redis/v9"
)

const keyPrefix = "captcha:dchest:"

// DchestRedisStore 实现 captcha.Store（答案为数字字节切片）。
type DchestRedisStore struct {
	Rdb *redis.Client
	TTL time.Duration
}

// Set implements captcha.Store.
func (s *DchestRedisStore) Set(id string, value []byte) {
	if s.Rdb == nil {
		return
	}
	ttl := s.TTL
	if ttl <= 0 {
		ttl = 3 * time.Minute
	}
	_ = s.Rdb.Set(context.Background(), keyPrefix+id, value, ttl).Err()
}

// Get implements captcha.Store.
func (s *DchestRedisStore) Get(id string, clear bool) []byte {
	if s.Rdb == nil {
		return nil
	}
	ctx := context.Background()
	k := keyPrefix + id
	val, err := s.Rdb.Get(ctx, k).Bytes()
	if err == redis.Nil || err != nil {
		return nil
	}
	if clear {
		_ = s.Rdb.Del(ctx, k).Err()
	}
	return val
}
