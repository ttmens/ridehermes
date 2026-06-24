CREATE TABLE users (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    phone       VARCHAR(20)  NOT NULL UNIQUE COMMENT '手机号',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希(bcrypt)',
    nickname    VARCHAR(50)  NOT NULL DEFAULT '' COMMENT '昵称',
    role        TINYINT      NOT NULL COMMENT '角色: 1=管理员 2=乘客 3=司机',
    avatar_url  VARCHAR(500) NOT NULL DEFAULT '' COMMENT '头像URL',
    status      TINYINT      NOT NULL DEFAULT 1 COMMENT '状态: 1=正常 2=禁用',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at  DATETIME     NULL COMMENT '软删除',
    INDEX idx_phone (phone),
    INDEX idx_role (role),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE drivers (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT UNSIGNED NOT NULL UNIQUE COMMENT '关联用户ID',
    real_name   VARCHAR(50)    NOT NULL COMMENT '真实姓名',
    id_card_no  VARCHAR(18)    NOT NULL UNIQUE COMMENT '身份证号',
    license_no  VARCHAR(30)    NOT NULL UNIQUE COMMENT '驾驶证号',
    status      TINYINT        NOT NULL DEFAULT 1 COMMENT '状态: 1=待审核 2=正常 3=禁用',
    rating      DECIMAL(3,2)   NOT NULL DEFAULT 5.00 COMMENT '评分',
    balance     DECIMAL(12,2)  NOT NULL DEFAULT 0.00 COMMENT '余额(预留)',
    created_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at  DATETIME       NULL COMMENT '软删除',
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_deleted_at (deleted_at),
    CONSTRAINT fk_driver_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='司机表';

CREATE TABLE vehicles (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    driver_id   BIGINT UNSIGNED NOT NULL COMMENT '归属司机ID',
    plate_number VARCHAR(20)    NOT NULL UNIQUE COMMENT '车牌号',
    brand       VARCHAR(50)     NOT NULL COMMENT '品牌',
    model       VARCHAR(50)     NOT NULL COMMENT '车型',
    color       VARCHAR(20)     NOT NULL COMMENT '颜色',
    car_type    TINYINT         NOT NULL DEFAULT 1 COMMENT '车型类别: 1=快车 2=专车 3=豪华车',
    status      TINYINT         NOT NULL DEFAULT 1 COMMENT '状态: 1=正常 2=停用',
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_driver_id (driver_id),
    INDEX idx_plate_number (plate_number),
    CONSTRAINT fk_vehicle_driver FOREIGN KEY (driver_id) REFERENCES drivers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='车辆表';

CREATE TABLE orders (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_no        VARCHAR(32)     NOT NULL UNIQUE COMMENT '订单号',
    passenger_id    BIGINT UNSIGNED NOT NULL COMMENT '乘客用户ID',
    driver_id       BIGINT UNSIGNED NULL COMMENT '司机ID(派单后填充)',
    status          TINYINT        NOT NULL DEFAULT 1 COMMENT '状态: 1=待派单 2=派单中 3=已接单 4=前往接驾 5=等待上车 6=行程中 7=已完成 8=已取消',
    pickup_addr     VARCHAR(255)   NOT NULL COMMENT '上车点地址',
    pickup_lat      DECIMAL(10,7)  NOT NULL COMMENT '上车点纬度',
    pickup_lng      DECIMAL(10,7)  NOT NULL COMMENT '上车点经度',
    dropoff_addr    VARCHAR(255)   NOT NULL COMMENT '下车点地址',
    dropoff_lat     DECIMAL(10,7)  NOT NULL COMMENT '下车点纬度',
    dropoff_lng     DECIMAL(10,7)  NOT NULL COMMENT '下车点经度',
    est_price       DECIMAL(10,2)  NOT NULL DEFAULT 0.00 COMMENT '预估费用',
    actual_price    DECIMAL(10,2)  NOT NULL DEFAULT 0.00 COMMENT '实际费用(预留)',
    est_distance    INT            NOT NULL DEFAULT 0 COMMENT '预估距离(米)',
    est_duration    INT            NOT NULL DEFAULT 0 COMMENT '预估时长(秒)',
    car_type        TINYINT        NOT NULL DEFAULT 1 COMMENT '车型: 1=快车 2=专车 3=豪华车',
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at     DATETIME       NULL COMMENT '司机接单时间',
    arrived_at      DATETIME       NULL COMMENT '司机到达时间',
    started_at      DATETIME       NULL COMMENT '行程开始时间',
    ended_at        DATETIME       NULL COMMENT '行程结束时间',
    cancelled_at    DATETIME       NULL COMMENT '取消时间',
    cancel_reason   VARCHAR(255)   NOT NULL DEFAULT '' COMMENT '取消原因',
    updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_no (order_no),
    INDEX idx_passenger_id (passenger_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    CONSTRAINT fk_order_passenger FOREIGN KEY (passenger_id) REFERENCES users(id),
    CONSTRAINT fk_order_driver FOREIGN KEY (driver_id) REFERENCES drivers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

CREATE TABLE locations (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    user_type   TINYINT        NOT NULL COMMENT '用户类型: 2=乘客 3=司机',
    latitude    DECIMAL(10,7)  NOT NULL COMMENT '纬度',
    longitude   DECIMAL(10,7)  NOT NULL COMMENT '经度',
    accuracy    DECIMAL(6,2)   NOT NULL DEFAULT 0 COMMENT 'GPS精度(米)',
    speed       DECIMAL(6,2)   NOT NULL DEFAULT 0 COMMENT '速度(km/h)',
    bearing     DECIMAL(6,2)   NOT NULL DEFAULT 0 COMMENT '方向角(0-360)',
    created_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_type (user_id, user_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='位置记录表';

CREATE TABLE dispatch_logs (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id    BIGINT UNSIGNED NOT NULL COMMENT '订单ID',
    driver_id   BIGINT UNSIGNED NOT NULL COMMENT '被派单司机ID',
    status      TINYINT        NOT NULL COMMENT '结果: 1=待响应 2=已接受 3=已拒绝 4=超时',
    round       INT            NOT NULL DEFAULT 1 COMMENT '轮询轮次',
    created_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id),
    INDEX idx_driver_id (driver_id),
    CONSTRAINT fk_dispatch_order FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_dispatch_driver FOREIGN KEY (driver_id) REFERENCES drivers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='派单记录表';

CREATE TABLE ai_conversations (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    session_id      VARCHAR(36)     NOT NULL COMMENT '会话ID(UUID)',
    role            TINYINT         NOT NULL COMMENT '角色: 1=用户 2=AI',
    input_text      TEXT            NOT NULL COMMENT '输入文本',
    input_audio_url VARCHAR(500)    NOT NULL DEFAULT '' COMMENT '语音文件URL(预留)',
    intent_result   JSON           NULL COMMENT '意图识别结果JSON',
    response_text   TEXT            NOT NULL COMMENT 'AI回复文本',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_session (user_id, session_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI对话记录表';

-- 管理员账号 (密码: admin123, bcrypt hash)
INSERT INTO users (phone, password_hash, nickname, role, status)
VALUES ('00000000000', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '系统管理员', 1, 1);
