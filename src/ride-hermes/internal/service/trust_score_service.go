package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/ridehermes/ride-hermes/internal/model"
	"github.com/ridehermes/ride-hermes/internal/repository"
	"go.uber.org/zap"
)

type TrustScoreService struct {
	tsRepo   *repository.TrustScoreRepo
	evalRepo *repository.EvaluationRepo
	logger   *zap.Logger
}

func NewTrustScoreService(tsRepo *repository.TrustScoreRepo, evalRepo *repository.EvaluationRepo, logger *zap.Logger) *TrustScoreService {
	return &TrustScoreService{tsRepo: tsRepo, evalRepo: evalRepo, logger: logger}
}

// SubmitEvaluation 提交评价并更新信誉分
func (s *TrustScoreService) SubmitEvaluation(ctx context.Context, driverID, orderID, passengerID int64, scores *EvaluationScores) (*model.Evaluation, error) {
	eval := &model.Evaluation{
		DriverID:    driverID,
		OrderID:     orderID,
		PassengerID: passengerID,
		Punctuality: scores.Punctuality,
		Service:     scores.Service,
		Driving:     scores.Driving,
		Completion:  scores.Completion,
		Weight:      1.0,
	}

	if err := s.evalRepo.Create(ctx, eval); err != nil {
		return nil, err
	}

	// 重新计算信誉分
	if err := s.recalculateScore(ctx, driverID); err != nil {
		s.logger.Error("failed to recalculate score", zap.Int64("driver_id", driverID), zap.Error(err))
	}

	return eval, nil
}

// GetTrustScore 查询司机信誉分
func (s *TrustScoreService) GetTrustScore(ctx context.Context, driverID int64) (*model.TrustScore, error) {
	ts, err := s.tsRepo.FindByDriverID(ctx, driverID)
	if err != nil {
		// 初始化默认信誉分
		ts = &model.TrustScore{
			DriverID:    driverID,
			TotalScore:  5.0,
			Punctuality: 5.0,
			Service:     5.0,
			Driving:     5.0,
			Completion:  5.0,
		}
		s.tsRepo.Create(ctx, ts)
	}
	return ts, nil
}

// GetEvaluations 查询评价历史
func (s *TrustScoreService) GetEvaluations(ctx context.Context, driverID int64, limit int) ([]model.Evaluation, error) {
	return s.evalRepo.FindByDriverID(ctx, driverID, limit)
}

// ApplyDecay 时间衰减Cron Job
func (s *TrustScoreService) ApplyDecay(ctx context.Context) error {
	scores, err := s.tsRepo.FindAll(ctx)
	if err != nil {
		return err
	}

	for _, ts := range scores {
		if err := s.recalculateScore(ctx, ts.DriverID); err != nil {
			s.logger.Error("failed to apply decay", zap.Int64("driver_id", ts.DriverID), zap.Error(err))
		}
	}
	return nil
}

// DetectAnomalies 异常检测Cron Job
func (s *TrustScoreService) DetectAnomalies(ctx context.Context) ([]AnomalyReport, error) {
	anomalies := []AnomalyReport{}
	scores, err := s.tsRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	for _, ts := range scores {
		// 7天内信誉分骤降 > 0.5
		evals, err := s.evalRepo.FindRecently(ctx, ts.DriverID, 7*24*time.Hour)
		if err != nil {
			continue
		}
		avg := s.calculateAvgScore(evals)
		if math.Abs(avg-ts.TotalScore) > 0.5 {
			anomalies = append(anomalies, AnomalyReport{
				DriverID:    ts.DriverID,
				Type:        "ScoreDrop",
				Description: fmt.Sprintf("信誉分7天内下降%.2f", ts.TotalScore-avg),
			})
		}

		// 14天内连续3次差评
		badEvals, err := s.evalRepo.FindBadEvaluations(ctx, ts.DriverID, 14*24*time.Hour)
		if err == nil && len(badEvals) >= 3 {
			anomalies = append(anomalies, AnomalyReport{
				DriverID:    ts.DriverID,
				Type:        "ConsecutiveBadReviews",
				Description: fmt.Sprintf("14天内%d次差评", len(badEvals)),
			})
		}
	}
	return anomalies, nil
}

func (s *TrustScoreService) recalculateScore(ctx context.Context, driverID int64) error {
	evals, err := s.evalRepo.FindByDriverID(ctx, driverID, 100)
	if err != nil {
		return err
	}

	if len(evals) == 0 {
		return nil
	}

	totalWeight := 0.0
	var weightedPunctuality, weightedService, weightedDriving, weightedCompletion float64

	for _, eval := range evals {
		weight := s.calculateWeight(eval.CreatedAt)
		weightedPunctuality += eval.Punctuality * weight
		weightedService += eval.Service * weight
		weightedDriving += eval.Driving * weight
		weightedCompletion += eval.Completion * weight
		totalWeight += weight
	}

	if totalWeight <= 0 {
		return nil
	}

	avgPunctuality := weightedPunctuality / totalWeight
	avgService := weightedService / totalWeight
	avgDriving := weightedDriving / totalWeight
	avgCompletion := weightedCompletion / totalWeight

	totalScore := avgPunctuality*model.WeightPunctuality +
		avgService*model.WeightService +
		avgDriving*model.WeightDriving +
		avgCompletion*model.WeightCompletion

	ts := &model.TrustScore{
		DriverID:    driverID,
		TotalScore:  math.Round(totalScore*100) / 100,
		Punctuality: math.Round(avgPunctuality*100) / 100,
		Service:     math.Round(avgService*100) / 100,
		Driving:     math.Round(avgDriving*100) / 100,
		Completion:  math.Round(avgCompletion*100) / 100,
		TotalOrders: len(evals),
	}

	return s.tsRepo.Upsert(ctx, ts)
}

func (s *TrustScoreService) calculateWeight(createdAt time.Time) float64 {
	age := time.Since(createdAt).Hours()

	if age < 30*24 { // 30天内
		return 1.0
	} else if age < 90*24 { // 30-90天
		return model.Decay30Days
	} else if age < 180*24 { // 90-180天
		return model.Decay90Days
	} else { // 180天以上
		return model.Decay180Days
	}
}

func (s *TrustScoreService) calculateAvgScore(evals []model.Evaluation) float64 {
	if len(evals) == 0 {
		return 0
	}
	var total float64
	for _, eval := range evals {
		total += eval.Punctuality*model.WeightPunctuality +
			eval.Service*model.WeightService +
			eval.Driving*model.WeightDriving +
			eval.Completion*model.WeightCompletion
	}
	return total / float64(len(evals))
}

// EvaluationScores 评价分数
type EvaluationScores struct {
	Punctuality float64 `json:"punctuality"`
	Service     float64 `json:"service"`
	Driving     float64 `json:"driving"`
	Completion  float64 `json:"completion"`
}

// AnomalyReport 异常报告
type AnomalyReport struct {
	DriverID    int64  `json:"driver_id"`
	Type        string `json:"type"`
	Description string `json:"description"`
}

// GetAllTrustScores 获取所有司机信誉分（管理员）
func (s *TrustScoreService) GetAllTrustScores(ctx context.Context) ([]model.TrustScore, error) {
	return s.tsRepo.FindAll(ctx)
}

// StartTrustScoreCronJobs 启动信誉分定时任务
func (s *TrustScoreService) StartTrustScoreCronJobs(ctx context.Context) {
	go s.runDecayCron(ctx)
	go s.runAnomalyCron(ctx)
}

func (s *TrustScoreService) runDecayCron(ctx context.Context) {
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if err := s.ApplyDecay(ctx); err != nil {
				s.logger.Error("[Cron] ApplyDecay failed", zap.Error(err))
			} else {
				s.logger.Info("[Cron] ApplyDecay completed")
			}
		}
	}
}

func (s *TrustScoreService) runAnomalyCron(ctx context.Context) {
	ticker := time.NewTicker(10 * time.Minute)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			anomalies, err := s.DetectAnomalies(ctx)
			if err != nil {
				s.logger.Error("[Cron] DetectAnomalies failed", zap.Error(err))
			} else {
				s.logger.Info("[Cron] DetectAnomalies completed", zap.Int("count", len(anomalies)))
			}
		}
	}
}

// AdjustTrustScore 管理员调整司机信誉分
func (s *TrustScoreService) AdjustTrustScore(ctx context.Context, driverID int64, newScore int, reason string) error {
	// 获取当前信誉分
	ts, err := s.tsRepo.FindByDriverID(ctx, driverID)
	if err != nil {
		// 如果不存在，创建默认信誉分
		ts = &model.TrustScore{
			DriverID:    driverID,
			TotalScore:  5.0,
			Punctuality: 5.0,
			Service:     5.0,
			Driving:     5.0,
			Completion:  5.0,
		}
		if err := s.tsRepo.Create(ctx, ts); err != nil {
			return fmt.Errorf("创建信誉分记录失败: %w", err)
		}
	}

	// 将新分数（0-100）转换为 5 分制（0-5）
	newScoreFloat := float64(newScore) / 20.0

	// 更新信誉分
	updates := map[string]interface{}{
		"total_score":  newScoreFloat,
		"punctuality":  newScoreFloat,
		"service":      newScoreFloat,
		"driving":      newScoreFloat,
		"completion":   newScoreFloat,
	}

	if err := s.tsRepo.Update(ctx, driverID, updates); err != nil {
		return fmt.Errorf("更新信誉分失败: %w", err)
	}

	// 记录调整日志
	s.logger.Info("管理员调整信誉分",
		zap.Int64("driver_id", driverID),
		zap.Int("new_score", newScore),
		zap.String("reason", reason))

	return nil
}
