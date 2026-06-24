import { useEffect, useState, useRef, useCallback } from 'react';
import { Card, Table, Tag, Space, Button, Badge, Tooltip, message } from 'antd';
import { ReloadOutlined, AimOutlined } from '@ant-design/icons';
import api from '@/services/api';
import { CAR_TYPE_MAP } from '@/utils/constants';
import type { DriverLocation } from '@/types/location';

const REFRESH_INTERVAL = 10000;
const BEIJING_CENTER: [number, number] = [116.397428, 39.90923];
const CAR_COLORS: Record<number, string> = { 1: '#1890FF', 2: '#F5222D', 3: '#FAAD14' };

function createCarIcon(carType: number): string {
  const color = CAR_COLORS[carType] ?? '#1890FF';
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
    <circle cx="16" cy="16" r="14" fill="${color}" opacity="0.3"/>
    <circle cx="16" cy="16" r="8" fill="${color}" stroke="#fff" stroke-width="2"/>
    <text x="16" y="20" text-anchor="middle" fill="#fff" font-size="10" font-weight="bold">🚗</text>
  </svg>`;
  return `data:image/svg+xml;base64,${btoa(unescape(encodeURIComponent(svg)))}`;
}

function createDriverContent(driver: DriverLocation): string {
  return `<div style="min-width:180px;font-size:13px;line-height:1.8">
    <strong>${driver.real_name || '未知'}</strong>
    <br/>📱 ${driver.phone || '-'}
    <br/>🚙 ${driver.plate_number || '-'} · ${CAR_TYPE_MAP[driver.car_type] ?? '快车'}
    <br/>📍 ${Number(driver.latitude).toFixed(5)}, ${Number(driver.longitude).toFixed(5)}
    <br/>🚀 ${Number(driver.speed).toFixed(0)} km/h · 🎯 ${Number(driver.accuracy).toFixed(0)}m
  </div>`;
}

export default function MonitorPage() {
  const [drivers, setDrivers] = useState<DriverLocation[]>([]);
  const [loading, setLoading] = useState(false);
  const [mapReady, setMapReady] = useState(false);
  const mapRef = useRef<AMap.Map | null>(null);
  const markersRef = useRef<AMap.Marker[]>([]);
  const containerRef = useRef<HTMLDivElement>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const initTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const mapId = useRef(`map-${Date.now()}`).current;

  const clearMarkers = useCallback(() => {
    const map = mapRef.current;
    markersRef.current.forEach((m) => {
      if (map) m.setMap(null);
    });
    markersRef.current = [];
  }, []);

  const fitToMarkers = useCallback(() => {
    if (!mapRef.current) return;
    if (markersRef.current.length > 0) {
      mapRef.current.setFitView(markersRef.current, false, [60, 60, 60, 60]);
    } else {
      mapRef.current.setCenter(BEIJING_CENTER);
      mapRef.current.setZoom(12);
    }
  }, []);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/locations/drivers').catch(() => ({ data: [] }));
      const list: DriverLocation[] = res.data ?? [];
      setDrivers(list);

      const map = mapRef.current;
      if (!map) return;

      clearMarkers();

      list.forEach((d) => {
        const lat = Number(d.latitude);
        const lng = Number(d.longitude);
        if (!lat || !lng) return;

        const marker = new AMap.Marker({
          position: [lng, lat],
          icon: createCarIcon(d.car_type),
          title: d.real_name || '司机',
          offset: new AMap.Pixel(-16, -16),
          zIndex: 100,
        });

        const infoWindow = new AMap.InfoWindow({
          content: createDriverContent(d),
          offset: new AMap.Pixel(0, -36),
        });

        marker.on('click', () => {
          infoWindow.open(map, marker.getPosition());
        });

        marker.setMap(map);
        marker.setExtData(d);
        markersRef.current.push(marker);
      });

      fitToMarkers();
    } catch {
      // handled by interceptor
    } finally {
      setLoading(false);
    }
  }, [clearMarkers, fitToMarkers]);

  // Init map — retry if AMap SDK not ready yet
  useEffect(() => {
    if (mapRef.current) return;

    function tryInit(attempt: number) {
      if (mapRef.current) return;

      if (typeof AMap !== 'undefined' && AMap.Map) {
        try {
          const map = new AMap.Map(mapId, {
            zoom: 12,
            center: BEIJING_CENTER,
            viewMode: '2D',
            resizeEnable: true,
          });
          mapRef.current = map;
          setMapReady(true);
          fetchData();
          timerRef.current = setInterval(fetchData, REFRESH_INTERVAL);
          message.success('地图加载成功');
          return;
        } catch (err) {
          console.error('地图初始化失败:', err);
        }
      }

      if (attempt < 60) {
        initTimerRef.current = setTimeout(() => tryInit(attempt + 1), 300);
      } else {
        message.error('地图SDK加载失败，请检查网络连接并刷新页面');
      }
    }

    initTimerRef.current = setTimeout(() => tryInit(0), 500);

    return () => {
      if (initTimerRef.current) clearTimeout(initTimerRef.current);
      if (timerRef.current) clearInterval(timerRef.current);
      if (mapRef.current) {
        clearMarkers();
        mapRef.current.destroy();
        mapRef.current = null;
      }
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleRefresh = () => {
    fetchData();
    message.success('已刷新');
  };

  return (
    <div>
      <Card
        title={
          <Space>
            <span>实时监控</span>
            <Tag color="blue">在线司机 {drivers.length}</Tag>
          </Space>
        }
        extra={
          <Space>
            <Badge status="processing" text={`自动刷新 ${REFRESH_INTERVAL / 1000}s`} />
            <Tooltip title="适应所有车辆">
              <Button icon={<AimOutlined />} onClick={fitToMarkers} disabled={!mapReady}>
                适应屏幕
              </Button>
            </Tooltip>
            <Button icon={<ReloadOutlined />} loading={loading} onClick={handleRefresh}>
              刷新
            </Button>
          </Space>
        }
      >
        <div
          id={mapId}
          ref={containerRef}
          style={{ width: '100%', height: 500, borderRadius: 8, marginBottom: 16, background: '#f5f5f5' }}
        />

        <Space>
          {Object.entries(CAR_COLORS).map(([type, color]) => (
            <Tag key={type} color={color}>
              🚗 {CAR_TYPE_MAP[Number(type)]}
            </Tag>
          ))}
          <Tag>📍 {drivers.length} 辆在线</Tag>
        </Space>
      </Card>

      <Card title="在线司机列表" size="small" style={{ marginTop: 16 }}>
        <Table
          dataSource={drivers}
          rowKey="driver_id"
          pagination={false}
          size="small"
          columns={[
            { title: '姓名', dataIndex: 'real_name', key: 'real_name', width: 100 },
            { title: '手机号', dataIndex: 'phone', key: 'phone', width: 130 },
            { title: '车牌号', dataIndex: 'plate_number', key: 'plate_number', width: 120 },
            {
              title: '车型',
              dataIndex: 'car_type',
              key: 'car_type',
              width: 80,
              render: (v: number) => <Tag color={CAR_COLORS[v]}>{CAR_TYPE_MAP[v] ?? v}</Tag>,
            },
            { title: '速度', dataIndex: 'speed', key: 'speed', width: 80, render: (v: number) => `${Number(v).toFixed(0)} km/h` },
            { title: '精度', dataIndex: 'accuracy', key: 'accuracy', width: 70, render: (v: number) => `${Number(v).toFixed(0)}m` },
            {
              title: '位置',
              key: 'pos',
              width: 200,
              render: (_: unknown, r: DriverLocation) =>
                `${Number(r.latitude).toFixed(5)}, ${Number(r.longitude).toFixed(5)}`,
            },
          ]}
          locale={{ emptyText: '暂无在线司机' }}
        />
      </Card>
    </div>
  );
}
