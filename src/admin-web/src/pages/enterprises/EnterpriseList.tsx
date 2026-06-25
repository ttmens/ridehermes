import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Table, Select, Space, Input, Button, Card, Tag, Modal, Form, message } from 'antd';
import {
  SearchOutlined,
  ReloadOutlined,
  PlusOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { colors } from '@/styles/theme';

const { Option } = Select;

/** 合同状态映射 */
const CONTRACT_STATUS_MAP: Record<number, { text: string; color: string }> = {
  1: { text: '待签约', color: 'warning' },
  2: { text: '已签约', color: 'success' },
  3: { text: '续约中', color: 'processing' },
  4: { text: '已到期', color: 'default' },
  5: { text: '已终止', color: 'error' },
};

/** 行业类型映射 */
const INDUSTRY_MAP: Record<number, string> = {
  1: '出行服务',
  2: '物流运输',
  3: '旅游服务',
  4: '餐饮服务',
  5: '其他',
};

interface Enterprise {
  id: number;
  name: string;
  contact_person: string;
  contact_phone: string;
  contact_email: string;
  industry: number;
  contract_status: number;
  employee_count: number;
  created_at: string;
  updated_at: string;
}

export default function EnterpriseList() {
  const navigate = useNavigate();
  const [enterprises, setEnterprises] = useState<Enterprise[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<number | undefined>();
  const [industryFilter, setIndustryFilter] = useState<number | undefined>();
  const [searchText, setSearchText] = useState('');
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  const [createForm] = Form.useForm();

  const fetchEnterprises = async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = {
        offset: (page - 1) * 20,
        limit: 20,
      };
      if (statusFilter !== undefined) params.contract_status = statusFilter;
      if (industryFilter !== undefined) params.industry = industryFilter;
      if (searchText) params.keyword = searchText;

      const resp = await api.get('/admin/enterprises', { params });
      setEnterprises(resp.data?.list ?? []);
      setTotal(resp.data?.total ?? 0);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEnterprises();
  }, [page, statusFilter, industryFilter]);

  const handleCreate = async () => {
    try {
      const values = await createForm.validateFields();
      setCreateLoading(true);
      await api.post('/admin/enterprises', values);
      message.success('企业创建成功');
      setCreateModalOpen(false);
      createForm.resetFields();
      setPage(1);
      fetchEnterprises();
    } catch {
      // validation or api error
    } finally {
      setCreateLoading(false);
    }
  };

  const columns = [
    {
      title: '企业名称',
      dataIndex: 'name',
      key: 'name',
      width: 180,
      render: (v: string, record: Enterprise) => (
        <a onClick={() => navigate(`/enterprise/${record.id}`)}>{v}</a>
      ),
    },
    {
      title: '联系人',
      dataIndex: 'contact_person',
      key: 'contact_person',
      width: 120,
    },
    {
      title: '联系电话',
      dataIndex: 'contact_phone',
      key: 'contact_phone',
      width: 140,
    },
    {
      title: '邮箱',
      dataIndex: 'contact_email',
      key: 'contact_email',
      width: 180,
      render: (v: string) => v || '-',
    },
    {
      title: '行业',
      dataIndex: 'industry',
      key: 'industry',
      width: 110,
      render: (v: number) => {
        const text = INDUSTRY_MAP[v];
        return text ? <Tag>{text}</Tag> : <Tag>未知</Tag>;
      },
    },
    {
      title: '合同状态',
      dataIndex: 'contract_status',
      key: 'contract_status',
      width: 110,
      render: (s: number) => {
        const info = CONTRACT_STATUS_MAP[s];
        return info ? <Tag color={info.color}>{info.text}</Tag> : <Tag>{s}</Tag>;
      },
    },
    {
      title: '员工数',
      dataIndex: 'employee_count',
      key: 'employee_count',
      width: 80,
      render: (v: number) => v ?? 0,
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 160,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '操作',
      key: 'actions',
      width: 80,
      render: (_: unknown, record: Enterprise) => (
        <a onClick={() => navigate(`/enterprise/${record.id}`)}>详情</a>
      ),
    },
  ];

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
          <Space wrap>
            <Input
              placeholder="搜索企业名称/联系人"
              prefix={<SearchOutlined />}
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              onPressEnter={() => { setPage(1); fetchEnterprises(); }}
              style={{ width: 220 }}
              allowClear
            />
            <Select
              placeholder="合同状态"
              allowClear
              style={{ width: 130 }}
              value={statusFilter}
              onChange={(v) => { setStatusFilter(v); setPage(1); }}
            >
              {Object.entries(CONTRACT_STATUS_MAP).map(([k, v]) => (
                <Option key={k} value={Number(k)}>{v.text}</Option>
              ))}
            </Select>
            <Select
              placeholder="行业类型"
              allowClear
              style={{ width: 130 }}
              value={industryFilter}
              onChange={(v) => { setIndustryFilter(v); setPage(1); }}
            >
              {Object.entries(INDUSTRY_MAP).map(([k, v]) => (
                <Option key={k} value={Number(k)}>{v}</Option>
              ))}
            </Select>
            <Button icon={<ReloadOutlined />} onClick={fetchEnterprises}>
              刷新
            </Button>
          </Space>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => setCreateModalOpen(true)}
          >
            新增企业
          </Button>
        </div>

        <Table
          columns={columns}
          dataSource={enterprises}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1200 }}
          locale={{
            emptyText: (
              <div style={{ textAlign: 'center', padding: 40, color: colors.textHint }}>
                <TeamOutlined style={{ fontSize: 48, marginBottom: 8 }} />
                <p>暂无企业客户数据</p>
              </div>
            ),
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

      {/* 新增企业弹窗 */}
      <Modal
        title="新增企业客户"
        open={createModalOpen}
        onOk={handleCreate}
        onCancel={() => {
          setCreateModalOpen(false);
          createForm.resetFields();
        }}
        confirmLoading={createLoading}
        destroyOnClose
      >
        <Form
          form={createForm}
          layout="vertical"
          style={{ marginTop: 16 }}
        >
          <Form.Item
            name="name"
            label="企业名称"
            rules={[{ required: true, message: '请输入企业名称' }]}
          >
            <Input placeholder="输入企业名称" />
          </Form.Item>
          <Form.Item
            name="contact_person"
            label="联系人"
            rules={[{ required: true, message: '请输入联系人' }]}
          >
            <Input placeholder="输入联系人姓名" />
          </Form.Item>
          <Form.Item
            name="contact_phone"
            label="联系电话"
            rules={[{ required: true, message: '请输入联系电话' }]}
          >
            <Input placeholder="输入联系电话" />
          </Form.Item>
          <Form.Item
            name="contact_email"
            label="邮箱"
          >
            <Input placeholder="输入邮箱地址" type="email" />
          </Form.Item>
          <Form.Item
            name="industry"
            label="行业类型"
            rules={[{ required: true, message: '请选择行业类型' }]}
          >
            <Select placeholder="选择行业类型">
              {Object.entries(INDUSTRY_MAP).map(([k, v]) => (
                <Option key={k} value={Number(k)}>{v}</Option>
              ))}
            </Select>
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
