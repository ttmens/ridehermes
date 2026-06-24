import { useState, useEffect } from 'react';
import { Card, Table, Button, Tag, message, Space, Modal, Form, Input, Select, Popconfirm, Tabs } from 'antd';
import { PlusOutlined, ReloadOutlined, KeyOutlined, HistoryOutlined } from '@ant-design/icons';
import api from '@/services/api';

interface AgentCredential {
  id: number;
  user_id: number;
  agent_name: string;
  prefix: string;
  permissions: string[];
  rate_limit: number;
  status: number;
  last_used_at: string;
  created_at: string;
}

interface AgentCallLog {
  id: number;
  credential_id: number;
  user_id: number;
  agent_name: string;
  endpoint: string;
  response_code: number;
  order_id: number | null;
  ip_address: string;
  latency_ms: number;
  created_at: string;
}

export default function AgentManagement() {
  const [credentials, setCredentials] = useState<AgentCredential[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [resultOpen, setResultOpen] = useState(false);
  const [newKey, setNewKey] = useState({ api_key: '', user_id: 0, agent_name: '' });
  const [form] = Form.useForm();
  const [activeTab, setActiveTab] = useState('keys');

  // Call log state
  const [logs, setLogs] = useState<AgentCallLog[]>([]);
  const [logsLoading, setLogsLoading] = useState(false);
  const [logFilters, setLogFilters] = useState({ user_id: '' });
  const [logsTotal, setLogsTotal] = useState(0);

  const fetchCredentials = async () => {
    setLoading(true);
    try {
      const resp = await api.get('/admin/agents/credentials');
      setCredentials(resp.data?.list ?? []);
    } catch {
      // handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  const fetchLogs = async () => {
    if (!logFilters.user_id) return;
    setLogsLoading(true);
    try {
      const resp = await api.get('/admin/agents/logs', { params: logFilters });
      setLogs(resp.data?.list ?? []);
      setLogsTotal(resp.data?.total ?? 0);
    } catch {
      // handled by interceptor
    } finally {
      setLogsLoading(false);
    }
  };

  useEffect(() => {
    fetchCredentials();
  }, []);

  const handleGenerate = async (values: { user_id: number; agent_name: string }) => {
    try {
      const resp = await api.post('/admin/agents/credentials', values);
      setNewKey({
        api_key: resp.data.api_key,
        user_id: resp.data.user_id,
        agent_name: resp.data.agent_name,
      });
      setModalOpen(false);
      setResultOpen(true);
      form.resetFields();
      fetchCredentials();
    } catch {
      // handled by interceptor
    }
  };

  const handleRevoke = async (id: number) => {
    try {
      await api.put(`/admin/agents/credentials/${id}/revoke`);
      message.success('API Key 已吊销');
      fetchCredentials();
    } catch {
      // handled by interceptor
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text).then(() => message.success('已复制'));
  };

  const credColumns = [
    { title: 'ID', dataIndex: 'id', width: 60 },
    { title: '用户ID', dataIndex: 'user_id', width: 80 },
    {
      title: '智能体',
      dataIndex: 'agent_name',
      width: 120,
      render: (v: string) => <Tag color="blue">{v}</Tag>,
    },
    {
      title: '状态',
      dataIndex: 'status',
      width: 80,
      render: (s: number) =>
        s === 1 ? <Tag color="green">正常</Tag> : <Tag color="red">已吊销</Tag>,
    },
    {
      title: '权限',
      dataIndex: 'permissions',
      width: 280,
      render: (perms: string[]) =>
        perms?.map((p) => <Tag key={p} style={{ marginBottom: 4 }}>{p}</Tag>),
    },
    { title: '频率限制', dataIndex: 'rate_limit', width: 80, render: (v: number) => `${v}/min` },
    { title: '最后使用', dataIndex: 'last_used_at', width: 160 },
    { title: '创建时间', dataIndex: 'created_at', width: 160 },
    {
      title: '操作',
      key: 'actions',
      width: 80,
      render: (_: unknown, record: AgentCredential) =>
        record.status === 1 ? (
          <Popconfirm title="确定吊销该 API Key？吊销后立即生效。" onConfirm={() => handleRevoke(record.id)}>
            <a style={{ color: '#FF4D4F' }}>吊销</a>
          </Popconfirm>
        ) : (
          <span style={{ color: '#999' }}>已吊销</span>
        ),
    },
  ];

  const logColumns = [
    { title: 'ID', dataIndex: 'id', width: 60 },
    { title: '凭证ID', dataIndex: 'credential_id', width: 80 },
    { title: '用户ID', dataIndex: 'user_id', width: 80 },
    { title: '智能体', dataIndex: 'agent_name', width: 100, render: (v: string) => <Tag color="blue">{v}</Tag> },
    { title: '端点', dataIndex: 'endpoint', width: 220 },
    {
      title: '状态码',
      dataIndex: 'response_code',
      width: 80,
      render: (c: number) => <Tag color={c === 200 ? 'green' : 'red'}>{c}</Tag>,
    },
    { title: '订单ID', dataIndex: 'order_id', width: 80, render: (v: number | null) => v ?? '-' },
    { title: '耗时', dataIndex: 'latency_ms', width: 80, render: (v: number) => `${v}ms` },
    { title: 'IP', dataIndex: 'ip_address', width: 130 },
    { title: '时间', dataIndex: 'created_at', width: 160 },
  ];

  const keyTab = (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <span style={{ fontSize: 16, fontWeight: 500 }}>
          <KeyOutlined style={{ marginRight: 8 }} />
          智能体 API Key 管理
        </span>
        <Space>
          <Button icon={<ReloadOutlined />} onClick={fetchCredentials}>刷新</Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setModalOpen(true)}>
            生成 API Key
          </Button>
        </Space>
      </div>
      <Table
        columns={credColumns}
        dataSource={credentials}
        rowKey="id"
        loading={loading}
        pagination={{ pageSize: 20, showTotal: (t: number) => `共 ${t} 条` }}
      />
    </div>
  );

  const logTab = (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <span style={{ fontSize: 16, fontWeight: 500 }}>
          <HistoryOutlined style={{ marginRight: 8 }} />
          调用日志
        </span>
        <Space>
          <Input
            placeholder="输入用户ID"
            value={logFilters.user_id}
            onChange={(e) => setLogFilters({ user_id: e.target.value })}
            style={{ width: 150 }}
          />
          <Button type="primary" onClick={fetchLogs}>查询</Button>
        </Space>
      </div>
      <Table
        columns={logColumns}
        dataSource={logs}
        rowKey="id"
        loading={logsLoading}
        pagination={{ pageSize: 20, showTotal: (t: number) => `共 ${t} 条` }}
      />
    </div>
  );

  return (
    <div>
      <Card>
        <Tabs
          activeKey={activeTab}
          onChange={setActiveTab}
          items={[
            { key: 'keys', label: 'API Keys', children: keyTab },
            { key: 'logs', label: '调用日志', children: logTab },
          ]}
        />
      </Card>

      <Modal
        title="生成 API Key"
        open={modalOpen}
        onCancel={() => { setModalOpen(false); form.resetFields(); }}
        onOk={() => form.submit()}
        okText="生成"
      >
        <Form form={form} layout="vertical" onFinish={handleGenerate}>
          <Form.Item
            name="user_id"
            label="乘客用户 ID"
            rules={[{ required: true, message: '请输入乘客用户 ID' }]}
          >
            <Input type="number" placeholder="例如: 2" />
          </Form.Item>
          <Form.Item
            name="agent_name"
            label="智能体标识"
            rules={[{ required: true, message: '请输入智能体标识' }]}
          >
            <Select
              placeholder="选择智能体"
              options={[
                { value: 'openclaw', label: 'openclaw' },
                { value: 'hermes', label: 'hermes' },
                { value: 'openhuman', label: 'openhuman' },
                { value: 'claude-desktop', label: 'Claude Desktop' },
                { value: 'other', label: '其他' },
              ]}
            />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="⚠️ 请妥善保管 API Key"
        open={resultOpen}
        onCancel={() => setResultOpen(false)}
        footer={[
          <Button key="close" type="primary" onClick={() => setResultOpen(false)}>
            我已知晓
          </Button>,
        ]}
      >
        <p style={{ color: '#D97706', marginBottom: 16 }}>
          此 API Key 仅展示一次，关闭后无法再次查看。请立即复制并妥善保管。
        </p>
        <div style={{ marginBottom: 12 }}>
          <strong>智能体：</strong>
          <Tag color="blue">{newKey.agent_name}</Tag>
        </div>
        <div style={{ marginBottom: 12 }}>
          <strong>User ID：</strong>
          <code style={{ fontSize: 16, background: '#f5f5f5', padding: '2px 8px', borderRadius: 4 }}>
            {newKey.user_id}
          </code>
          <Button type="link" size="small" onClick={() => copyToClipboard(String(newKey.user_id))}>
            复制
          </Button>
        </div>
        <div style={{ marginBottom: 12 }}>
          <strong>API Key：</strong>
          <div style={{
            background: '#f0f5ff',
            border: '1px solid #91caff',
            borderRadius: 6,
            padding: '8px 12px',
            marginTop: 4,
            wordBreak: 'break-all',
            fontFamily: 'monospace',
            fontSize: 13,
          }}>
            {newKey.api_key}
          </div>
          <Button type="link" size="small" style={{ marginTop: 4 }}
            onClick={() => copyToClipboard(newKey.api_key)}>
            复制
          </Button>
        </div>
        <div>
          <strong>安装命令：</strong>
          <pre style={{
            background: '#1a1a2e',
            color: '#00ff88',
            padding: '8px 12px',
            borderRadius: 6,
            marginTop: 4,
            fontSize: 12,
          }}>
            npx ridehermes-mcp-server setup
          </pre>
          <Button type="link" size="small"
            onClick={() => copyToClipboard('npx @ridehermes/mcp-server setup')}>
            复制
          </Button>
        </div>
      </Modal>
    </div>
  );
}
