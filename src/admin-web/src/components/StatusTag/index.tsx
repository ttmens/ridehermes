import { Tag } from 'antd';
import { ORDER_STATUS_MAP, DRIVER_STATUS_MAP, USER_STATUS_MAP } from '@/utils/constants';

interface StatusTagProps {
  status: number;
  type?: 'order' | 'driver' | 'user';
}

const STATUS_MAPS = {
  order: ORDER_STATUS_MAP,
  driver: DRIVER_STATUS_MAP,
  user: USER_STATUS_MAP,
} as const;

export default function StatusTag({ status, type = 'order' }: StatusTagProps) {
  const map = STATUS_MAPS[type];
  const info = map[status];

  if (!info) {
    return <Tag>{status}</Tag>;
  }

  return <Tag color={info.color}>{info.text}</Tag>;
}
