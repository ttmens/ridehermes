import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Card, Descriptions, Tag, Button, Input, Select, Form, Row, Col, Spin, message, Popconfirm, Breadcrumb } from 'antd';
import api from '@/services/api';
import { DRIVER_STATUS_MAP, CAR_TYPE_MAP } from '@/utils/constants';

/** 敏感信息脱敏：保留前3后4，中间用 * 替代 */
function maskSensitive(text: string | undefined | null): string {
  if (!text) return '-';
  if (text.length <= 7) return text.slice(0, 3) + '***';
  return text.slice(0, 3) + '****' + text.slice(-4);
}

export default function DriverDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [driver, setDriver] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    if (id) fetchDriver(Number(id));
  }, [id]);

  async function fetchDriver(driverId: number) {
    setLoading(true);
    try {
      const resp = await api.get(`/admin/drivers/${driverId}`);
      setDriver(resp.data);
    } catch {
      // error handled by interceptor
    } finally {
      setLoading(false);
    }
  }

  function startEdit() {
    const v = driver?.vehicle;
    form.setFieldsValue({
      real_name: driver?.real_name,
      id_card_no: driver?.id_card_no,
      license_no: driver?.license_no,
      status: driver?.status,
      plate_number: v?.plate_number,
      brand: v?.brand,
      model: v?.model,
      color: v?.color,
      car_type: v?.car_type ?? 1,
    });
    setEditing(true);
  }

  async function handleSave() {
    try {
      const values = await form.validateFields();
      setSaving(true);
      await api.put(`/admin/drivers/${id}`, values);
      message.success('保存成功');
      setEditing(false);
      fetchDriver(Number(id));
    } catch {
      // validation error or API error handled by interceptor
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!driver) {
    return (
      <div style={{ textAlign: 'center', padding: 80 }}>
        <p style={{ color: '#999' }}>司机不存在</p>
        <a onClick={() => navigate('/driver')}>返回司机列表</a>
      </div>
    );
  }

  const statusInfo = DRIVER_STATUS_MAP[driver.status];
  const vehicle = driver.vehicle;

  return (
    <div>
      <Breadcrumb items={[
        { title: <a onClick={() => navigate('/driver')}>司机管理</a> },
        { title: `司机 #${driver.id}` },
      ]} style={{ marginBottom: 16 }} />

      <Card
        title={`司机详情 #${driver.id}`}
        extra={
          editing ? (
            <>
              <Button onClick={() => setEditing(false)} style={{ marginRight: 8 }}>取消</Button>
              <Button type="primary" loading={saving} onClick={handleSave}>保存</Button>
            </>
          ) : (
            <>
              <Button onClick={startEdit} style={{ marginRight: 8 }}>编辑</Button>
              <a onClick={() => navigate('/driver')}>返回列表</a>
            </>
          )
        }
      >
        {/* User Info */}
        <Card type="inner" title="用户信息" size="small" style={{ marginBottom: 16 }}>
          <Descriptions column={2} size="small">
            <Descriptions.Item label="手机号">{driver.user?.phone ?? '-'}</Descriptions.Item>
            <Descriptions.Item label="昵称">{driver.user?.nickname ?? '-'}</Descriptions.Item>
          </Descriptions>
        </Card>

        {/* Driver Info + Vehicle Info 合并为一个 Form */}
        <Form form={form} layout="vertical" component={false}>
          {/* Driver Info */}
          <Card type="inner" title="司机信息" size="small" style={{ marginBottom: 16 }}>
            {editing ? (
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="姓名" name="real_name" rules={[{ required: true, message: '请输入姓名' }]}>
                    <Input />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="状态" name="status" rules={[{ required: true }]}>
                    <Select
                      options={[
                        { value: 1, label: '待审核' },
                        { value: 2, label: '正常' },
                        { value: 3, label: '禁用' },
                      ]}
                    />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="身份证号" name="id_card_no" rules={[
                    { required: true, message: '请输入身份证号' },
                    { pattern: /^\d{17}[\dXx]$/, message: '身份证号格式不正确' },
                  ]}>
                    <Input maxLength={18} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="驾驶证号" name="license_no" rules={[{ required: true, message: '请输入驾驶证号' }]}>
                    <Input maxLength={18} />
                  </Form.Item>
                </Col>
              </Row>
            ) : (
              <Descriptions column={2} size="small">
                <Descriptions.Item label="姓名">{driver.real_name}</Descriptions.Item>
                <Descriptions.Item label="状态">
                  <Tag color={statusInfo?.color}>{statusInfo?.text ?? driver.status}</Tag>
                </Descriptions.Item>
                <Descriptions.Item label="身份证号">{maskSensitive(driver.id_card_no)}</Descriptions.Item>
                <Descriptions.Item label="驾驶证号">{maskSensitive(driver.license_no)}</Descriptions.Item>
                <Descriptions.Item label="评分">{driver.rating?.toFixed(1) ?? '-'}</Descriptions.Item>
                <Descriptions.Item label="余额">¥{driver.balance ?? '0.00'}</Descriptions.Item>
              </Descriptions>
            )}
          </Card>

          {/* Vehicle Info */}
          <Card type="inner" title="车辆信息" size="small">
            {editing ? (
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="车牌号" name="plate_number" rules={[
                    { required: true, message: '请输入车牌号' },
                    { pattern: /^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-Z][A-Z0-9]{5}$/, message: '车牌号格式不正确' },
                  ]}>
                    <Input maxLength={8} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="车型" name="car_type" rules={[{ required: true }]}>
                    <Select
                      options={[
                        { value: 1, label: '快车' },
                        { value: 2, label: '专车' },
                        { value: 3, label: '豪华车' },
                      ]}
                    />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item label="品牌" name="brand" rules={[{ required: true, message: '请输入品牌' }]}>
                    <Input />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item label="型号" name="model" rules={[{ required: true, message: '请输入型号' }]}>
                    <Input />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item label="颜色" name="color" rules={[{ required: true, message: '请输入颜色' }]}>
                    <Input />
                  </Form.Item>
                </Col>
              </Row>
            ) : vehicle ? (
              <Descriptions column={3} size="small">
                <Descriptions.Item label="车牌号">{vehicle.plate_number}</Descriptions.Item>
                <Descriptions.Item label="车型">{CAR_TYPE_MAP[vehicle.car_type] ?? vehicle.car_type}</Descriptions.Item>
                <Descriptions.Item label="品牌">{vehicle.brand}</Descriptions.Item>
                <Descriptions.Item label="型号">{vehicle.model}</Descriptions.Item>
                <Descriptions.Item label="颜色">{vehicle.color}</Descriptions.Item>
              </Descriptions>
            ) : (
              <span style={{ color: '#999' }}>无车辆信息</span>
            )}
          </Card>
        </Form>
      </Card>
    </div>
  );
}
