import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Card, Descriptions, Tag, Steps, Row, Col, Spin } from 'antd';
import {
  EnvironmentOutlined,
  ClockCircleOutlined,
  CarOutlined,
  UserOutlined,
  DollarOutlined,
} from '@ant-design/icons';
import api from '@/services/api';
import { ORDER_STATUS_MAP, CAR_TYPE_MAP } from '@/utils/constants';
import { formatDistance, formatDuration } from '@/utils/format';
import { OrderStatus, type Order } from '@/types/order';

export default function OrderDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (id) fetchOrder(Number(id));
  }, [id]);

  async function fetchOrder(orderId: number) {
    setLoading(true);
    try {
      const resp = await api.get(`/admin/orders/${orderId}`);
      setOrder(resp.data);
    } catch {
      // error handled by interceptor
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

  if (!order) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <p style={{ color: '#999' }}>订单不存在</p>
        <a onClick={() => navigate('/order')}>返回订单列表</a>
      </div>
    );
  }

  const statusInfo = ORDER_STATUS_MAP[order.status];

  // Calculate step index based on status
  const stepIndex = (() => {
    if (order.status === OrderStatus.CANCELLED) return -1;
    if (order.status >= 7) return 5;
    if (order.status >= 5) return order.status - 2;
    return Math.max(0, order.status - 1);
  })();

  const stepItems = [
    { title: '创建订单', description: order.created_at },
    { title: '已派单', description: order.assigned_at },
    { title: '司机接单', description: order.accepted_at },
    { title: '到达上车点', description: order.arrived_at },
    { title: '开始行程', description: order.started_at },
    { title: '行程完成', description: order.ended_at },
  ];

  return (
    <div>
      <Card
        title={`订单详情 ${order.order_no}`}
        extra={<a onClick={() => navigate('/order')}>返回列表</a>}
      >
        {/* Basic Info */}
        <Card type="inner" title="基本信息" size="small" style={{ marginBottom: 16 }}>
          <Descriptions column={2} size="small">
            <Descriptions.Item label="订单号">{order.order_no}</Descriptions.Item>
            <Descriptions.Item label="状态">
              <Tag color={statusInfo?.color}>{statusInfo?.text}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="预约出发时间">{order.departure_time}</Descriptions.Item>
            <Descriptions.Item label="创建时间">{order.created_at}</Descriptions.Item>
            <Descriptions.Item label="车型">
              {CAR_TYPE_MAP[order.car_type] ?? order.car_type}
            </Descriptions.Item>
          </Descriptions>
        </Card>

        <Row gutter={16} style={{ marginBottom: 16 }}>
          {/* Passenger Info */}
          <Col span={8}>
            <Card type="inner" title={<><UserOutlined /> 乘客信息</>} size="small">
              <p style={{ margin: '4px 0' }}>{order.passenger?.nickname ?? '-'}</p>
              <p style={{ margin: 0, color: '#999' }}>{order.passenger?.phone ?? '-'}</p>
            </Card>
          </Col>

          {/* Driver Info */}
          <Col span={8}>
            <Card type="inner" title={<><CarOutlined /> 司机信息</>} size="small">
              {order.status >= OrderStatus.ASSIGNED && order.driver ? (
                <>
                  <p style={{ margin: '4px 0' }}>{order.driver.real_name}</p>
                  <p style={{ margin: 0, color: '#999' }}>
                    {order.driver.vehicle?.plate_number ?? '-'}
                    {' '}
                    {order.driver.vehicle?.brand ?? ''} {order.driver.vehicle?.model ?? ''}
                  </p>
                  <p style={{ margin: 0, color: '#999' }}>
                    评分: {order.driver.rating?.toFixed(1) ?? '-'}
                  </p>
                </>
              ) : (
                <span style={{ color: '#999' }}>待分配</span>
              )}
            </Card>
          </Col>

          {/* Price Info */}
          <Col span={8}>
            <Card type="inner" title={<><DollarOutlined /> 费用信息</>} size="small">
              <p style={{ margin: '4px 0' }}>
                预估: <span style={{ fontWeight: 600, color: '#0D9488' }}>¥{order.est_price}</span>
              </p>
              <p style={{ margin: 0, color: '#999' }}>
                实际: {order.actual_price ? `¥${order.actual_price}` : '—'}
              </p>
            </Card>
          </Col>
        </Row>

        {/* Trip Info */}
        <Card type="inner" title={<><EnvironmentOutlined /> 行程信息</>} size="small" style={{ marginBottom: 16 }}>
          <Descriptions column={2} size="small">
            <Descriptions.Item label="起点">{order.pickup_addr}</Descriptions.Item>
            <Descriptions.Item label="终点">{order.dropoff_addr}</Descriptions.Item>
            <Descriptions.Item label="距离">
              {formatDistance(order.est_distance)}
            </Descriptions.Item>
            <Descriptions.Item label="预计时长">
              {formatDuration(order.est_duration)}
            </Descriptions.Item>
          </Descriptions>
        </Card>

        {/* Progress Timeline */}
        {order.status !== OrderStatus.CANCELLED && (
          <Card type="inner" title={<><ClockCircleOutlined /> 订单进度</>} size="small" style={{ marginBottom: 16 }}>
            <Steps
              current={stepIndex}
              size="small"
              status="process"
              items={stepItems.map((item) => ({
                title: item.title,
                description: item.description || '—',
              }))}
            />
          </Card>
        )}

        {/* Cancel Info */}
        {order.status === OrderStatus.CANCELLED && (
          <Card type="inner" title="取消信息" size="small">
            <Descriptions column={2} size="small">
              <Descriptions.Item label="取消时间">{order.cancelled_at || '—'}</Descriptions.Item>
              <Descriptions.Item label="取消原因">{order.cancel_reason || '—'}</Descriptions.Item>
            </Descriptions>
          </Card>
        )}
      </Card>
    </div>
  );
}
