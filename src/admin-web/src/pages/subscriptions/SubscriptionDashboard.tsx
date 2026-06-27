import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, Row, Col, Statistic, Progress, Table, Tag, Spin } from 'antd';
import {
  TeamOutlined,
  DollarOutlined,
  RiseOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  CloseCircleOutlined,
  CrownOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { colors } from '@/styles/theme';
import {
  SUBSCRIPTION_STATUS_MAP,
  SUBSCRIPTION_PLAN_MAP,
} from '@/utils/constants';
import type {
  SubscriptionStats,
  SubscriptionTrend,
  PlanDistribution,
  Subscription,
} from '@/types/subscription';

const statCardStyle = (borderColor: string): React.CSSProperties => ({
  borderLeft: `4px solid ${borderColor}`,
  cursor: 'pointer',
  transition: 'box-shadow 0.2s',
});

/** 简易柱状图（纯 CSS，无需第三方库） */
function SimpleBarChart({
  data,
  dataKey,
  color,
  height = 160,
}: {
  data: { label: string; value: number }[];
  dataKey: string;
  color: string;
  height?: number;
}) {
  const max = Math.max(...data.map((d) => d.value), 1);
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height, padding: '0 4px' }}>
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
          <span style={{ fontSize: 11, color: colors.textSecondary, marginBottom: 4 }}>
            {d.value}
          </span>
          <div
            style={{
              width: '100%',
              maxWidth: 36,
              height: `${(d.value / max) * 100}%`,
              minHeight: 4,
              background: `linear-gradient(180deg, ${color}, ${color}88)`,
              borderRadius: '4px 4px 0 0',
              transition: 'height 0.3s',
            }}
          />
          <span style={{ fontSize: 11, color: colors.textHint, marginTop: 4 }}>
            {d.label}
          </span>
        </div>
      ))}
    </div>
  );
}

export default function SubscriptionDashboard() {
  const navigate = useNavigate();
  const [stats, setStats] = useState<SubscriptionStats | null>(null);
  const [trend, setTrend] = useState<SubscriptionTrend[]>([]);
  const [planDist, setPlanDist] = useState<PlanDistribution[]>([]);
  const [recentSubs, setRecentSubs] = useState<Subscription[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  async function fetchDashboardData() {
    setLoading(true);
    try {
      const [statsRes, trendRes, planRes, recentRes] = await Promise.allSettled([
        api.get('/admin/subscriptions/stats'),
        api.get('/admin/subscriptions/trend', { params: { days: 7 } }),
        api.get('/admin/subscriptions/plans/distribution'),
        api.get('/admin/subscriptions', { params: { offset: 0, limit: 5, sort: '-created_at' } }),
      ]);

      const getData = (r: PromiseSettledResult<any>) =>
        r.status === 'fulfilled' ? r.value.data : null;

      const statsData = getData(statsRes);
      const trendData = getData(trendRes);
      const planData = getData(planRes);
      const recentData = getData(recentRes);

      if (statsData) setStats(statsData);
      if (Array.isArray(trendData)) setTrend(trendData);
      
      // 套餐分布：后端返回 [{plan, count}] 格式
      if (Array.isArray(planData)) {
        // 计算百分比
        const total = planData.reduce((sum: number, p: any) => sum + (p.count ?? 0), 0);
        const withPct = planData.map((p: any) => ({
          ...p,
          percentage: total > 0 ? Math.round(((p.count ?? 0) / total) * 100) : 0,
        }));
        setPlanDist(withPct);
      }
      
      // 最近订阅：后端返回 data.subscriptions
      if (recentData?.subscriptions) {
        const recentList = recentData.subscriptions.slice(0, 5).map((s: any) => ({
          id: s.id,
          driver_id: s.driver_id,
          driver_name: s.driver?.real_name ?? s.driver_name ?? `司机 #${s.driver_id}`,
          driver_phone: s.driver?.user?.phone ?? '',
          plan_type: s.plan_type,
          plan: s.plan_type,
          plan_name: s.plan_name ?? '',
          price: s.monthly_fee ?? 0,
          status: s.status,
          start_date: s.start_date,
          end_date: s.expire_date ?? s.end_date,
          expire_date: s.expire_date,
          auto_renew: s.auto_renew ?? false,
          created_at: s.created_at,
        }));
        setRecentSubs(recentList);
      } else if (recentData?.list) {
        setRecentSubs(recentData.list);
      }
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <Spin size="large" />
      </div>
    );
  }

  // 构造图表数据
  const trendChartData = trend.map((t) => ({
    label: dayjs(t.date).format('MM-DD'),
    value: t.new_subscriptions,
  }));
  const revenueChartData = trend.map((t) => ({
    label: dayjs(t.date).format('MM-DD'),
    value: t.revenue,
  }));

  const planColors: Record<number, string> = {
    0: colors.textHint,
    1: colors.info,
    2: colors.primary,
    3: colors.warning,
  };

  return (
    <div>
      {/* 核心指标卡片 */}
      <Row gutter={[16, 16]}>
        <Col span={6}>
          <Card
            loading={loading}
            style={statCardStyle(colors.primary)}
            onClick={() => navigate('/subscription')}
            hoverable
          >
            <Statistic
              title="订阅总数"
              value={stats?.total_subscriptions ?? 0}
              prefix={<TeamOutlined />}
              valueStyle={{ color: colors.primary }}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card
            loading={loading}
            style={statCardStyle(colors.success)}
            onClick={() => navigate('/subscription')}
            hoverable
          >
            <Statistic
              title="生效中"
              value={stats?.active_subscriptions ?? 0}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: colors.success }}
              suffix={
                <span style={{ fontSize: 14, color: colors.textHint }}>
                  试用 {stats?.trial_subscriptions ?? 0}
                </span>
              }
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card
            loading={loading}
            style={statCardStyle(colors.warning)}
            hoverable
          >
            <Statistic
              title="本月收入"
              value={stats?.monthly_revenue ?? 0}
              prefix={<DollarOutlined />}
              valueStyle={{ color: colors.warning }}
              suffix="元"
              precision={2}
            />
          </Card>
        </Col>
        <Col span={6}>
          <Card
            loading={loading}
            style={statCardStyle(colors.info)}
            hoverable
          >
            <Statistic
              title="续费率"
              value={stats?.renewal_rate ?? 0}
              prefix={<RiseOutlined />}
              valueStyle={{ color: colors.info }}
              suffix="%"
              precision={1}
            />
          </Card>
        </Col>
      </Row>

      {/* 图表区域 */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col span={12}>
          <Card title="近7日新增订阅" size="small">
            {trendChartData.length > 0 ? (
              <SimpleBarChart data={trendChartData} dataKey="new_subscriptions" color={colors.primary} />
            ) : (
              <div style={{ textAlign: 'center', padding: 40, color: colors.textHint }}>
                暂无数据
              </div>
            )}
          </Card>
        </Col>
        <Col span={12}>
          <Card title="近7日收入趋势" size="small">
            {revenueChartData.length > 0 ? (
              <SimpleBarChart data={revenueChartData} dataKey="revenue" color={colors.warning} />
            ) : (
              <div style={{ textAlign: 'center', padding: 40, color: colors.textHint }}>
                暂无数据
              </div>
            )}
          </Card>
        </Col>
      </Row>

      {/* 套餐分布 + 最近订阅 */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col span={8}>
          <Card title="套餐分布" size="small">
            {planDist.length > 0 ? (
              <div>
                {planDist.map((p, i) => (
                  <div key={i} style={{ marginBottom: 12 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                      <span>{p.plan}</span>
                      <span style={{ color: colors.textSecondary }}>
                        {p.count} 人 ({p.percentage}%)
                      </span>
                    </div>
                    <Progress
                      percent={p.percentage}
                      showInfo={false}
                      strokeColor={planColors[i] ?? colors.primary}
                      size="small"
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ textAlign: 'center', padding: 24, color: colors.textHint }}>
                暂无数据
              </div>
            )}
          </Card>
        </Col>
        <Col span={16}>
          <Card
            title="最近订阅"
            size="small"
            extra={<a onClick={() => navigate('/subscription')}>查看全部 →</a>}
          >
            <Table
              dataSource={recentSubs}
              rowKey="id"
              pagination={false}
              size="small"
              columns={[
                {
                  title: '司机',
                  dataIndex: 'driver_name',
                  width: 100,
                  render: (v: string, r: Subscription) => (
                    <a onClick={() => navigate(`/subscription/${r.driver_id}`)}>{v}</a>
                  ),
                },
                { title: '套餐', dataIndex: 'plan_name', width: 80 },
                {
                  title: '状态',
                  dataIndex: 'status',
                  width: 90,
                  render: (v: number) => {
                    const info = SUBSCRIPTION_STATUS_MAP[v];
                    return info ? <Tag color={info.color}>{info.text}</Tag> : <Tag>{v}</Tag>;
                  },
                },
                {
                  title: '费用',
                  dataIndex: 'price',
                  width: 80,
                  render: (v: number) => (v > 0 ? `¥${v}` : '免费'),
                },
                {
                  title: '到期时间',
                  dataIndex: 'end_date',
                  width: 120,
                  render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD') : '-'),
                },
                {
                  title: '自动续费',
                  dataIndex: 'auto_renew',
                  width: 80,
                  render: (v: boolean) =>
                    v ? (
                      <Tag color="green">是</Tag>
                    ) : (
                      <Tag color="default">否</Tag>
                    ),
                },
              ]}
              locale={{ emptyText: '暂无订阅数据' }}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
}
