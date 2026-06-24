import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Table, Select, Space, Input, Button, Card } from 'antd';
import { SearchOutlined, ReloadOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { ORDER_STATUS_MAP } from '@/utils/constants';
import StatusTag from '@/components/StatusTag';
import EmptyState from '@/components/EmptyState';

export default function OrderList() {
  const navigate = useNavigate();
  const [orders, setOrders] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<number | undefined>();
  const [orderNoSearch, setOrderNoSearch] = useState('');

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { offset: (page - 1) * 20, limit: 20 };
      if (statusFilter !== undefined) params.status = statusFilter;
      if (orderNoSearch) params.order_no = orderNoSearch;

      const resp = await api.get('/admin/orders', { params });
      setOrders(resp.data?.list ?? []);
      setTotal(resp.data?.total ?? 0);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [page, statusFilter]);

  const columns: any = [
    {
      title: '订单号', dataIndex: 'order_no', key: 'order_no', width: 190,
      render: (v: string, record: any) => (
        <a onClick={() => navigate(`/order/${record.id}`)}>{v}</a>
      ),
    },
    {
      title: '乘客', key: 'passenger', width: 100,
      render: (_: any, r: any) => r.passenger?.nickname ?? '-',
    },
    {
      title: '司机', key: 'driver', width: 100,
      render: (_: any, r: any) =>
        r.status >= 2 && r.driver?.real_name
          ? r.driver.real_name
          : <span style={{ color: '#999' }}>待分配</span>,
    },
    { title: '起点', dataIndex: 'pickup_addr', key: 'pickup_addr', width: 160, ellipsis: true },
    { title: '终点', dataIndex: 'dropoff_addr', key: 'dropoff_addr', width: 160, ellipsis: true },
    {
      title: '预估费用', dataIndex: 'est_price', key: 'est_price', width: 100,
      render: (p: number) => `¥${p}`,
    },
    {
      title: '状态', dataIndex: 'status', key: 'status', width: 110,
      render: (s: number) => <StatusTag status={s} type="order" />,
    },
    {
      title: '创建时间', dataIndex: 'created_at', key: 'created_at', width: 170,
      render: (v: string) => v ? dayjs(v).format('MM-DD HH:mm') : '-',
    },
    { title: '预约时间', dataIndex: 'departure_time', key: 'departure_time', width: 170 },
    {
      title: '操作', key: 'actions', width: 80,
      render: (_: any, record: any) => (
        <a onClick={() => navigate(`/order/${record.id}`)}>详情</a>
      ),
    },
  ];

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
          <Space>
            <Input
              placeholder="搜索订单号"
              prefix={<SearchOutlined />}
              value={orderNoSearch}
              onChange={(e) => setOrderNoSearch(e.target.value)}
              onPressEnter={() => { setPage(1); fetchOrders(); }}
              style={{ width: 200 }}
              allowClear
            />
            <Select
              placeholder="筛选状态"
              allowClear
              style={{ width: 140 }}
              value={statusFilter}
              onChange={(v) => { setStatusFilter(v); setPage(1); }}
              options={Object.entries(ORDER_STATUS_MAP)
                .filter(([k]) => Number(k) !== 4)
                .map(([k, v]) => ({
                  value: Number(k),
                  label: v.text,
                }))}
            />
            <Button icon={<ReloadOutlined />} onClick={fetchOrders}>刷新</Button>
          </Space>
        </div>

        <Table
          columns={columns}
          dataSource={orders}
          rowKey="id"
          loading={loading}
          locale={{
            emptyText: <EmptyState description="暂无订单数据" />,
          }}
          pagination={{
            total,
            current: page,
            onChange: (p) => setPage(p),
            pageSize: 20,
            showTotal: (t) => `共 ${t} 条`,
          }}
        />
      </Card>
    </div>
  );
}
