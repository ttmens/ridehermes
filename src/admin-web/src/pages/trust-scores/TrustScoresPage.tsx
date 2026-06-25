import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Card,
  Row,
  Col,
  Statistic,
  Table,
  Tag,
  Spin,
  Space,
  Modal,
  Form,
  Select,
  Input,
  Button,
  message,
  Progress,
  Tooltip,
  Empty,
} from 'antd';
import {
  SafetyCertificateOutlined,
  UserOutlined,
  WarningOutlined,
  CheckCircleOutlined,
  ExclamationCircleOutlined,
  CloseCircleOutlined,
  CheckOutlined,
  CloseOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { colors } from '@/styles/theme';

/* ==================== 类型定义 ==================== */

interface TrustScoreItem {
  driver_id: number;
  driver_name: string;
  driver_phone: string;
  trust_score: number;
  total_orders: number;
  completed_orders: number;
  cancellation_rate: number;
  rating: number;
  anomaly_count: number;
  last_anomaly_at: string | null;
  created_at: string;
  updated_at: string;
}

interface TrustScoreStats {
  total_drivers: number;
  high_trust_count: number;
  medium_trust_count: number;
  low_trust_count: number;
  avg_score: number;
  anomaly_total: number;
  pending_anomaly_count: number;
}

interface AnomalyItem {
  id: number;
  driver_id: number;
  driver_name: string;
  driver_phone: string;
  anomaly_type: string;
  description: string;
  score_deduction: number;
  status: 'pending' | 'resolved' | 'dismissed';
  detected_at: string;
  resolved_at: string | null;
  handler: string | null;
}

/* ==================== 工具函数 ==================== */

/** 根据信誉分返回对应的颜色 */
function scoreColor(score: number): string {
  if (score >= 80) return colors.success;
  if (score >= 60) return colors.warning;
  return colors.error;
}

/** 根据信誉分返回对应的等级标签 */
function scoreLevelTag(score: number) {
  if (score >= 80)
    return <Tag color="success" icon={<CheckCircleOutlined />}>优秀</Tag>;
  if (score >= 60)
    return <Tag color="warning" icon={<ExclamationCircleOutlined />}>一般</Tag>;
  return <Tag color="error" icon={<CloseCircleOutlined />}>低危</Tag>;
}

/** 异常类型映射 */
const ANOMALY_TYPE_MAP: Record<string, { text: string; color: string }> = {
  high_cancellation: { text: '高取消率', color: 'orange' },
  frequent_complaints: { text: '频繁投诉', color: 'red' },
  abnormal_route: { text: '异常路线', color: 'purple' },
  long_idle: { text: '长时间空闲', color: 'geekblue' },
  fake_order: { text: '疑似刷单', color: 'volcano' },
  low_rating: { text: '低评分', color: 'magenta' },
};

function anomalyTypeTag(type: string) {
  const info = ANOMALY_TYPE_MAP[type];
  return info ? <Tag color={info.color}>{info.text}</Tag> : <Tag>{type}</Tag>;
}

/** 统计卡片边框样式 */
const statCardStyle = (borderColor: string): React.CSSProperties => ({
  borderLeft: `4px solid ${borderColor}`,
  cursor: 'default',
  transition: 'box-shadow 0.2s',
});

/* ==================== 处理弹窗 ==================== */

interface AnomalyModalProps {
  open: boolean;
  record: AnomalyItem | null;
  onClose: () => void;
  onSuccess: () => void;
}

function AnomalyHandleModal({ open, record, onClose, onSuccess }: AnomalyModalProps) {
  const [form] = Form.useForm();
  const [submitting, setSubmitting] = useState(false);

  const handleOk = async () => {
    if (!record) return;
    try {
      const values = await form.validateFields();
      setSubmitting(true);
      await api.post(`/admin/trust-scores/anomalies/${record.id}/handle`, values);
      message.success('处理成功');
      form.resetFields();
      onSuccess();
      onClose();
    } catch (err: unknown) {
      if (err && typeof err === 'object' && 'errorFields' in err) {
        // form validation error, do nothing
      } else {
        message.error('处理失败，请重试');
      }
    } finally {
      setSubmitting(false);
    }
  };

  const handleCancel = () => {
    form.resetFields();
    onClose();
  };

  return (
    <Modal
      title={
        <Space>
          <WarningOutlined style={{ color: colors.warning }} />
          处理异常预警
        </Space>
      }
      open={open}
      onOk={handleOk}
      onCancel={handleCancel}
      confirmLoading={submitting}
      okText="提交处理"
      cancelText="取消"
      destroyOnClose
    >
      {record ? (
        <div style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 8 }}>
            <span style={{ fontWeight: 600, marginRight: 8 }}>司机：</span>
            {record.driver_name}
            <span style={{ color: colors.textSecondary, marginLeft: 8 }}>
              ({record.driver_phone})
            </span>
          </div>
          <div style={{ marginBottom: 8 }}>
            <span style={{ fontWeight: 600, marginRight: 8 }}>异常类型：</span>
            {anomalyTypeTag(record.anomaly_type)}
          </div>
          <div style={{ marginBottom: 8 }}>
            <span style={{ fontWeight: 600, marginRight: 8 }}>异常描述：</span>
            {record.description}
          </div>
          <div style={{ marginBottom: 8 }}>
            <span style={{ fontWeight: 600, marginRight: 8 }}>信誉扣分：</span>
            <span style={{ color: colors.error }}>-{record.score_deduction}</span>
          </div>
          <div>
            <span style={{ fontWeight: 600, marginRight: 8 }}>检测时间：</span>
            {dayjs(record.detected_at).format('YYYY-MM-DD HH:mm:ss')}
          </div>
        </div>
      ) : (
        <Empty description="未选择异常记录" />
      )}

      <Form
        form={form}
        layout="vertical"
        initialValues={{ action: 'resolved' }}
      >
        <Form.Item
          name="action"
          label="处理方式"
          rules={[{ required: true, message: '请选择处理方式' }]}
        >
          <Select
            options={[
              { value: 'resolved', label: '标记已处理 — 确认异常属实并已处理' },
              { value: 'dismissed', label: '标记已忽略 — 确认异常为误报' },
            ]}
          />
        </Form.Item>
        <Form.Item
          name="remark"
          label="处理备注"
          rules={[{ max: 200, message: '备注不超过200字' }]}
        >
          <Input.TextArea
            rows={3}
            placeholder="请输入处理说明（可选）"
            maxLength={200}
            showCount
          />
        </Form.Item>
      </Form>
    </Modal>
  );
}

/* ==================== 主页面组件 ==================== */

export default function TrustScoresPage() {
  const navigate = useNavigate();

  // 数据状态
  const [stats, setStats] = useState<TrustScoreStats | null>(null);
  const [drivers, setDrivers] = useState<TrustScoreItem[]>([]);
  const [anomalies, setAnomalies] = useState<AnomalyItem[]>([]);
  const [loading, setLoading] = useState(true);

  // 弹窗状态
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedAnomaly, setSelectedAnomaly] = useState<AnomalyItem | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    setLoading(true);
    try {
      const [statsRes, driversRes, anomaliesRes] = await Promise.allSettled([
        api.get('/admin/trust-scores/stats'),
        api.get('/admin/trust-scores'),
        api.get('/admin/trust-scores/anomalies'),
      ]);

      const getData = (r: PromiseSettledResult<any>) =>
        r.status === 'fulfilled' ? r.value.data : null;

      const statsData = getData(statsRes);
      const driversData = getData(driversRes);
      const anomaliesData = getData(anomaliesRes);

      if (statsData) setStats(statsData);
      if (Array.isArray(driversData?.list)) setDrivers(driversData.list);
      else if (Array.isArray(driversData)) setDrivers(driversData);
      if (Array.isArray(anomaliesData?.list)) setAnomalies(anomaliesData.list);
      else if (Array.isArray(anomaliesData)) setAnomalies(anomaliesData);
    } finally {
      setLoading(false);
    }
  }

  /** 打开处理弹窗 */
  const openHandleModal = (record: AnomalyItem) => {
    setSelectedAnomaly(record);
    setModalOpen(true);
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <Spin size="large" />
      </div>
    );
  }

  /* ========== 司机列表列定义 ========== */
  const driverColumns = [
    {
      title: '司机姓名',
      dataIndex: 'driver_name',
      key: 'driver_name',
      width: 120,
      render: (v: string, record: TrustScoreItem) => (
        <a onClick={() => navigate(`/driver/${record.driver_id}`)}>{v}</a>
      ),
    },
    {
      title: '手机号',
      dataIndex: 'driver_phone',
      key: 'driver_phone',
      width: 130,
    },
    {
      title: '信誉分',
      dataIndex: 'trust_score',
      key: 'trust_score',
      width: 200,
      sorter: (a: TrustScoreItem, b: TrustScoreItem) => a.trust_score - b.trust_score,
      render: (score: number) => (
        <Tooltip title={`信誉等级：${score >= 80 ? '优秀' : score >= 60 ? '一般' : '低危'}`}>
          <Space>
            <Progress
              type="circle"
              percent={score}
              size={32}
              strokeColor={scoreColor(score)}
              format={(p) => `${p}`}
            />
            <SafetyCertificateOutlined style={{ color: scoreColor(score), fontSize: 18 }} />
            {scoreLevelTag(score)}
          </Space>
        </Tooltip>
      ),
    },
    {
      title: '总订单',
      dataIndex: 'total_orders',
      key: 'total_orders',
      width: 80,
      sorter: (a: TrustScoreItem, b: TrustScoreItem) => a.total_orders - b.total_orders,
    },
    {
      title: '完成订单',
      dataIndex: 'completed_orders',
      key: 'completed_orders',
      width: 100,
    },
    {
      title: '取消率',
      dataIndex: 'cancellation_rate',
      key: 'cancellation_rate',
      width: 100,
      render: (v: number) => `${(v * 100).toFixed(1)}%`,
    },
    {
      title: '评分',
      dataIndex: 'rating',
      key: 'rating',
      width: 80,
      render: (v: number) => (v ? v.toFixed(1) : '-'),
    },
    {
      title: '异常次数',
      dataIndex: 'anomaly_count',
      key: 'anomaly_count',
      width: 90,
      render: (v: number) =>
        v > 0 ? (
          <Tag color="red" icon={<WarningOutlined />}>
            {v}
          </Tag>
        ) : (
          <Tag color="default">0</Tag>
        ),
    },
    {
      title: '最近异常',
      dataIndex: 'last_anomaly_at',
      key: 'last_anomaly_at',
      width: 130,
      render: (v: string) => (v ? dayjs(v).format('MM-DD HH:mm') : '-'),
    },
    {
      title: '更新时间',
      dataIndex: 'updated_at',
      key: 'updated_at',
      width: 150,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD HH:mm') : '-'),
    },
  ];

  /* ========== 异常预警列定义 ========== */
  const anomalyColumns = [
    {
      title: '司机',
      dataIndex: 'driver_name',
      key: 'driver_name',
      width: 100,
      render: (v: string, r: AnomalyItem) => (
        <a onClick={() => navigate(`/driver/${r.driver_id}`)}>{v}</a>
      ),
    },
    {
      title: '手机号',
      dataIndex: 'driver_phone',
      key: 'driver_phone',
      width: 120,
    },
    {
      title: '异常类型',
      dataIndex: 'anomaly_type',
      key: 'anomaly_type',
      width: 110,
      render: (v: string) => anomalyTypeTag(v),
    },
    {
      title: '异常描述',
      dataIndex: 'description',
      key: 'description',
      width: 200,
      ellipsis: true,
    },
    {
      title: '扣分',
      dataIndex: 'score_deduction',
      key: 'score_deduction',
      width: 70,
      render: (v: number) => <span style={{ color: colors.error }}>-{v}</span>,
    },
    {
      title: '检测时间',
      dataIndex: 'detected_at',
      key: 'detected_at',
      width: 150,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 90,
      render: (v: string) => {
        const statusMap: Record<string, { text: string; color: string }> = {
          pending: { text: '待处理', color: 'orange' },
          resolved: { text: '已处理', color: 'green' },
          dismissed: { text: '已忽略', color: 'default' },
        };
        const info = statusMap[v] ?? { text: v, color: 'default' };
        return <Tag color={info.color}>{info.text}</Tag>;
      },
    },
    {
      title: '处理人',
      dataIndex: 'handler',
      key: 'handler',
      width: 90,
      render: (v: string | null) => v || '-',
    },
    {
      title: '操作',
      key: 'actions',
      width: 100,
      render: (_: unknown, record: AnomalyItem) =>
        record.status === 'pending' ? (
          <Button
            type="link"
            size="small"
            icon={<CheckOutlined />}
            onClick={() => openHandleModal(record)}
          >
            处理
          </Button>
        ) : (
          <span style={{ color: colors.textHint }}>已处理</span>
        ),
    },
  ];

  return (
    <div>
      {/* ====== 1. 总览统计卡片 ====== */}
      <Row gutter={[16, 16]}>
        <Col xs={12} sm={8} lg={4}>
          <Card loading={loading} style={statCardStyle(colors.primary)} hoverable>
            <Statistic
              title="司机总数"
              value={stats?.total_drivers ?? 0}
              prefix={<UserOutlined />}
              valueStyle={{ color: colors.primary }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card loading={loading} style={statCardStyle(colors.success)} hoverable>
            <Statistic
              title="高信誉 (≥80)"
              value={stats?.high_trust_count ?? 0}
              prefix={<CheckCircleOutlined />}
              valueStyle={{ color: colors.success }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card loading={loading} style={statCardStyle(colors.warning)} hoverable>
            <Statistic
              title="中等信誉 (60-79)"
              value={stats?.medium_trust_count ?? 0}
              prefix={<ExclamationCircleOutlined />}
              valueStyle={{ color: colors.warning }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card loading={loading} style={statCardStyle(colors.error)} hoverable>
            <Statistic
              title="低信誉 (<60)"
              value={stats?.low_trust_count ?? 0}
              prefix={<CloseCircleOutlined />}
              valueStyle={{ color: colors.error }}
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card loading={loading} style={statCardStyle(colors.info)} hoverable>
            <Statistic
              title="平均信誉分"
              value={stats?.avg_score ?? 0}
              prefix={<SafetyCertificateOutlined />}
              valueStyle={{ color: colors.info }}
              precision={1}
            />
          </Card>
        </Col>
        <Col xs={12} sm={8} lg={4}>
          <Card
            loading={loading}
            style={statCardStyle(colors.error)}
            hoverable
            onClick={() =>
              document.getElementById('anomaly-section')?.scrollIntoView({ behavior: 'smooth' })
            }
          >
            <Statistic
              title="待处理异常"
              value={stats?.pending_anomaly_count ?? 0}
              prefix={<WarningOutlined />}
              valueStyle={{ color: colors.error }}
            />
          </Card>
        </Col>
      </Row>

      {/* ====== 2. 司机信誉列表 ====== */}
      <Card
        title={
          <Space>
            <SafetyCertificateOutlined style={{ color: colors.primary }} />
            司机信誉分列表
          </Space>
        }
        size="small"
        style={{ marginTop: 16 }}
        extra={
          <Button size="small" onClick={fetchData}>
            刷新
          </Button>
        }
      >
        <Table
          columns={driverColumns}
          dataSource={drivers}
          rowKey="driver_id"
          size="small"
          scroll={{ x: 1200 }}
          pagination={{
            pageSize: 15,
            showTotal: (t) => `共 ${t} 位司机`,
            showSizeChanger: false,
          }}
          locale={{ emptyText: '暂无信誉数据' }}
        />
      </Card>

      {/* ====== 3. 异常预警列表 ====== */}
      <Card
        id="anomaly-section"
        title={
          <Space>
            <WarningOutlined style={{ color: colors.warning }} />
            异常预警列表
            {stats && stats.pending_anomaly_count > 0 && (
              <Tag color="error" style={{ marginLeft: 8 }}>
                待处理 {stats.pending_anomaly_count} 条
              </Tag>
            )}
          </Space>
        }
        size="small"
        style={{ marginTop: 16 }}
        extra={
          <Button size="small" onClick={fetchData}>
            刷新
          </Button>
        }
      >
        <Table
          columns={anomalyColumns}
          dataSource={anomalies}
          rowKey="id"
          size="small"
          scroll={{ x: 1050 }}
          pagination={{
            pageSize: 10,
            showTotal: (t) => `共 ${t} 条异常预警`,
            showSizeChanger: false,
          }}
          locale={{ emptyText: '暂无异常预警' }}
        />
      </Card>

      {/* ====== 4. 处理弹窗 ====== */}
      <AnomalyHandleModal
        open={modalOpen}
        record={selectedAnomaly}
        onClose={() => {
          setModalOpen(false);
          setSelectedAnomaly(null);
        }}
        onSuccess={fetchData}
      />
    </div>
  );
}
