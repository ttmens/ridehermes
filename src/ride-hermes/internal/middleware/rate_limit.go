package middleware

import (
	"context"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/ridehermes/ride-hermes/internal/common"
)

type RateLimitKeyFunc func(c *gin.Context) string

func RateLimitMiddleware(rdb *redis.Client, keyFn RateLimitKeyFunc, maxReq int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := "rate_limit:" + keyFn(c)
		ctx := context.Background()

		pipe := rdb.Pipeline()
		now := time.Now().UnixMilli()
		windowStart := now - window.Milliseconds()

		pipe.ZRemRangeByScore(ctx, key, "0", strconv.FormatInt(windowStart, 10))
		_ = pipe.ZCard(ctx, key)
		pipe.ZAdd(ctx, key, redis.Z{Score: float64(now), Member: strconv.FormatInt(now, 10)})
		pipe.Expire(ctx, key, window)

		cmds, err := pipe.Exec(ctx)
		if err != nil {
			c.Next()
			return
		}

		current := cmds[1].(*redis.IntCmd).Val()
		if current >= int64(maxReq) {
			c.Header("X-RateLimit-Limit", strconv.Itoa(maxReq))
			c.Header("X-RateLimit-Remaining", "0")
			c.Header("X-RateLimit-Reset", strconv.FormatInt((now+window.Milliseconds())/1000, 10))
			common.ErrorWithStatus(c, 429, common.CodeRateLimit, "请求过于频繁，请稍后再试")
			c.Abort()
			return
		}

		c.Header("X-RateLimit-Limit", strconv.Itoa(maxReq))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(maxReq-int(current)-1))
		c.Next()
	}
}
