import { useEffect, useState } from 'react';
import { Card, Row, Col, Statistic, Table, Tag, Space, Button, Spin, Timeline, Empty, Tooltip } from 'antd';
import {
  TeamOutlined,
  ThunderboltOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  SwapOutlined,
  RiseOutlined,
  WarningOutlined,
  ReloadOutlined,
  NodeIndexOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { colors } from '@/styles/theme';

/* ==================== 类型定义 ==================== */

interface MatchingStats {
  online_drivers: number;
  pending_demands: number;
  active_matches: number;
  today_matched: number;
  avg_response_time: number;      // 秒
  matching_success_rate: number;  // 百分比
  avg_offers_per_demand: number;
}

interface MatchingActivity {
  id: number;
  demand_id: number;
  passenger_name: string;
  driver_name: string;
  action: string;      // demand_published / offer_submitted / match_confirmed / order_created
  description: string;
  created_at: string;
}

interface PendingDemand {
  id: number;
  passenger_name: string;
  pickup_addr: string;
  dropoff_addr: string;
  departure_time: string;
  car_type: number;
  status: string;
  offer_count: number;
  remaining_seconds: number;
  created_at: string;
}

/* ==================== 工具函数 ==================== */

const ACTION_MAP: Record<string, { text: string; color: string }> = {
  demand_published: { text: '需求发布', color: 'blue' },
  offer_submitted: { text: '司机报价', color: 'orange' },
  match_confirmed: { text: '匹配确认', color: 'green' },
  order_created: { text: '订单创建', color: 'purple' },
};

const statCardStyle = (borderColor: string): React.CSSProperties => ({
  borderLeft: `4px solid ${borderColor}`,
  cursor: 'default',
  transition: 'box-shadow 0.2s',
});

/* ==================== 主页面组件 ==================== */

export default function MatchingMonitorPage() {
  const [stats, setStats] = useState<MatchingStats | null>(null);
  const [activities, setActivities] = useState<MatchingActivity[]>([]);
  const [demands, setDemands] = useState<PendingDemand[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
    const timer = setInterval(fetchData, 15000); // 15秒自动刷新
    return () => clearInterval(timer);
  }, []);

  async function fetchData() {
    try {
      const [statsRes, activityRes, demandRes] = await Promise.allSettled([
        api.get('/admin/matching/stats'),
        api.get('/admin/matching/activities', { params: { limit: 20 } }),
        api.get('/admin/matching/demands', { params: { status: 'pending', limit: 10 } }),
      ]);

      const getData = (r: PromiseSettledResult<any>) =>
        r.status === 'fulfilled' ? r.value.data : null;

      const statsData = getData(statsRes);
      const activityData = getData(activityRes);
      const demandData = getData(demandRes);

      if (statsData) setStats(statsData);
      if (activityData?.list) setActivities(activityData.list);
      if (demandData?.list) setDemands(demandData.list);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <Spin size="large" tip="加载撮合数据..." />
      </div>
    );
  }

  // 待匹配需求列
  const demandColumns = [
    {
      title: '乘客', dataIndex: 'passenger_name', key: 'passenger_name', width: 110,
    },
    {
      title: '出发地', dataIndex: 'pickup_addr', key: 'pickup_addr', ellipsis: true,
    },
    {
      title: '目的地', dataIndex: 'dropoff_addr', key: 'dropoff_addr', ellipsis: true,
    },
    {
      title: '出发时间', dataIndex: 'departure_time', key: 'departure_time', width: 150,
      render: (v: string) => v ? dayjs(v).format('MM-DD HH:mm') : '-',
    },
    {
      title: '报价数', dataIndex: 'offer_count', key: 'offer_count', width: 70,
      render: (v: number) => <Tag color={v > 0 ? 'green' : 'default'}>{v}</Tag>,
    },
    {
      title: '剩余时间', dataIndex: 'remaining_seconds', key: 'remaining_seconds', width: 100,
      render: (v: number) => {
        if (v <= 0) return <Tag color="red">已超时</Tag>;
        if (v <= 30) return <Tag color="orange">{v}s</Tag>;
        return <span>{v}s</span>;
      },
    },
    {
      title: '状态', dataIndex: 'status', key: 'status', width: 90,
      render: (v: string) => {
        const map: Record<string, { text: string; color: string }> = {
          pending: { text: '匹配中', color: 'processing' },
          matched: { text: '已匹配', color: 'success' },
          expired: { text: '已过期', color: 'default' },
          cancelled: { text: '已取消', color: 'error' },
        };
        const info = map[v] ?? { text: v, color: 'default' };
        return <Tag color={info.color}>{info.text}</Tag>;
      },
    },
  ];

  // 撮合活动列
  const activityColumns = [
    {
      title: '时间', dataIndex: 'created_at', key: 'created_at', width: 160,
      render: (v: string) => v ? dayjs(v).format('HH:mm:ss') : '-',
    },
    {
      title: '操作', dataIndex: 'action', key: 'action', width: 100,
      render: (v: string) => {
        const info = ACTION_MAP[v];
        return info ? <Tag color={info.color}>{info.text}</Tag> : <Tag>{v}</Tag>;
      },
    },
    {
      title: '乘客', dataIndex: 'passenger_name', key: 'passenger_name', width: 100,
    },
    {
      title: '司机', dataIndex: 'driver_name', key: 'driver_name', width: 100,
      render: (v: string) => v || '-',
    },
    {
      title: '描述', dataIndex: 'description', key: 'description', ellipsis: true,
    },
  ];

  return (
    <div>
      {/* ====== 页面标题 ====== */}
      <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 style={{ margin: 0 }}>
            <NodeIndexOutlined style={{ color: colors.primary, marginRight: 8 }} />
            A-to-A 撮合监控
          </h2>
          <span style={{ color: colors.textHint, fontSize: 13 }}>
            实时监控 Agent-to-Agent 撮合引擎运行状态
          </span>
        </div>
        <Button icon={<ReloadOutlined />} onClick={fetchData}>
          刷新
        </Button>
      </div>

      {/* ====== 1. 核心指标 ====== */}
      <Row gutter={[16, 16]}>
        <Col xs={12} sm={8} lg={3}>
          <Card style={statCardStyle(colors.success)} hoverable>
            <Statistic
              title="在线司机"
              value={stats?.online_drivers ?? 0}
              prefix={<TeamOutlined />}
              valueStyle={{ color: colors.success }}
              suffix="人"
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={3}>
          <Card style={statCardStyle(colors.warning)} hoverable>
            <Statistic
              title="待匹配需求"
              value={stats?.pending_demands ?? 0}
              prefix={<ClockCircleOutlined />}
              valueStyle={{ color: colors.warning }}
              suffix="单"
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={3}>
          <Card style={statCardStyle(colors.primary)} hoverable>
            <Statistic
              title="进行中匹配"
              value={stats?.active_matches ?? 0}
              prefix={<SwapOutlined />}
              valueStyle={{ color: colors.primary }}
              suffix="单"
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={3}>
          <Card style={statCardStyle(colors.info)} hoverable>
            <Statistic
              title="今日匹配成功"
              value={stats?.today_matched ?? 0}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: colors.info }}
              suffix="单"
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card style={statCardStyle(colors.textSecondary)} hoverable>
            <Statistic
              title="平均响应时间"
              value={stats?.avg_response_time ?? 0}
              prefix={<ThunderboltOutlined />}
              valueStyle={{ color: colors.textPrimary }}
              suffix="秒"
              precision={1}
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card style={statCardStyle(colors.success)} hoverable>
            <Statistic
              title="撮合成功率"
              value={stats?.matching_success_rate ?? 0}
              prefix={<RiseOutlined />}
              valueStyle={{ color: colors.success }}
              suffix="%"
              precision={1}
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card style={statCardStyle(colors.primary)} hoverable>
            <Statistic
              title="平均报价数/需求"
              value={stats?.avg_offers_per_demand ?? 0}
              prefix={<TeamOutlined />}
              valueStyle={{ color: colors.primary }}
              precision={1}
            />
          </Card>
        </Col>
      </Row>

      {/* ====== 2. 撮合流程示意图 ====== */}
      <Card title={
        <Space>
          <NodeIndexOutlined style={{ color: colors.primary }} />
          A-to-A 撮合流程
        </Space>
      } size="small" style={{ marginTop: 16 }}>
        <div style={{ 
          display: 'flex', justifyContent: 'space-around', alignItems: 'center',
          padding: '24px 16px', background: '#fafafa', borderRadius: 8,
          fontSize: 13, color: colors.textSecondary
        }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 28, marginBottom: 4 }}>📱</div>
            <div><Tag color="blue">乘客发布需求</Tag></div>
          </div>
          <div style={{ fontSize: 24, color: colors.textHint }}>→</div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 28, marginBottom: 4 }}>📡</div>
            <div><Tag color="orange">MatchingEngine</Tag></div>
            <div style={{ fontSize: 11, marginTop: 2 }}>Redis Pub/Sub 广播</div>
          </div>
          <div style={{ fontSize: 24, color: colors.textHint }}>→</div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 28, marginBottom: 4 }}>🤖</div>
            <div><Tag color="purple">司机Agent评估</Tag></div>
            <div style={{ fontSize: 11, marginTop: 2 }}>偏好匹配 + 报价</div>
          </div>
          <div style={{ fontSize: 24, color: colors.textHint }}>→</div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 28, marginBottom: 4 }}>✅</div>
            <div><Tag color="green">乘客确认</Tag></div>
            <div style={{ fontSize: 11, marginTop: 2 }}>选择司机 → 订单</div>
          </div>
        </div>
      </Card>

      {/* ====== 3. 待匹配需求 + 撮合活动 ====== */}
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col span={12}>
          <Card
            title={
              <Space>
                <ClockCircleOutlined style={{ color: colors.warning }} />
                待匹配需求
                {demands.length > 0 && <Tag color="error" style={{ marginLeft: 4 }}>{demands.length}</Tag>}
              </Space>
            }
            size="small"
          >
            <Table
              columns={demandColumns}
              dataSource={demands}
              rowKey="id"
              size="small"
              scroll={{ x: 800 }}
              pagination={false}
              locale={{ emptyText: <Empty description="暂无待匹配需求" /> }}
            />
          </Card>
        </Col>
        <Col span={12}>
          <Card
            title={
              <Space>
                <NodeIndexOutlined style={{ color: colors.primary }} />
                最新撮合活动
              </Space>
            }
            size="small"
          >
            <Table
              columns={activityColumns}
              dataSource={activities}
              rowKey="id"
              size="small"
              scroll={{ x: 600 }}
              pagination={false}
              locale={{ emptyText: <Empty description="暂无撮合活动" /> }}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
}
