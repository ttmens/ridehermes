import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, Form, Input, Button, Select, message, Divider } from 'antd';
import api from '@/services/api';
import { CAR_TYPE_MAP } from '@/utils/constants';

export default function DriverCreate() {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const onFinish = async (values: Record<string, unknown>) => {
    setLoading(true);
    try {
      await api.post('/admin/users/driver', values);
      message.success('司机创建成功');
      navigate('/driver');
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <Card
        title="创建司机"
        extra={<a onClick={() => navigate('/driver')}>返回列表</a>}
      >
        <Form
          form={form}
          onFinish={onFinish}
          layout="vertical"
          style={{ maxWidth: 640 }}
        >
          <Divider orientation="left" plain>基本信息</Divider>

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
            <Input placeholder="司机昵称（可选）" />
          </Form.Item>

          <Form.Item
            name="real_name"
            label="真实姓名"
            rules={[{ required: true, message: '请输入真实姓名' }]}
          >
            <Input placeholder="与身份证一致" />
          </Form.Item>

          <Form.Item
            name="id_card_no"
            label="身份证号"
            rules={[
              { required: true, message: '请输入身份证号' },
              { len: 18, message: '身份证号为18位' },
            ]}
          >
            <Input placeholder="18位身份证号" maxLength={18} />
          </Form.Item>

          <Form.Item
            name="license_no"
            label="驾驶证号"
            rules={[{ required: true, message: '请输入驾驶证号' }]}
          >
            <Input placeholder="驾驶证号" />
          </Form.Item>

          <Divider orientation="left" plain>车辆信息</Divider>

          <Form.Item
            name={['vehicle', 'plate_number']}
            label="车牌号"
            rules={[{ required: true, message: '请输入车牌号' }]}
          >
            <Input placeholder="如：京A12345" />
          </Form.Item>

          <div style={{ display: 'flex', gap: 16 }}>
            <Form.Item
              name={['vehicle', 'brand']}
              label="品牌"
              rules={[{ required: true, message: '请输入品牌' }]}
              style={{ flex: 1 }}
            >
              <Input placeholder="如：丰田" />
            </Form.Item>
            <Form.Item
              name={['vehicle', 'model']}
              label="型号"
              rules={[{ required: true, message: '请输入型号' }]}
              style={{ flex: 1 }}
            >
              <Input placeholder="如：卡罗拉" />
            </Form.Item>
          </div>

          <div style={{ display: 'flex', gap: 16 }}>
            <Form.Item
              name={['vehicle', 'color']}
              label="颜色"
              rules={[{ required: true, message: '请输入颜色' }]}
              style={{ flex: 1 }}
            >
              <Input placeholder="如：白色" />
            </Form.Item>
            <Form.Item
              name={['vehicle', 'car_type']}
              label="车型类别"
              rules={[{ required: true, message: '请选择车型类别' }]}
              style={{ flex: 1 }}
              initialValue={1}
            >
              <Select
                options={Object.entries(CAR_TYPE_MAP).map(([k, v]) => ({
                  value: Number(k),
                  label: v,
                }))}
              />
            </Form.Item>
          </div>

          <Form.Item>
            <Button onClick={() => navigate('/driver')}>取消</Button>
            <Button type="primary" htmlType="submit" loading={loading} style={{ marginLeft: 16 }}>
              提交
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
