import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Table, Select, Space, Input, Button, Card, Tag, DatePicker } from 'antd';
import {
  SearchOutlined,
  ReloadOutlined,
  DownloadOutlined,
  FilterOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import {
  SUBSCRIPTION_STATUS_MAP,
  SUBSCRIPTION_PLAN_MAP,
} from '@/utils/constants';
import EmptyState from '@/components/EmptyState';
import type { Subscription } from '@/types/subscription';

const { RangePicker } = DatePicker;

export default function SubscriptionList() {
  const navigate = useNavigate();
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<number | undefined>();
  const [planFilter, setPlanFilter] = useState<number | undefined>();
  const [searchText, setSearchText] = useState('');
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);

  const fetchSubscriptions = async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = {
        offset: (page - 1) * 20,
        limit: 20,
      };
      if (statusFilter !== undefined) params.status = statusFilter;
      if (planFilter !== undefined) params.plan = planFilter;
      if (searchText) params.keyword = searchText;
      if (dateRange) {
        params.start_date = dateRange[0].format('YYYY-MM-DD');
        params.end_date = dateRange[1].format('YYYY-MM-DD');
      }

      const resp = await api.get('/admin/subscriptions', { params });
      // 后端返回 data.subscriptions，前端需要映射字段名
      const rawList = resp.data?.subscriptions ?? resp.data?.list ?? [];
      const mapped = rawList.map((s: any) => ({
        id: s.id,
        driver_id: s.driver_id,
        driver_name: s.driver?.real_name ?? s.driver_name ?? `司机 #${s.driver_id}`,
        driver_phone: s.driver?.user?.phone ?? s.driver_phone ?? '',
        plan_type: s.plan_type,
        plan: s.plan_type,
        plan_name: s.plan_name ?? '',
        price: s.monthly_fee ?? s.price ?? 0,
        monthly_fee: s.monthly_fee,
        status: s.status,
        start_date: s.start_date,
        end_date: s.expire_date ?? s.end_date,
        expire_date: s.expire_date,
        auto_renew: s.auto_renew ?? false,
        created_at: s.created_at,
        updated_at: s.updated_at,
      }));
      setSubscriptions(mapped);
      setTotal(resp.data?.total ?? 0);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSubscriptions();
  }, [page, statusFilter, planFilter]);

  const handleExport = () => {
    const params = new URLSearchParams();
    if (statusFilter !== undefined) params.set('status', String(statusFilter));
    if (planFilter !== undefined) params.set('plan', String(planFilter));
    if (searchText) params.set('keyword', searchText);
    if (dateRange) {
      params.set('start_date', dateRange[0].format('YYYY-MM-DD'));
      params.set('end_date', dateRange[1].format('YYYY-MM-DD'));
    }
    window.open(`/api/v1/admin/subscriptions/export?${params.toString()}`, '_blank');
  };

  const columns = [
    {
      title: '司机姓名',
      dataIndex: 'driver_name',
      key: 'driver_name',
      width: 120,
      render: (v: string, record: Subscription) => (
        <a onClick={() => navigate(`/subscription/${record.driver_id}`)}>{v}</a>
      ),
    },
    {
      title: '手机号',
      dataIndex: 'driver_phone',
      key: 'driver_phone',
      width: 130,
    },
    {
      title: '套餐',
      dataIndex: 'plan_name',
      key: 'plan_name',
      width: 100,
      render: (_v: string, record: Subscription) => {
        const planInfo = SUBSCRIPTION_PLAN_MAP[record.plan];
        const colorMap: Record<number, string> = { 0: 'default', 1: 'blue', 2: 'cyan', 3: 'gold' };
        return <Tag color={colorMap[record.plan] ?? 'default'}>{planInfo?.text ?? record.plan_name}</Tag>;
      },
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (s: number) => {
        const info = SUBSCRIPTION_STATUS_MAP[s];
        return info ? <Tag color={info.color}>{info.text}</Tag> : <Tag>{s}</Tag>;
      },
    },
    {
      title: '费用',
      dataIndex: 'price',
      key: 'price',
      width: 100,
      render: (v: number) => (v > 0 ? `¥${v.toFixed(2)}` : '免费'),
    },
    {
      title: '开始日期',
      dataIndex: 'start_date',
      key: 'start_date',
      width: 120,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD') : '-'),
    },
    {
      title: '到期日期',
      dataIndex: 'end_date',
      key: 'end_date',
      width: 120,
      render: (v: string) => {
        if (!v) return '-';
        const isExpired = dayjs(v).isBefore(dayjs());
        return (
          <span style={isExpired ? { color: '#EF4444' } : undefined}>
            {dayjs(v).format('YYYY-MM-DD')}
          </span>
        );
      },
    },
    {
      title: '自动续费',
      dataIndex: 'auto_renew',
      key: 'auto_renew',
      width: 90,
      render: (v: boolean) =>
        v ? <Tag color="green">开启</Tag> : <Tag color="default">关闭</Tag>,
    },
    {
      title: '订阅时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '操作',
      key: 'actions',
      width: 80,
      render: (_: unknown, record: Subscription) => (
        <a onClick={() => navigate(`/subscription/${record.driver_id}`)}>详情</a>
      ),
    },
  ];

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
          <Space wrap>
            <Input
              placeholder="搜索司机姓名/手机号"
              prefix={<SearchOutlined />}
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              onPressEnter={() => { setPage(1); fetchSubscriptions(); }}
              style={{ width: 220 }}
              allowClear
            />
            <Select
              placeholder="订阅状态"
              allowClear
              style={{ width: 130 }}
              value={statusFilter}
              onChange={(v) => { setStatusFilter(v); setPage(1); }}
              options={Object.entries(SUBSCRIPTION_STATUS_MAP).map(([k, v]) => ({
                value: Number(k),
                label: v.text,
              }))}
            />
            <Select
              placeholder="套餐类型"
              allowClear
              style={{ width: 130 }}
              value={planFilter}
              onChange={(v) => { setPlanFilter(v); setPage(1); }}
              options={Object.entries(SUBSCRIPTION_PLAN_MAP).map(([k, v]) => ({
                value: Number(k),
                label: v.text,
              }))}
            />
            <RangePicker
              value={dateRange}
              onChange={(dates) => {
                setDateRange(dates as [dayjs.Dayjs, dayjs.Dayjs] | null);
                setPage(1);
              }}
              style={{ width: 240 }}
            />
            <Button icon={<ReloadOutlined />} onClick={fetchSubscriptions}>
              刷新
            </Button>
          </Space>
          <Space>
            <Button icon={<DownloadOutlined />} onClick={handleExport}>
              导出
            </Button>
            <Button
              type="primary"
              icon={<FilterOutlined />}
              onClick={() => navigate('/subscription/dashboard')}
            >
              数据看板
            </Button>
          </Space>
        </div>

        <Table
          columns={columns}
          dataSource={subscriptions}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1200 }}
          locale={{
            emptyText: <EmptyState description="暂无订阅数据" />,
          }}
          pagination={{
            total,
            current: page,
            onChange: (p) => setPage(p),
            pageSize: 20,
            showTotal: (t) => `共 ${t} 条`,
            showSizeChanger: false,
          }}
        />
      </Card>
    </div>
  );
}
