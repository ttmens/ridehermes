-- 004_a2a_matching.up.sql
-- A-to-A撮合引擎 + 订阅计费 + 司机Agent画像

-- 撮合需求表
CREATE TABLE IF NOT EXISTS matching_demands (
    id BIGSERIAL PRIMARY KEY,
    demand_no VARCHAR(32) UNIQUE NOT NULL,
    passenger_id BIGINT NOT NULL,
    pickup_addr VARCHAR(255) NOT NULL,
    pickup_lat DECIMAL(10,7) NOT NULL,
    pickup_lng DECIMAL(10,7) NOT NULL,
    dropoff_addr VARCHAR(255) NOT NULL,
    dropoff_lat DECIMAL(10,7) NOT NULL,
    dropoff_lng DECIMAL(10,7) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    car_type SMALLINT NOT NULL DEFAULT 1,
    price_range_min DECIMAL(10,2) NOT NULL DEFAULT 0,
    price_range_max DECIMAL(10,2) NOT NULL DEFAULT 0,
    min_trust_score DECIMAL(3,2) NOT NULL DEFAULT 0,
    status SMALLINT NOT NULL DEFAULT 1,  -- 1=匹配中, 2=已匹配, 3=已取消, 4=已过期
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_matching_demands_status ON matching_demands(status, created_at);
CREATE INDEX IF NOT EXISTS idx_matching_demands_passenger ON matching_demands(passenger_id);

-- 撮合报价表
CREATE TABLE IF NOT EXISTS matching_offers (
    id BIGSERIAL PRIMARY KEY,
    demand_id BIGINT NOT NULL,
    driver_id BIGINT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    message TEXT,
    status SMALLINT NOT NULL DEFAULT 1,  -- 1=待处理, 2=已接受, 3=已拒绝, 4=还价
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (demand_id) REFERENCES matching_demands(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_matching_offers_demand ON matching_offers(demand_id, status);
CREATE INDEX IF NOT EXISTS idx_matching_offers_driver ON matching_offers(driver_id);

-- 订阅表
CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL,
    plan_type SMALLINT NOT NULL,  -- 1=Basic, 2=Pro, 3=Premium
    monthly_fee DECIMAL(10,2) NOT NULL,
    revenue_rate DECIMAL(3,2) NOT NULL,  -- 0.03/0.05/0.06
    start_date TIMESTAMP NOT NULL,
    expire_date TIMESTAMP NOT NULL,
    status SMALLINT NOT NULL DEFAULT 1,  -- 1=Active, 2=Expired, 3=Cancelled
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_driver ON subscriptions(driver_id, status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expire ON subscriptions(expire_date, status);

-- 流水记录表
CREATE TABLE IF NOT EXISTS revenue_records (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(3,2) NOT NULL,
    commission DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_revenue_records_driver ON revenue_records(driver_id, created_at);
CREATE INDEX IF NOT EXISTS idx_revenue_records_order ON revenue_records(order_id);

-- 司机Agent画像表
CREATE TABLE IF NOT EXISTS driver_agent_profiles (
    id BIGSERIAL PRIMARY KEY,
    driver_id BIGINT NOT NULL UNIQUE,
    preferred_areas JSONB,  -- 偏好区域（GeoJSON）
    preferred_time_slots JSONB,  -- 偏好时间段
    preferred_car_types SMALLINT[],  -- 偏好车型
    base_price DECIMAL(5,2) NOT NULL DEFAULT 3.50,  -- 基础报价（元/公里）
    price_range DECIMAL(3,2) NOT NULL DEFAULT 0.20,  -- 浮动范围（±20%）
    min_accept_price DECIMAL(10,2) NOT NULL DEFAULT 25.00,  -- 最低接受价
    available_time_slots JSONB,  -- 在线时间
    is_online BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_driver_agent_profiles_online ON driver_agent_profiles(is_online);

-- orders表扩展（关联撮合需求）
ALTER TABLE orders ADD COLUMN IF NOT EXISTS demand_id BIGINT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS matching_mode SMALLINT DEFAULT 1;  -- 1=Platform, 2=A2A

-- drivers表扩展（关联订阅）
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS subscription_id BIGINT;
