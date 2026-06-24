import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Table, Button, Tag, Select, Space, Card } from 'antd';
import { PlusOutlined, ReloadOutlined } from '@ant-design/icons';
import api from '@/services/api';
import { DRIVER_STATUS_MAP, CAR_TYPE_MAP } from '@/utils/constants';

export default function DriverList() {
  const navigate = useNavigate();
  const [drivers, setDrivers] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<number | undefined>();

  const fetchDrivers = async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { offset: (page - 1) * 20, limit: 20 };
      if (statusFilter !== undefined) params.status = statusFilter;

      const resp = await api.get('/admin/drivers', { params });
      setDrivers(resp.data?.list ?? []);
      setTotal(resp.data?.total ?? 0);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDrivers();
  }, [page, statusFilter]);

  const columns: any = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '姓名', dataIndex: 'real_name', key: 'real_name', width: 100 },
    {
      title: '手机号', key: 'phone', width: 140,
      render: (_: any, r: any) => r.user?.phone ?? '-',
    },
    {
      title: '车牌号', key: 'plate', width: 120,
      render: (_: any, r: any) => r.vehicle?.plate_number ?? '-',
    },
    {
      title: '车辆', key: 'car', width: 180,
      render: (_: any, r: any) => {
        const v = r.vehicle;
        if (!v) return '-';
        return `${v.color ?? ''} ${v.brand ?? ''} ${v.model ?? ''} (${CAR_TYPE_MAP[v.car_type ?? 1] ?? ''})`;
      },
    },
    { title: '评分', dataIndex: 'rating', key: 'rating', width: 80 },
    {
      title: '状态', dataIndex: 'status', key: 'status', width: 100,
      render: (s: number) => {
        const info = DRIVER_STATUS_MAP[s];
        return <Tag color={info?.color}>{info?.text ?? s}</Tag>;
      },
    },
    {
      title: '操作', key: 'actions', width: 100,
      render: (_: any, record: any) => (
        <a onClick={() => navigate(`/driver/${record.id}`)}>详情</a>
      ),
    },
  ];

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
          <Space>
            <Select
              placeholder="状态筛选"
              allowClear
              style={{ width: 120 }}
              value={statusFilter}
              onChange={(v) => { setStatusFilter(v); setPage(1); }}
              options={[
                { value: 1, label: '待审核' },
                { value: 2, label: '正常' },
                { value: 3, label: '禁用' },
              ]}
            />
            <Button icon={<ReloadOutlined />} onClick={fetchDrivers}>刷新</Button>
          </Space>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/driver/create')}>
            创建司机
          </Button>
        </div>

        <Table
          columns={columns}
          dataSource={drivers}
          rowKey="id"
          loading={loading}
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
