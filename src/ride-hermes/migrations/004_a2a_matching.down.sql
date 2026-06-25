-- 004_a2a_matching.down.sql
-- 回滚A-to-A撮合引擎相关表

DROP TABLE IF EXISTS revenue_records;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS matching_offers;
DROP TABLE IF EXISTS matching_demands;
DROP TABLE IF EXISTS driver_agent_profiles;

-- 回滚orders表扩展
ALTER TABLE orders DROP COLUMN IF EXISTS demand_id;
ALTER TABLE orders DROP COLUMN IF EXISTS matching_mode;

-- 回滚drivers表扩展
ALTER TABLE drivers DROP COLUMN IF EXISTS subscription_id;
