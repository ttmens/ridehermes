import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { Layout, Menu, Avatar, Dropdown, theme, Breadcrumb } from 'antd';
import {
  DashboardOutlined,
  UserOutlined,
  CarOutlined,
  FileTextOutlined,
  EnvironmentOutlined,
  LogoutOutlined,
  PlusOutlined,
  KeyOutlined,
  HomeOutlined,
  CrownOutlined,
  BankOutlined,
  SafetyCertificateOutlined,
  BellOutlined,
} from '@ant-design/icons';
import { useAuthStore } from '@/stores/authStore';

const { Header, Sider, Content } = Layout;

const menuItems = [
  { key: '/dashboard', icon: <DashboardOutlined />, label: '工作台' },
  {
    key: '/passenger',
    icon: <UserOutlined />,
    label: '乘客管理',
    children: [
      { key: '/passenger', label: '乘客列表' },
      { key: '/passenger/create', icon: <PlusOutlined />, label: '创建乘客' },
    ],
  },
  {
    key: '/driver',
    icon: <CarOutlined />,
    label: '司机管理',
    children: [
      { key: '/driver', label: '司机列表' },
      { key: '/driver/create', icon: <PlusOutlined />, label: '创建司机' },
    ],
  },
  { key: '/order', icon: <FileTextOutlined />, label: '订单管理' },
  { key: '/subscription', icon: <CrownOutlined />, label: '订阅管理' },
  { key: '/enterprise', icon: <BankOutlined />, label: '企业客户' },
  { key: '/trust-scores', icon: <SafetyCertificateOutlined />, label: '信誉看板' },
  { key: '/notifications', icon: <BellOutlined />, label: '推送通知' },
  { key: '/monitor', icon: <EnvironmentOutlined />, label: '实时监控' },
  { key: '/agents', icon: <KeyOutlined />, label: '智能体管理' },
];

/** 路由 → 面包屑映射 */
const breadcrumbMap: Record<string, string> = {
  '/dashboard': '工作台',
  '/passenger': '乘客管理',
  '/passenger/create': '创建乘客',
  '/driver': '司机管理',
  '/driver/create': '创建司机',
  '/order': '订单管理',
  '/subscription': '订阅管理',
  '/subscription/dashboard': '订阅看板',
  '/enterprise': '企业客户管理',
  '/trust-scores': '信誉看板',
  '/notifications': '推送通知',
  '/monitor': '实时监控',
  '/agents': '智能体管理',
};

function getBreadcrumbItems(pathname: string) {
  const segments = pathname.split('/').filter(Boolean);
  const items: { title: React.ReactNode }[] = [{ title: <a onClick={() => window.location.hash === ''}><HomeOutlined /> 首页</a> }];

  let currentPath = '';
  for (const seg of segments) {
    currentPath += `/${seg}`;
    const label = breadcrumbMap[currentPath];
    if (label) {
      const path = currentPath;
      items.push({ title: <a onClick={() => window.history.pushState(null, '', path)}>{label}</a> });
    } else if (/^\/order\/\d+$/.test(currentPath)) {
      items.push({ title: '订单详情' });
    } else if (/^\/driver\/\d+$/.test(currentPath)) {
      // already handled by DriverDetail
    } else if (/^\/subscription\/\d+$/.test(currentPath)) {
      items.push({ title: '订阅详情' });
    } else if (/^\/enterprise\/\d+$/.test(currentPath)) {
      items.push({ title: '企业详情' });
    }
  }

  return items.length > 1 ? items : [];
}

export default function MainLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuthStore();
  const { token: themeToken } = theme.useToken();

  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key);
  };

  const allMenuKeys = menuItems.flatMap(item =>
    'children' in item && item.children
      ? [item.key, ...item.children.map((c: { key: string }) => c.key)]
      : [item.key]
  );

  const selectedKey = allMenuKeys
    .filter(key => location.pathname === key || location.pathname.startsWith(key + '/'))
    .sort((a, b) => b.length - a.length)[0] ?? location.pathname;

  const openKeys = ['/passenger', '/driver'];

  const userMenu = {
    items: [
      { key: 'logout', icon: <LogoutOutlined />, label: '退出登录', onClick: () => logout() },
    ],
  };

  const breadcrumbItems = getBreadcrumbItems(location.pathname);

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider
        collapsible
        collapsed={collapsed}
        onCollapse={setCollapsed}
        theme="light"
        style={{ borderRight: '1px solid #f0f0f0' }}
      >
        <div style={{
          height: 64,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          borderBottom: '1px solid #f0f0f0',
          cursor: 'pointer',
        }} onClick={() => navigate('/dashboard')}>
          <h1 style={{
            margin: 0,
            fontSize: collapsed ? 16 : 18,
            fontWeight: 700,
            color: themeToken.colorPrimary,
          }}>
            {collapsed ? 'RH' : 'RideHermes'}
          </h1>
        </div>
        <Menu
          mode="inline"
          selectedKeys={[selectedKey]}
          defaultOpenKeys={openKeys}
          items={menuItems}
          onClick={handleMenuClick}
          style={{ borderRight: 0 }}
        />
      </Sider>

      <Layout>
        <Header style={{
          padding: '0 24px',
          background: themeToken.colorBgContainer,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          borderBottom: '1px solid #f0f0f0',
        }}>
          {breadcrumbItems.length > 0 ? (
            <Breadcrumb items={breadcrumbItems} />
          ) : (
            <span />
          )}
          <Dropdown menu={userMenu}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
              <Avatar icon={<UserOutlined />} style={{ backgroundColor: themeToken.colorPrimary }} />
              <span>{user?.nickname || '管理员'}</span>
            </div>
          </Dropdown>
        </Header>

        <Content style={{ margin: 24, padding: 24, background: themeToken.colorBgContainer, borderRadius: 8, minHeight: 280 }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  );
}
