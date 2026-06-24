import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, Row, Col, Button, Table, Statistic, Space, Tag, Progress } from 'antd';
import {
  ShoppingCartOutlined,
  CarOutlined,
  ClockCircleOutlined,
  TeamOutlined,
  PlusOutlined,
  RiseOutlined,
  DollarOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { colors } from '@/styles/theme';
import StatusTag from '@/components/StatusTag';

interface DashboardStats {
  totalOrders: number;
  todayOrders: number;
  onlineDrivers: number;
  pendingOrders: number;
  totalPassengers: number;
  totalDrivers: number;
}

const statCardStyle = (borderColor: string): React.CSSProperties => ({
  borderLeft: `4px solid ${borderColor}`,
  cursor: 'pointer',
  transition: 'box-shadow 0.2s',
});

export default function DashboardPage() {
  const navigate = useNavigate();
  const [stats, setStats] = useState<DashboardStats>({
    totalOrders: 0, todayOrders: 0, onlineDrivers: 0,
    pendingOrders: 0, totalPassengers: 0, totalDrivers: 0,
  });
  const [recentOrders, setRecentOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  async function fetchDashboardData() {
    setLoading(true);
    try {
      const today = dayjs().format('YYYY-MM-DD');
      const [ordersRes, onlineRes, pendingRes, passengersRes, recentRes, driversRes, todayOrdersRes] = await Promise.allSettled([
        api.get('/admin/orders', { params: { offset: 0, limit: 1 } }),
        api.get('/admin/locations/drivers'),
        api.get('/admin/orders', { params: { status: 1, offset: 0, limit: 1 } }),
        api.get('/admin/users', { params: { role: 2, offset: 0, limit: 1 } }),
        api.get('/admin/orders', { params: { offset: 0, limit: 5 } }),
        api.get('/admin/users', { params: { role: 3, offset: 0, limit: 1 } }),
        api.get('/admin/orders', { params: { offset: 0, limit: 1, created_after: today } }),
      ]);

      const getData = (result: PromiseSettledResult<any>) =>
        result.status === 'fulfilled' ? result.value.data : null;

      const ordersData = getData(ordersRes);
      const onlineData = getData(onlineRes);
      const pendingData = getData(pendingRes);
      const passengersData = getData(passengersRes);
      const recentData = getData(recentRes);
      const driversData = getData(driversRes);
      const todayData = getData(todayOrdersRes);

      setStats({
        totalOrders: ordersData?.total ?? 0,
        todayOrders: todayData?.total ?? 0,
        onlineDrivers: Array.isArray(onlineData) ? onlineData.length : 0,
        pendingOrders: pendingData?.total ?? 0,
        totalPassengers: passengersData?.total ?? 0,
        totalDrivers: driversData?.total ?? 0,
      });
      setRecentOrders(recentData?.list ?? []);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      {/* 核心指标 */}
      <Row gutter={[16, 16]}>
        <Col span={6}>
          <Card loading={loading} style={statCardStyle(colors.primary)}
            onClick={() => navigate('/order')} hoverable>
            <Statistic title="订单总数" value={stats.totalOrders}
              prefix={<ShoppingCartOutlined />} valueStyle={{ color: colors.primary }}
              suffix={<span style={{ fontSize: 14, color: colors.textHint }}>今日 +{stats.todayOrders}</span>} />
          </Card>
        </Col>
        <Col span={6}>
          <Card loading={loading} style={statCardStyle(colors.info)}
            onClick={() => navigate('/monitor')} hoverable>
            <Statistic title="在线司机" value={stats.onlineDrivers}
              prefix={<CarOutlined />} valueStyle={{ color: colors.info }}
              suffix={<span style={{ fontSize: 14, color: colors.textHint }}>/ {stats.totalDrivers} 总</span>} />
          </Card>
        </Col>
        <Col span={6}>
          <Card loading={loading} style={statCardStyle(colors.warning)}
            onClick={() => navigate('/order')} hoverable>
            <Statistic title="待派单" value={stats.pendingOrders}
              prefix={<ClockCircleOutlined />} valueStyle={{ color: colors.warning }} />
          </Card>
        </Col>
        <Col span={6}>
          <Card loading={loading} style={statCardStyle(colors.textSecondary)}
            onClick={() => navigate('/passenger')} hoverable>
            <Statistic title="乘客总数" value={stats.totalPassengers}
              prefix={<TeamOutlined />} valueStyle={{ color: colors.textPrimary }} />
          </Card>
        </Col>
      </Row>

      {/* 快捷操作 */}
      <Card title="快捷操作" style={{ marginTop: 16 }}>
        <Space wrap>
          <Button type="primary" icon={<PlusOutlined />}
            onClick={() => navigate('/passenger/create')}>创建乘客</Button>
          <Button icon={<PlusOutlined />}
            onClick={() => navigate('/driver/create')}>创建司机</Button>
          <Button onClick={() => navigate('/order')}>查看订单</Button>
          <Button onClick={() => navigate('/monitor')}>实时监控</Button>
        </Space>
      </Card>

      {/* 最近订单 */}
      <Card title="最近订单" extra={<a onClick={() => navigate('/order')}>查看全部 →</a>}
        style={{ marginTop: 16 }}>
        <Table
          dataSource={recentOrders}
          rowKey="id"
          pagination={false}
          size="small"
          columns={[
            { title: '订单号', dataIndex: 'order_no', width: 180 },
            { title: '乘客', dataIndex: ['passenger', 'nickname'], width: 100 },
            { title: '司机', dataIndex: ['driver', 'real_name'], width: 100,
              render: (v: string | undefined) => v || <span style={{ color: colors.textHint }}>待分配</span> },
            { title: '状态', dataIndex: 'status', width: 100,
              render: (v: number) => <StatusTag status={v} type="order" /> },
            { title: '预估费用', dataIndex: 'est_price', width: 100,
              render: (v: number) => v != null ? `¥${Number(v).toFixed(2)}` : '-' },
            { title: '创建时间', dataIndex: 'created_at', width: 170,
              render: (v: string) => v ? dayjs(v).format('MM-DD HH:mm') : '-' },
          ]}
          locale={{ emptyText: '暂无订单数据' }}
        />
      </Card>
    </div>
  );
}
