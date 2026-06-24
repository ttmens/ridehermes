package middleware

import (
	"fmt"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/ridehermes/ride-hermes/internal/common"
	"github.com/ridehermes/ride-hermes/internal/config"
)

type Claims struct {
	UserID int64  `json:"user_id"`
	Phone  string `json:"phone"`
	Role   int8   `json:"role"`
	jwt.RegisteredClaims
}

func GenerateToken(userID int64, phone string, role int8, secret string, expireSeconds int) (string, error) {
	claims := Claims{
		UserID: userID,
		Phone:  phone,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expireSeconds) * time.Second)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func ParseToken(tokenString string, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}
	return claims, nil
}

func AuthMiddleware(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			common.ErrorWithStatus(c, 401, common.CodeUnauthorized, "未登录")
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := ParseToken(tokenString, cfg.JWT.Secret)
		if err != nil {
			common.ErrorWithStatus(c, 401, common.CodeTokenExpired, "Token已过期或无效")
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Set("role", claims.Role)
		c.Next()
	}
}
