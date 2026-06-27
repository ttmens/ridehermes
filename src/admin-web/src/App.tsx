import { lazy, Suspense } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { Spin } from 'antd';
import MainLayout from '@/layouts/MainLayout';

// 懒加载页面组件 - 代码分割
const LoginPage = lazy(() => import('@/pages/login/LoginPage'));
const DashboardPage = lazy(() => import('@/pages/DashboardPage'));
const PassengerList = lazy(() => import('@/pages/passenger/PassengerList'));
const PassengerCreate = lazy(() => import('@/pages/passenger/PassengerCreate'));
const DriverList = lazy(() => import('@/pages/drivers/DriverList'));
const DriverCreate = lazy(() => import('@/pages/drivers/DriverCreate'));
const DriverDetail = lazy(() => import('@/pages/drivers/DriverDetail'));
const OrderList = lazy(() => import('@/pages/orders/OrderList'));
const OrderDetail = lazy(() => import('@/pages/orders/OrderDetail'));
const MonitorPage = lazy(() => import('@/pages/map/MonitorPage'));
const MatchingMonitorPage = lazy(() => import('@/pages/match/MatchingMonitorPage'));
const AgentPage = lazy(() => import('@/pages/AgentManagement'));
const SubscriptionDashboard = lazy(() => import('@/pages/subscriptions/SubscriptionDashboard'));
const SubscriptionList = lazy(() => import('@/pages/subscriptions/SubscriptionList'));
const SubscriptionDetail = lazy(() => import('@/pages/subscriptions/SubscriptionDetail'));
const EnterpriseList = lazy(() => import('@/pages/enterprises/EnterpriseList'));
const EnterpriseDetail = lazy(() => import('@/pages/enterprises/EnterpriseDetail'));
const TrustScoresPage = lazy(() => import('@/pages/trust-scores/TrustScoresPage'));
const NotificationsPage = lazy(() => import('@/pages/notifications/NotificationsPage'));
const NotFoundPage = lazy(() => import('@/pages/NotFoundPage'));

// 加载占位符
function PageLoading() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%', minHeight: 200 }}>
      <Spin size="large" tip="加载中..." />
    </div>
  );
}

function AuthGuard({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.token);
  if (!token) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <Suspense fallback={<PageLoading />}>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={
            <AuthGuard>
              <MainLayout />
            </AuthGuard>
          }
        >
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="passenger" element={<PassengerList />} />
          <Route path="passenger/create" element={<PassengerCreate />} />
          <Route path="driver" element={<DriverList />} />
          <Route path="driver/create" element={<DriverCreate />} />
          <Route path="driver/:id" element={<DriverDetail />} />
          <Route path="order" element={<OrderList />} />
          <Route path="order/:id" element={<OrderDetail />} />
          <Route path="monitor" element={<MonitorPage />} />
          <Route path="matching" element={<MatchingMonitorPage />} />
          <Route path="agents" element={<AgentPage />} />
          <Route path="subscription" element={<SubscriptionList />} />
          <Route path="subscription/dashboard" element={<SubscriptionDashboard />} />
          <Route path="subscription/:id" element={<SubscriptionDetail />} />
          <Route path="trust-scores" element={<TrustScoresPage />} />
          <Route path="notifications" element={<NotificationsPage />} />
          <Route path="enterprise" element={<EnterpriseList />} />
          <Route path="enterprise/:id" element={<EnterpriseDetail />} />
          <Route path="*" element={<NotFoundPage />} />
        </Route>
      </Routes>
    </Suspense>
  );
}
