ALTER TABLE orders ADD COLUMN departure_time DATETIME NOT NULL COMMENT '预约出发时间' AFTER car_type;
ALTER TABLE orders ADD COLUMN assigned_at DATETIME NULL COMMENT '系统派单时间' AFTER cancelled_at;
