import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Card,
  Descriptions,
  Tag,
  Spin,
  Tabs,
  Table,
  Button,
  Space,
  Modal,
  Form,
  Input,
  message,
  Empty,
  Typography,
} from 'antd';
import {
  ArrowLeftOutlined,
  TeamOutlined,
  FileTextOutlined,
  DollarOutlined,
  InfoCircleOutlined,
  PlusOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import api from '@/services/api';
import { colors } from '@/styles/theme';

const { Text } = Typography;

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

interface Employee {
  id: number;
  name: string;
  phone: string;
  email: string;
  role: string;
  status: number;
  created_at: string;
}

interface Order {
  id: number;
  order_no: string;
  employee_name: string;
  start_address: string;
  end_address: string;
  amount: number;
  status: number;
  created_at: string;
}

interface Bill {
  id: number;
  bill_no: string;
  period_start: string;
  period_end: string;
  total_amount: number;
  order_count: number;
  status: number;
  created_at: string;
}

const ORDER_STATUS_MAP: Record<number, { text: string; color: string }> = {
  1: { text: '待派单', color: 'default' },
  2: { text: '已派单', color: 'processing' },
  5: { text: '等待上车', color: 'purple' },
  6: { text: '行程中', color: 'orange' },
  7: { text: '已完成', color: 'green' },
  8: { text: '已取消', color: 'red' },
};

const BILL_STATUS_MAP: Record<number, { text: string; color: string }> = {
  1: { text: '待结算', color: 'warning' },
  2: { text: '已结算', color: 'success' },
  3: { text: '已开票', color: 'processing' },
};

export default function EnterpriseDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [enterprise, setEnterprise] = useState<Enterprise | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('basic');

  // Employees state
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [employeesLoading, setEmployeesLoading] = useState(false);
  const [employeeModalOpen, setEmployeeModalOpen] = useState(false);
  const [employeeForm] = Form.useForm();
  const [employeeSubmitting, setEmployeeSubmitting] = useState(false);

  // Orders state
  const [orders, setOrders] = useState<Order[]>([]);
  const [ordersLoading, setOrdersLoading] = useState(false);
  const [ordersPage, setOrdersPage] = useState(1);
  const [ordersTotal, setOrdersTotal] = useState(0);

  // Bills state
  const [bills, setBills] = useState<Bill[]>([]);
  const [billsLoading, setBillsLoading] = useState(false);
  const [billsPage, setBillsPage] = useState(1);
  const [billsTotal, setBillsTotal] = useState(0);

  useEffect(() => {
    if (id) fetchEnterprise(Number(id));
  }, [id]);

  const fetchEnterprise = async (enterpriseId: number) => {
    setLoading(true);
    try {
      const resp = await api.get(`/admin/enterprises/${enterpriseId}`);
      setEnterprise(resp.data ?? null);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  const fetchEmployees = async (enterpriseId: number) => {
    setEmployeesLoading(true);
    try {
      const resp = await api.get(`/admin/enterprises/${enterpriseId}/employees`, {
        params: { offset: 0, limit: 100 },
      });
      setEmployees(resp.data?.list ?? []);
    } catch {
      // error handled by interceptor
    } finally {
      setEmployeesLoading(false);
    }
  };

  const fetchOrders = async (enterpriseId: number, p: number) => {
    setOrdersLoading(true);
    try {
      const resp = await api.get(`/admin/enterprises/${enterpriseId}/orders`, {
        params: { offset: (p - 1) * 20, limit: 20 },
      });
      setOrders(resp.data?.list ?? []);
      setOrdersTotal(resp.data?.total ?? 0);
    } catch {
      // error handled by interceptor
    } finally {
      setOrdersLoading(false);
    }
  };

  const fetchBills = async (enterpriseId: number, p: number) => {
    setBillsLoading(true);
    try {
      const resp = await api.get(`/admin/enterprises/${enterpriseId}/bill`, {
        params: { offset: (p - 1) * 20, limit: 20 },
      });
      setBills(resp.data?.list ?? []);
      setBillsTotal(resp.data?.total ?? 0);
    } catch {
      // error handled by interceptor
    } finally {
      setBillsLoading(false);
    }
  };

  const handleTabChange = (key: string) => {
    setActiveTab(key);
    if (!id) return;
    const eid = Number(id);
    if (key === 'employees' && employees.length === 0) {
      fetchEmployees(eid);
    } else if (key === 'orders') {
      fetchOrders(eid, ordersPage);
    } else if (key === 'bills') {
      fetchBills(eid, billsPage);
    }
  };

  const handleAddEmployee = async () => {
    try {
      const values = await employeeForm.validateFields();
      setEmployeeSubmitting(true);
      await api.post(`/admin/enterprises/${id}/employees`, values);
      message.success('员工添加成功');
      setEmployeeModalOpen(false);
      employeeForm.resetFields();
      if (id) fetchEmployees(Number(id));
    } catch {
      // validation or api error
    } finally {
      setEmployeeSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!enterprise) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <p style={{ color: '#999' }}>未找到该企业信息</p>
        <a onClick={() => navigate('/enterprise')}>返回企业列表</a>
      </div>
    );
  }

  const statusInfo = CONTRACT_STATUS_MAP[enterprise.contract_status];
  const industryText = INDUSTRY_MAP[enterprise.industry] || '未知';

  const employeeColumns = [
    { title: '姓名', dataIndex: 'name', key: 'name', width: 120 },
    { title: '手机号', dataIndex: 'phone', key: 'phone', width: 140 },
    { title: '邮箱', dataIndex: 'email', key: 'email', width: 180, render: (v: string) => v || '-' },
    { title: '角色', dataIndex: 'role', key: 'role', width: 110 },
    {
      title: '状态', dataIndex: 'status', key: 'status', width: 80,
      render: (s: number) => (
        <Tag color={s === 1 ? 'green' : 'red'}>{s === 1 ? '启用' : '禁用'}</Tag>
      ),
    },
    {
      title: '创建时间', dataIndex: 'created_at', key: 'created_at', width: 160,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD HH:mm') : '-'),
    },
  ];

  const orderColumns = [
    { title: '订单号', dataIndex: 'order_no', key: 'order_no', width: 160 },
    { title: '员工', dataIndex: 'employee_name', key: 'employee_name', width: 110 },
    { title: '出发地', dataIndex: 'start_address', key: 'start_address', ellipsis: true },
    { title: '目的地', dataIndex: 'end_address', key: 'end_address', ellipsis: true },
    {
      title: '金额', dataIndex: 'amount', key: 'amount', width: 100,
      render: (v: number) => (v ? `¥${v.toFixed(2)}` : '-'),
    },
    {
      title: '状态', dataIndex: 'status', key: 'status', width: 100,
      render: (s: number) => {
        const info = ORDER_STATUS_MAP[s];
        return info ? <Tag color={info.color}>{info.text}</Tag> : <Tag>{s}</Tag>;
      },
    },
    {
      title: '时间', dataIndex: 'created_at', key: 'created_at', width: 160,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD HH:mm') : '-'),
    },
  ];

  const billColumns = [
    { title: '账单号', dataIndex: 'bill_no', key: 'bill_no', width: 160 },
    {
      title: '账期', key: 'period', width: 200,
      render: (_: unknown, record: Bill) => (
        <span>
          {record.period_start ? dayjs(record.period_start).format('YYYY-MM-DD') : '-'}
          {' ~ '}
          {record.period_end ? dayjs(record.period_end).format('YYYY-MM-DD') : '-'}
        </span>
      ),
    },
    {
      title: '订单数', dataIndex: 'order_count', key: 'order_count', width: 80,
    },
    {
      title: '总金额', dataIndex: 'total_amount', key: 'total_amount', width: 120,
      render: (v: number) => `¥${(v ?? 0).toFixed(2)}`,
    },
    {
      title: '状态', dataIndex: 'status', key: 'status', width: 100,
      render: (s: number) => {
        const info = BILL_STATUS_MAP[s];
        return info ? <Tag color={info.color}>{info.text}</Tag> : <Tag>{s}</Tag>;
      },
    },
    {
      title: '创建时间', dataIndex: 'created_at', key: 'created_at', width: 160,
      render: (v: string) => (v ? dayjs(v).format('YYYY-MM-DD HH:mm') : '-'),
    },
  ];

  const tabItems = [
    {
      key: 'basic',
      label: <span><InfoCircleOutlined /> 基本信息</span>,
      children: (
        <div>
          <Descriptions column={2} size="small" bordered style={{ marginTop: 16 }}>
            <Descriptions.Item label="企业名称" span={2}>{enterprise.name}</Descriptions.Item>
            <Descriptions.Item label="联系人">{enterprise.contact_person}</Descriptions.Item>
            <Descriptions.Item label="联系电话">{enterprise.contact_phone}</Descriptions.Item>
            <Descriptions.Item label="邮箱">{enterprise.contact_email || '-'}</Descriptions.Item>
            <Descriptions.Item label="行业">
              <Tag>{industryText}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="合同状态">
              <Tag color={statusInfo?.color}>{statusInfo?.text}</Tag>
            </Descriptions.Item>
            <Descriptions.Item label="员工数量">{enterprise.employee_count ?? 0}</Descriptions.Item>
            <Descriptions.Item label="创建时间">
              {enterprise.created_at ? dayjs(enterprise.created_at).format('YYYY-MM-DD HH:mm') : '-'}
            </Descriptions.Item>
            <Descriptions.Item label="更新时间">
              {enterprise.updated_at ? dayjs(enterprise.updated_at).format('YYYY-MM-DD HH:mm') : '-'}
            </Descriptions.Item>
          </Descriptions>
        </div>
      ),
    },
    {
      key: 'employees',
      label: <span><TeamOutlined /> 关联员工</span>,
      children: (
        <div>
          <div style={{ textAlign: 'right', marginBottom: 12 }}>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={() => setEmployeeModalOpen(true)}
            >
              添加员工
            </Button>
          </div>
          <Table
            columns={employeeColumns}
            dataSource={employees}
            rowKey="id"
            loading={employeesLoading}
            scroll={{ x: 800 }}
            locale={{ emptyText: <Empty description="暂无关联网员工" /> }}
            pagination={false}
          />
        </div>
      ),
    },
    {
      key: 'orders',
      label: <span><FileTextOutlined /> 订单历史</span>,
      children: (
        <Table
          columns={orderColumns}
          dataSource={orders}
          rowKey="id"
          loading={ordersLoading}
          scroll={{ x: 1000 }}
          locale={{ emptyText: <Empty description="暂无订单记录" /> }}
          pagination={{
            total: ordersTotal,
            current: ordersPage,
            onChange: (p) => {
              setOrdersPage(p);
              if (id) fetchOrders(Number(id), p);
            },
            pageSize: 20,
            showTotal: (t) => `共 ${t} 条`,
            showSizeChanger: false,
          }}
        />
      ),
    },
    {
      key: 'bills',
      label: <span><DollarOutlined /> 结算记录</span>,
      children: (
        <Table
          columns={billColumns}
          dataSource={bills}
          rowKey="id"
          loading={billsLoading}
          scroll={{ x: 900 }}
          locale={{ emptyText: <Empty description="暂无结算记录" /> }}
          pagination={{
            total: billsTotal,
            current: billsPage,
            onChange: (p) => {
              setBillsPage(p);
              if (id) fetchBills(Number(id), p);
            },
            pageSize: 20,
            showTotal: (t) => `共 ${t} 条`,
            showSizeChanger: false,
          }}
        />
      ),
    },
  ];

  return (
    <div>
      <Card
        title={
          <span>
            <ArrowLeftOutlined
              style={{ marginRight: 8, cursor: 'pointer' }}
              onClick={() => navigate('/enterprise')}
            />
            企业详情 - {enterprise.name}
          </span>
        }
      >
        <Tabs
          activeKey={activeTab}
          onChange={handleTabChange}
          items={tabItems}
        />
      </Card>

      {/* 添加员工弹窗 */}
      <Modal
        title="添加员工"
        open={employeeModalOpen}
        onOk={handleAddEmployee}
        onCancel={() => {
          setEmployeeModalOpen(false);
          employeeForm.resetFields();
        }}
        confirmLoading={employeeSubmitting}
        destroyOnClose
      >
        <Form
          form={employeeForm}
          layout="vertical"
          style={{ marginTop: 16 }}
        >
          <Form.Item
            name="name"
            label="姓名"
            rules={[{ required: true, message: '请输入员工姓名' }]}
          >
            <Input placeholder="输入员工姓名" />
          </Form.Item>
          <Form.Item
            name="phone"
            label="手机号"
            rules={[{ required: true, message: '请输入手机号' }]}
          >
            <Input placeholder="输入手机号" />
          </Form.Item>
          <Form.Item
            name="email"
            label="邮箱"
          >
            <Input placeholder="输入邮箱地址" type="email" />
          </Form.Item>
          <Form.Item
            name="role"
            label="角色"
          >
            <Input placeholder="输入角色名称（如：普通员工）" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
