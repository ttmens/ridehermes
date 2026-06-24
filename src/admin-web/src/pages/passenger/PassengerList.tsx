import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Table, Button, Tag, Popconfirm, message, Space, Input, Select, Card } from 'antd';
import { PlusOutlined, SearchOutlined, ReloadOutlined } from '@ant-design/icons';
import api from '@/services/api';
import { USER_STATUS_MAP } from '@/utils/constants';

export default function PassengerList() {
  const navigate = useNavigate();
  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [searchPhone, setSearchPhone] = useState('');
  const [statusFilter, setStatusFilter] = useState<number | undefined>();

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = {
        role: 2,
        offset: (page - 1) * 20,
        limit: 20,
      };
      if (statusFilter !== undefined) params.status = statusFilter;
      if (searchPhone) params.phone = searchPhone;

      const resp = await api.get('/admin/users', { params });
      setUsers(resp.data?.list ?? []);
      setTotal(resp.data?.total ?? 0);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [page, statusFilter, searchPhone]);

  const handleToggleStatus = async (record: { id: number; status: number }) => {
    const newStatus = record.status === 1 ? 2 : 1;
    await api.put(`/admin/users/${record.id}/status`, { status: newStatus });
    message.success(newStatus === 1 ? '已启用' : '已禁用');
    fetchUsers();
  };

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '手机号', dataIndex: 'phone', key: 'phone', width: 140 },
    { title: '昵称', dataIndex: 'nickname', key: 'nickname', width: 120 },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (s: number) => {
        const info = USER_STATUS_MAP[s];
        return <Tag color={info?.color}>{info?.text ?? s}</Tag>;
      },
    },
    {
      title: '注册时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 180,
    },
    {
      title: '操作',
      key: 'actions',
      width: 100,
      render: (_: unknown, record: { id: number; status: number }) => (
        <Popconfirm
          title={record.status === 1 ? '确定禁用该乘客？' : '确定启用该乘客？'}
          onConfirm={() => handleToggleStatus(record)}
        >
          <a style={{ color: record.status === 1 ? '#FF4D4F' : '#52C41A' }}>
            {record.status === 1 ? '禁用' : '启用'}
          </a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
          <Space>
            <Input
              placeholder="搜索手机号"
              prefix={<SearchOutlined />}
              value={searchPhone}
              onChange={(e) => setSearchPhone(e.target.value)}
              onPressEnter={() => { setPage(1); fetchUsers(); }}
              style={{ width: 180 }}
              allowClear
            />
            <Select
              placeholder="状态筛选"
              allowClear
              style={{ width: 120 }}
              value={statusFilter}
              onChange={(v) => { setStatusFilter(v); setPage(1); }}
              options={[
                { value: 1, label: '正常' },
                { value: 2, label: '禁用' },
              ]}
            />
            <Button icon={<ReloadOutlined />} onClick={fetchUsers}>刷新</Button>
          </Space>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate('/passenger/create')}>
            创建乘客
          </Button>
        </div>

        <Table
          columns={columns}
          dataSource={users}
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
