import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Form, Input, Button, Card, message, Checkbox } from 'antd';
import { MobileOutlined, LockOutlined } from '@ant-design/icons';
import api from '@/services/api';
import { useAuthStore } from '@/stores/authStore';

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);

  const onFinish = async (values: { phone: string; password: string; remember: boolean }) => {
    setLoading(true);
    try {
      const resp = await api.post('/auth/login', {
        phone: values.phone,
        password: values.password,
      });
      const { access_token, user } = resp.data;
      if (user.role !== 1) {
        message.error('该账号无管理员权限');
        return;
      }
      setAuth(access_token, user);
      message.success('登录成功');
      navigate('/dashboard', { replace: true });
    } catch {
      message.error('登录失败，请检查手机号和密码');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #0D9488 0%, #2563EB 100%)',
    }}>
      <Card style={{ width: 420, boxShadow: '0 8px 24px rgba(0,0,0,0.15)' }} styles={{ body: { padding: '40px 40px 24px' } }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <h1 style={{ fontSize: 28, fontWeight: 700, color: '#0D9488', margin: 0 }}>RideHermes</h1>
          <p style={{ color: '#666', marginTop: 8, fontSize: 14 }}>赫耳墨斯出行 · 运营管理平台</p>
        </div>

        <Form
          onFinish={onFinish}
          size="large"
          initialValues={{ remember: true }}
        >
          <Form.Item
            name="phone"
            rules={[
              { required: true, message: '请输入手机号' },
              { pattern: /^1\d{10}$/, message: '请输入正确的手机号' },
            ]}
          >
            <Input prefix={<MobileOutlined />} placeholder="手机号" maxLength={11} />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[
              { required: true, message: '请输入密码' },
              { min: 6, message: '密码至少6位' },
            ]}
          >
            <Input.Password prefix={<LockOutlined />} placeholder="密码" />
          </Form.Item>

          <Form.Item name="remember" valuePropName="checked">
            <Checkbox>记住登录</Checkbox>
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading} block>
              登 录
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
