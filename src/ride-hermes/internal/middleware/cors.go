package middleware

import (
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORSMiddleware 跨域配置
// 生产环境必须指定具体域名，不能使用 "*" + AllowCredentials: true
// 开发环境允许所有来源
func CORSMiddleware() gin.HandlerFunc {
	allowedOrigins := []string{
		"http://localhost:3001",
		"http://localhost:5173",
		"https://ride.accseal.cn",
	}

	return cors.New(cors.Config{
		AllowOriginFunc: func(origin string) bool {
			// 开发环境允许所有来源
			if gin.Mode() == gin.DebugMode {
				return true
			}
			// 生产环境检查白名单
			for _, allowed := range allowedOrigins {
				if origin == allowed || strings.HasSuffix(origin, ".accseal.cn") {
					return true
				}
			}
			return false
		},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "X-Requested-With"},
		ExposeHeaders:    []string{"Content-Length", "X-Request-Id"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	})
}
