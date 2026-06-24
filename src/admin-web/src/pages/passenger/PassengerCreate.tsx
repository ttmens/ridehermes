import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, Form, Input, Button, message } from 'antd';
import api from '@/services/api';

export default function PassengerCreate() {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const onFinish = async (values: { phone: string; password: string; nickname: string }) => {
    setLoading(true);
    try {
      await api.post('/admin/users/passenger', values);
      message.success('乘客创建成功');
      navigate('/passenger');
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <Card
        title="创建乘客"
        extra={<a onClick={() => navigate('/passenger')}>返回列表</a>}
      >
        <Form
          form={form}
          onFinish={onFinish}
          layout="vertical"
          style={{ maxWidth: 500 }}
        >
          <Form.Item
            name="phone"
            label="手机号"
            rules={[
              { required: true, message: '请输入手机号' },
              { pattern: /^1\d{10}$/, message: '请输入正确的手机号' },
            ]}
          >
            <Input placeholder="11位手机号" maxLength={11} />
          </Form.Item>

          <Form.Item
            name="password"
            label="密码"
            rules={[
              { required: true, message: '请输入密码' },
              { min: 6, message: '密码至少6位' },
            ]}
          >
            <Input.Password placeholder="至少6位" />
          </Form.Item>

          <Form.Item name="nickname" label="昵称">
            <Input placeholder="乘客昵称（可选）" />
          </Form.Item>

          <Form.Item>
            <Button onClick={() => navigate('/passenger')}>取消</Button>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginLeft: 16 }}>
              提交
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
