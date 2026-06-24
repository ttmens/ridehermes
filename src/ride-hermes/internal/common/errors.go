package common

const (
	CodeSuccess      = 0
	CodeParamError   = 10001
	CodePhoneExists  = 10002
	CodePlateExists  = 10003
	CodeIDCardExists = 10004
	CodeUnauthorized = 20001
	CodeTokenExpired = 20002
	CodeForbidden    = 20003
	CodeUserNotFound = 30001
	CodeOrderNotFound = 30002
	CodeDriverNotFound = 30003
	CodeInvalidStatus = 40001
	CodeDriverOffline = 40002
	CodeDriverBusy   = 40003
	CodeInternalError        = 50001
	CodeAIServiceUnavailable = 50002
	CodeRateLimit            = 40003
	CodeHasActiveOrder       = 40004
	CodeAgentNoPermission    = 20004
)
