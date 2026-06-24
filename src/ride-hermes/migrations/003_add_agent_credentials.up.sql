CREATE TABLE agent_credentials (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL COMMENT '委托的乘客用户ID',
    agent_name      VARCHAR(64)     NOT NULL COMMENT '智能体标识: openclaw/hermes/openhuman',
    api_key_hash    VARCHAR(128)    NOT NULL COMMENT 'API Key 的 SHA-256 哈希',
    permissions     JSON            COMMENT '权限列表: ["ride:book", "ride:cancel"]',
    rate_limit      INT             NOT NULL DEFAULT 60 COMMENT '每分钟最大请求数',
    status          TINYINT         NOT NULL DEFAULT 1 COMMENT '1=active, 0=disabled',
    last_used_at    DATETIME        NULL COMMENT '最后一次使用时间',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME        NULL COMMENT '软删除',
    INDEX idx_user_agent (user_id, agent_name),
    UNIQUE INDEX idx_api_key_hash (api_key_hash),
    INDEX idx_deleted_at (deleted_at),
    CONSTRAINT fk_agent_cred_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能体API认证凭证表';

CREATE TABLE agent_call_log (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    credential_id   BIGINT UNSIGNED NOT NULL COMMENT '关联的agent_credentials ID',
    user_id         BIGINT UNSIGNED NOT NULL COMMENT '委托的乘客用户ID',
    agent_name      VARCHAR(64)     NOT NULL COMMENT '智能体标识',
    endpoint        VARCHAR(128)    NOT NULL COMMENT '调用的 API 路径',
    request_body    JSON            COMMENT '请求体（脱敏后）',
    response_code   INT             COMMENT 'HTTP 状态码',
    order_id        BIGINT UNSIGNED NULL COMMENT '关联的订单ID',
    ip_address      VARCHAR(45)     NOT NULL DEFAULT '' COMMENT '请求来源IP',
    latency_ms      INT             NOT NULL DEFAULT 0 COMMENT '处理耗时(毫秒)',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_credential (credential_id),
    INDEX idx_user (user_id),
    INDEX idx_created (created_at),
    CONSTRAINT fk_call_log_credential FOREIGN KEY (credential_id) REFERENCES agent_credentials(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能体API调用审计日志表';
