import { useState, useEffect } from 'react';
import { Card, Table, Tag, Button, Space, message } from 'antd';
import { ReloadOutlined, BellOutlined } from '@ant-design/icons';
import api from '@/services/api';
import dayjs from 'dayjs';

interface Notification {
  id: number;
  driver_id: number;
  type: string;
  channel: string;
  title: string;
  content: string;
  status: number;
  sent_at: string | null;
  fail_reason: string | null;
  created_at: string;
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);

  const fetchNotifications = async () => {
    setLoading(true);
    try {
      const resp = await api.get('/admin/notifications', {
        params: { offset: (page - 1) * pageSize, limit: pageSize },
      });
      setNotifications(resp.data?.list || []);
      setTotal(resp.data?.total || 0);
    } catch (error: any) {
      message.error(error.message || '加载通知列表失败');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, [page, pageSize]);

  const getStatusTag = (status: number) => {
    switch (status) {
      case 1:
        return <Tag color="orange">待发送</Tag>;
      case 2:
        return <Tag color="green">已发送</Tag>;
      case 3:
        return <Tag color="red">发送失败</Tag>;
      default:
        return <Tag>未知</Tag>;
    }
  };

  const getTypeTag = (type: string) => {
    switch (type) {
      case 'info':
        return <Tag color="blue">信息</Tag>;
      case 'warning':
        return <Tag color="orange">警告</Tag>;
      case 'urgent':
        return <Tag color="red">紧急</Tag>;
      default:
        return <Tag>{type}</Tag>;
    }
  };

  const getChannelTag = (channel: string) => {
    switch (channel) {
      case 'sms':
        return <Tag color="purple">短信</Tag>;
      case 'app_push':
        return <Tag color="cyan">APP推送</Tag>;
      case 'in_app':
        return <Tag color="geekblue">应用内</Tag>;
      default:
        return <Tag>{channel}</Tag>;
    }
  };

  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 80,
    },
    {
      title: '司机ID',
      dataIndex: 'driver_id',
      key: 'driver_id',
      width: 100,
    },
    {
      title: '类型',
      dataIndex: 'type',
      key: 'type',
      width: 100,
      render: (type: string) => getTypeTag(type),
    },
    {
      title: '渠道',
      dataIndex: 'channel',
      key: 'channel',
      width: 120,
      render: (channel: string) => getChannelTag(channel),
    },
    {
      title: '标题',
      dataIndex: 'title',
      key: 'title',
      width: 200,
      ellipsis: true,
    },
    {
      title: '内容',
      dataIndex: 'content',
      key: 'content',
      ellipsis: true,
    },
    {
      title: '状态',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (status: number) => getStatusTag(status),
    },
    {
      title: '发送时间',
      dataIndex: 'sent_at',
      key: 'sent_at',
      width: 180,
      render: (sentAt: string | null) =>
        sentAt ? dayjs(sentAt).format('YYYY-MM-DD HH:mm:ss') : '-',
    },
    {
      title: '失败原因',
      dataIndex: 'fail_reason',
      key: 'fail_reason',
      width: 200,
      ellipsis: true,
      render: (reason: string | null) => reason || '-',
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 180,
      render: (createdAt: string) => dayjs(createdAt).format('YYYY-MM-DD HH:mm:ss'),
    },
  ];

  return (
    <div style={{ padding: 24 }}>
      <Card
        title={
          <Space>
            <BellOutlined />
            <span>推送通知管理</span>
          </Space>
        }
        extra={
          <Button icon={<ReloadOutlined />} onClick={fetchNotifications}>
            刷新
          </Button>
        }
      >
        <Table
          columns={columns}
          dataSource={notifications}
          rowKey="id"
          loading={loading}
          pagination={{
            current: page,
            pageSize: pageSize,
            total: total,
            showSizeChanger: true,
            showTotal: (total) => `共 ${total} 条`,
            onChange: (page, pageSize) => {
              setPage(page);
              setPageSize(pageSize);
            },
          }}
          scroll={{ x: 1400 }}
        />
      </Card>
    </div>
  );
}
