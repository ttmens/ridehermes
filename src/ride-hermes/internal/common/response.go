package common

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    CodeSuccess,
		Message: "success",
		Data:    data,
	})
}

func Error(c *gin.Context, code int, message string) {
	c.JSON(httpStatus(code), Response{
		Code:    code,
		Message: message,
		Data:    nil,
	})
}

func ErrorWithStatus(c *gin.Context, httpStatus int, code int, message string) {
	c.JSON(httpStatus, Response{
		Code:    code,
		Message: message,
		Data:    nil,
	})
}

func httpStatus(code int) int {
	switch {
	case code == CodeUnauthorized || code == CodeTokenExpired:
		return http.StatusUnauthorized
	case code == CodeForbidden || code == CodeAgentNoPermission:
		return http.StatusForbidden
	case code == CodeRateLimit:
		return http.StatusTooManyRequests
	case code == CodeHasActiveOrder:
		return http.StatusConflict
	case code >= 30001 && code <= 30003:
		return http.StatusNotFound
	case code >= 40001 && code <= 40003:
		return http.StatusConflict
	case code >= 50001:
		return http.StatusInternalServerError
	default:
		return http.StatusBadRequest
	}
}
