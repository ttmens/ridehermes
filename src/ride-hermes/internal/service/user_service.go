package service

import (
	"context"
	"fmt"

	"github.com/ridehermes/ride-hermes/internal/config"
	"github.com/ridehermes/ride-hermes/internal/middleware"
	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type UserService struct {
	userRepo    *repository.UserRepo
	driverRepo  *repository.DriverRepo
	vehicleRepo *repository.VehicleRepo
	cfg         *config.Config
}

func NewUserService(
	userRepo *repository.UserRepo,
	driverRepo *repository.DriverRepo,
	vehicleRepo *repository.VehicleRepo,
	cfg *config.Config,
) *UserService {
	return &UserService{userRepo: userRepo, driverRepo: driverRepo, vehicleRepo: vehicleRepo, cfg: cfg}
}

type CreatePassengerReq struct {
	Phone    string `json:"phone"`
	Password string `json:"password"`
	Nickname string `json:"nickname"`
}

type CreateDriverReq struct {
	Phone     string           `json:"phone"`
	Password  string           `json:"password"`
	Nickname  string           `json:"nickname"`
	RealName  string           `json:"real_name"`
	IDCardNo  string           `json:"id_card_no"`
	LicenseNo string           `json:"license_no"`
	Vehicle   *CreateVehicleReq `json:"vehicle"`
}

type CreateVehicleReq struct {
	PlateNumber string `json:"plate_number"`
	Brand       string `json:"brand"`
	Model       string `json:"model"`
	Color       string `json:"color"`
	CarType     int8   `json:"car_type"`
}

type LoginReq struct {
	Phone    string `json:"phone"`
	Password string `json:"password"`
}

type LoginResp struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresIn    int       `json:"expires_in"`
	User         *UserInfo `json:"user"`
}

type UserInfo struct {
	ID       int64  `json:"id"`
	Phone    string `json:"phone"`
	Nickname string `json:"nickname"`
	Role     int8   `json:"role"`
}

func (s *UserService) CreatePassenger(ctx context.Context, req *CreatePassengerReq) (*UserInfo, error) {
	existing, _ := s.userRepo.FindByPhone(ctx, req.Phone)
	if existing != nil {
		return nil, fmt.Errorf("手机号已存在")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Phone:        req.Phone,
		PasswordHash: string(hash),
		Nickname:     req.Nickname,
		Role:         model.RolePassenger,
		Status:       model.UserStatusNormal,
	}
	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	return toUserInfo(user), nil
}

func (s *UserService) CreateDriver(ctx context.Context, req *CreateDriverReq) (*UserInfo, *model.Driver, *model.Vehicle, error) {
	existing, _ := s.userRepo.FindByPhone(ctx, req.Phone)
	if existing != nil {
		return nil, nil, nil, fmt.Errorf("手机号已存在")
	}

	existingDriver, _ := s.driverRepo.FindByIDCardNo(ctx, req.IDCardNo)
	if existingDriver != nil {
		return nil, nil, nil, fmt.Errorf("身份证号已存在")
	}

	existingDriver, _ = s.driverRepo.FindByLicenseNo(ctx, req.LicenseNo)
	if existingDriver != nil {
		return nil, nil, nil, fmt.Errorf("驾驶证号已存在")
	}

	return nil, nil, nil, fmt.Errorf("CreateDriver requires DB transaction — use CreateDriverWithDB")
}

type CreatePassengerResult struct {
	User *UserInfo `json:"user"`
}

type CreateDriverResult struct {
	User    *UserInfo      `json:"user"`
	Driver  *DriverInfo    `json:"driver"`
	Vehicle *VehicleInfo   `json:"vehicle"`
}

type DriverInfo struct {
	ID       int64  `json:"id"`
	RealName string `json:"real_name"`
	Status   int8   `json:"status"`
}

type VehicleInfo struct {
	ID          int64  `json:"id"`
	PlateNumber string `json:"plate_number"`
	Brand       string `json:"brand"`
	Model       string `json:"model"`
	Color       string `json:"color"`
	CarType     int8   `json:"car_type"`
}

func toUserInfo(u *model.User) *UserInfo {
	phone := u.Phone
	if len(phone) > 7 {
		phone = phone[:3] + "****" + phone[7:]
	}
	return &UserInfo{
		ID:       u.ID,
		Phone:    phone,
		Nickname: u.Nickname,
		Role:     u.Role,
	}
}

type LoginOrRegisterReq struct {
	Phone    string `json:"phone"`
	Password string `json:"password"`
	Role     int8   `json:"role"` // 2=passenger, 3=driver
}

func (s *UserService) LoginOrRegister(ctx context.Context, req *LoginOrRegisterReq) (*LoginResp, error) {
	user, err := s.userRepo.FindByPhone(ctx, req.Phone)
	if err != nil {
		// User not found — register
		role := req.Role
		if role != model.RolePassenger && role != model.RoleDriver {
			role = model.RolePassenger
		}
		hash, hashErr := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if hashErr != nil {
			return nil, hashErr
		}
		user = &model.User{
			Phone:        req.Phone,
			PasswordHash: string(hash),
			Nickname:     req.Phone,
			Role:         role,
			Status:       model.UserStatusNormal,
		}
		if createErr := s.userRepo.Create(ctx, user); createErr != nil {
			return nil, fmt.Errorf("注册失败: %v", createErr)
		}
	} else {
		// User exists — verify password
		if user.Status == model.UserStatusDisabled {
			return nil, fmt.Errorf("账号已被禁用")
		}
		if bcryptErr := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); bcryptErr != nil {
			return nil, fmt.Errorf("手机号或密码错误")
		}
	}

	accessToken, err := middleware.GenerateToken(user.ID, user.Phone, user.Role, s.cfg.JWT.Secret, s.cfg.JWT.AccessExpire)
	if err != nil {
		return nil, err
	}
	refreshToken, err := middleware.GenerateToken(user.ID, user.Phone, user.Role, s.cfg.JWT.Secret, s.cfg.JWT.RefreshExpire)
	if err != nil {
		return nil, err
	}

	return &LoginResp{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    s.cfg.JWT.AccessExpire,
		User:         toUserInfo(user),
	}, nil
}

func (s *UserService) Login(ctx context.Context, req *LoginReq) (*LoginResp, error) {
	user, err := s.userRepo.FindByPhone(ctx, req.Phone)
	if err != nil {
		return nil, fmt.Errorf("手机号或密码错误")
	}
	if user.Status == model.UserStatusDisabled {
		return nil, fmt.Errorf("账号已被禁用")
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, fmt.Errorf("手机号或密码错误")
	}

	accessToken, err := middleware.GenerateToken(user.ID, user.Phone, user.Role, s.cfg.JWT.Secret, s.cfg.JWT.AccessExpire)
	if err != nil {
		return nil, err
	}

	refreshToken, err := middleware.GenerateToken(user.ID, user.Phone, user.Role, s.cfg.JWT.Secret, s.cfg.JWT.RefreshExpire)
	if err != nil {
		return nil, err
	}

	return &LoginResp{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    s.cfg.JWT.AccessExpire,
		User:         toUserInfo(user),
	}, nil
}

func (s *UserService) GetProfile(ctx context.Context, userID int64) (*UserInfo, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("用户不存在")
	}
	return toUserInfo(user), nil
}

func (s *UserService) UpdateProfile(ctx context.Context, userID int64, nickname, avatarURL string) error {
	updates := map[string]interface{}{}
	if nickname != "" {
		updates["nickname"] = nickname
	}
	if avatarURL != "" {
		updates["avatar_url"] = avatarURL
	}
	return s.userRepo.Update(ctx, userID, updates)
}

// CreatePassengerWithDB creates a passenger within a transaction context.
func (s *UserService) CreatePassengerWithDB(ctx context.Context, db *gorm.DB, req *CreatePassengerReq) (*model.User, error) {
	existing, _ := s.userRepo.FindByPhone(ctx, req.Phone)
	if existing != nil {
		return nil, fmt.Errorf("手机号已存在")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Phone:        req.Phone,
		PasswordHash: string(hash),
		Nickname:     req.Nickname,
		Role:         model.RolePassenger,
		Status:       model.UserStatusNormal,
	}
	if err := db.WithContext(ctx).Create(user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

// CreateDriverWithDB creates a driver + vehicle + user within a transaction.
func (s *UserService) CreateDriverWithDB(ctx context.Context, db *gorm.DB, req *CreateDriverReq) (*model.User, *model.Driver, *model.Vehicle, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, nil, nil, err
	}

	user := &model.User{
		Phone:        req.Phone,
		PasswordHash: string(hash),
		Nickname:     req.Nickname,
		Role:         model.RoleDriver,
		Status:       model.UserStatusNormal,
	}
	if err := db.WithContext(ctx).Create(user).Error; err != nil {
		return nil, nil, nil, err
	}

	driver := &model.Driver{
		UserID:    user.ID,
		RealName:  req.RealName,
		IDCardNo:  req.IDCardNo,
		LicenseNo: req.LicenseNo,
		Status:    model.DriverStatusActive,
	}
	if err := db.WithContext(ctx).Create(driver).Error; err != nil {
		return nil, nil, nil, err
	}

	vehicle := &model.Vehicle{
		DriverID:    driver.ID,
		PlateNumber: req.Vehicle.PlateNumber,
		Brand:       req.Vehicle.Brand,
		Model:       req.Vehicle.Model,
		Color:       req.Vehicle.Color,
		CarType:     req.Vehicle.CarType,
		Status:      model.VehicleStatusActive,
	}
	if err := db.WithContext(ctx).Create(vehicle).Error; err != nil {
		return nil, nil, nil, err
	}

	return user, driver, vehicle, nil
}
