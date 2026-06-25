import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Card,
  Descriptions,
  Tag,
  Row,
  Col,
  Spin,
  Statistic,
  Timeline,
  Progress,
  Button,
  Space,
  message,
} from 'antd';
import {
  UserOutlined,
  CrownOutlined,
  DollarOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  HistoryOutlined,
  ArrowLeftOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { colors } from '@/styles/theme';
import {
  SUBSCRIPTION_STATUS_MAP,
  SUBSCRIPTION_PLAN_MAP,
} from '@/utils/constants';
import type { Subscription } from '@/types/subscription';

interface DriverSubscription {
  subscription: Subscription;
  history: Subscription[];
  stats: {
    total_orders_with_sub: number;
    total_spent: number;
    active_days: number;
    remaining_days: number;
    usage_rate: number;
  };
}

/** 简易柱状图 */
function MiniBarChart({ data, color, height = 120 }: {
  data: { label: string; value: number }[];
  color: string;
  height?: number;
}) {
  const max = Math.max(...data.map((d) => d.value), 1);
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height, padding: '0 4px' }}>
      {data.map((d, i) => (
        <div
          key={i}
          style={{
            flex: 1,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'flex-end',
            height: '100%',
          }}
        >
          <span style={{ fontSize: 10, color: colors.textHint, marginBottom: 2 }}>
            {d.value}
          </span>
          <div
            style={{
              width: '100%',
              maxWidth: 28,
              height: `${(d.value / max) * 100}%`,
              minHeight: 2,
              background: color,
              borderRadius: '3px 3px 0 0',
            }}
          />
          <span style={{ fontSize: 10, color: colors.textHint, marginTop: 2 }}>
            {d.label}
          </span>
        </div>
      ))}
    </div>
  );
}

export default function SubscriptionDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [data, setData] = useState<DriverSubscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [monthlyOrders, setMonthlyOrders] = useState<{ label: string; value: number }[]>([]);

  useEffect(() => {
    if (id) fetchDetail(Number(id));
  }, [id]);

  async function fetchDetail(driverId: number) {
    setLoading(true);
    try {
      const [detailRes, ordersRes] = await Promise.allSettled([
        api.get(`/admin/subscriptions/driver/${driverId}`),
        api.get(`/admin/subscriptions/driver/${driverId}/monthly-orders`),
      ]);

      const getData = (r: PromiseSettledResult<unknown>) =>
        r.status === 'fulfilled' ? (r.value as { data: unknown }).data : null;

      const detailData = getData(detailRes) as DriverSubscription | null;
      const ordersData = getData(ordersRes) as Array<{ month: string; order_count: number }> | null;

      if (detailData) setData(detailData);
      if (Array.isArray(ordersData)) {
        setMonthlyOrders(
          ordersData.map((o) => ({
            label: dayjs(o.month).format('MM月'),
            value: o.order_count,
          }))
        );
      }
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  }

  const handleCancelSubscription = async () => {
    if (!data) return;
    try {
      await api.post(`/admin/subscriptions/${data.subscription.id}/cancel`);
      message.success('已取消订阅');
      fetchDetail(Number(id));
    } catch {
      // error handled by interceptor
    }
  };

  const handleRenewSubscription = async () => {
    if (!data) return;
    try {
      await api.post(`/admin/subscriptions/${data.subscription.id}/renew`);
      message.success('续订成功');
      fetchDetail(Number(id));
    } catch {
      // error handled by interceptor
    }
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!data || !data.subscription) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <p style={{ color: '#999' }}>未找到该司机的订阅信息</p>
        <a onClick={() => navigate('/subscription')}>返回订阅列表</a>
      </div>
    );
  }

  const { subscription: sub, history, stats } = data;
  const statusInfo = SUBSCRIPTION_STATUS_MAP[sub.status];
  const planInfo = SUBSCRIPTION_PLAN_MAP[sub.plan];
  const isExpired = sub.end_date ? dayjs(sub.end_date).isBefore(dayjs()) : false;
  const remainingDays = stats?.remaining_days ?? 0;

  return (
    <div>
      <Card
        title={
          <span>
            <ArrowLeftOutlined
              style={{ marginRight: 8, cursor: 'pointer' }}
              onClick={() => navigate('/subscription')}
            />
            司机订阅详情 - {sub.driver_name}
          </span>
        }
        extra={
          <Space>
            {sub.status === 2 && (
              <Button danger onClick={handleCancelSubscription}>
                取消订阅
              </Button>
            )}
            {(sub.status === 3 || sub.status === 4) && (
              <Button type="primary" onClick={handleRenewSubscription}>
                续订
              </Button>
            )}
          </Space>
        }
      >
        {/* 基本信息 */}
        <Card type="inner" title={<><UserOutlined /> 司机信息</>} size="small" style={{ marginBottom: 16 }}>
          <Descriptions column={3} size="small">
            <Descriptions.Item label="姓名">{sub.driver_name}</Descriptions.Item>
            <Descriptions.Item label="手机号">{sub.driver_phone}</Descriptions.Item>
            <Descriptions.Item label="司机ID">{sub.driver_id}</Descriptions.Item>
          </Descriptions>
        </Card>

        {/* 订阅信息 */}
        <Card type="inner" title={<><CrownOutlined /> 当前订阅</>} size="small" style={{ marginBottom: 16 }}>
          <Descriptions column={3} size="small">
            <Descriptions.Item label="套餐">
              <Tag color={sub.plan === 3 ? 'gold' : sub.plan === 2 ? 'cyan' : sub.plan === 1 ? 'blue' : 'default'}>
                {planInfo?.text ?? '未知'}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label="状态">
              <Tag color={statusInfo?.color}>{statusInfo?.text}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="费用">
              {sub.price > 0 ? `¥${sub.price.toFixed(2)}/月` : '免费'}
            </Descriptions.Item>
            <Descriptions.Item label="开始日期">
              {sub.start_date ? dayjs(sub.start_date).format('YYYY-MM-DD') : '-'}
            </Descriptions.Item>
            <Descriptions.Item label="到期日期">
              <span style={isExpired ? { color: colors.error } : undefined}>
                {sub.end_date ? dayjs(sub.end_date).format('YYYY-MM-DD') : '-'}
              </span>
            </Descriptions.Item>
            <Descriptions.Item label="自动续费">
              {sub.auto_renew ? (
                <Tag color="green">已开启</Tag>
              ) : (
                <Tag color="default">未开启</Tag>
              )}
            </Descriptions.Item>
            <Descriptions.Item label="支付方式">{sub.payment_method || '-'}</Descriptions.Item>
            <Descriptions.Item label="订阅时间">
              {sub.created_at ? dayjs(sub.created_at).format('YYYY-MM-DD HH:mm') : '-'}
            </Descriptions.Item>
          </Descriptions>

          {/* 剩余天数进度 */}
          {sub.status === 2 && !isExpired && (
            <div style={{ marginTop: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                <span style={{ fontSize: 13 }}>订阅有效期</span>
                <span style={{ fontSize: 13, color: remainingDays <= 7 ? colors.error : colors.textSecondary }}>
                  剩余 {remainingDays} 天
                </span>
              </div>
              <Progress
                percent={Math.min(100, Math.round((remainingDays / 30) * 100))}
                strokeColor={remainingDays <= 7 ? colors.error : colors.primary}
                size="small"
              />
            </div>
          )}
        </Card>

        {/* 统计数据 */}
        <Row gutter={16} style={{ marginBottom: 16 }}>
          <Col span={6}>
            <Card size="small">
              <Statistic
                title="订阅期间订单"
                value={stats?.total_orders_with_sub ?? 0}
                prefix={<CheckCircleOutlined />}
                valueStyle={{ color: colors.primary }}
              />
            </Card>
          </Col>
          <Col span={6}>
            <Card size="small">
              <Statistic
                title="累计消费"
                value={stats?.total_spent ?? 0}
                prefix={<DollarOutlined />}
                valueStyle={{ color: colors.warning }}
                suffix="元"
                precision={2}
              />
            </Card>
          </Col>
          <Col span={6}>
            <Card size="small">
              <Statistic
                title="活跃天数"
                value={stats?.active_days ?? 0}
                prefix={<ClockCircleOutlined />}
                valueStyle={{ color: colors.info }}
                suffix="天"
              />
            </Card>
          </Col>
          <Col span={6}>
            <Card size="small">
              <Statistic
                title="使用率"
                value={stats?.usage_rate ?? 0}
                prefix={<CrownOutlined />}
                valueStyle={{ color: colors.success }}
                suffix="%"
                precision={1}
              />
            </Card>
          </Col>
        </Row>

        {/* 月度订单趋势 + 订阅历史 */}
        <Row gutter={16} style={{ marginBottom: 16 }}>
          <Col span={12}>
            <Card type="inner" title={<><HistoryOutlined /> 月度订单趋势</>} size="small">
              {monthlyOrders.length > 0 ? (
                <MiniBarChart data={monthlyOrders} color={colors.primary} />
              ) : (
                <div style={{ textAlign: 'center', padding: 24, color: colors.textHint }}>
                  暂无数据
                </div>
              )}
            </Card>
          </Col>
          <Col span={12}>
            <Card type="inner" title={<><ClockCircleOutlined /> 订阅历史</>} size="small">
              {history && history.length > 0 ? (
                <Timeline
                  items={history.map((h) => {
                    const hStatus = SUBSCRIPTION_STATUS_MAP[h.status];
                    const hPlan = SUBSCRIPTION_PLAN_MAP[h.plan];
                    return {
                      color: h.status === 2 ? 'green' : h.status === 4 ? 'red' : 'blue',
                      children: (
                        <div>
                          <div>
                            <Tag color={hStatus?.color}>{hStatus?.text}</Tag>
                            <strong>{hPlan?.text ?? h.plan_name}</strong>
                            {h.price > 0 && <span style={{ color: colors.textSecondary }}> ¥{h.price}</span>}
                          </div>
                          <div style={{ fontSize: 12, color: colors.textHint }}>
                            {h.start_date ? dayjs(h.start_date).format('YYYY-MM-DD') : '-'}
                            {' ~ '}
                            {h.end_date ? dayjs(h.end_date).format('YYYY-MM-DD') : '-'}
                          </div>
                        </div>
                      ),
                    };
                  })}
                />
              ) : (
                <div style={{ textAlign: 'center', padding: 24, color: colors.textHint }}>
                  暂无历史记录
                </div>
              )}
            </Card>
          </Col>
        </Row>
      </Card>
    </div>
  );
}
