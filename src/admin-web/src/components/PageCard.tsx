import React from 'react';
import { Card, Spin } from 'antd';
import { colors } from '@/styles/theme';

interface PageCardProps {
  title?: string;
  extra?: React.ReactNode;
  loading?: boolean;
  children: React.ReactNode;
  style?: React.CSSProperties;
}

export default function PageCard({ title, extra, loading, children, style }: PageCardProps) {
  return (
    <Card
      title={title}
      extra={extra}
      style={{
        borderRadius: 12,
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        border: `1px solid ${colors.divider}`,
        ...style,
      }}
      styles={{
        body: { padding: 0 },
      }}
    >
      <Spin spinning={!!loading}>
        {children}
      </Spin>
    </Card>
  );
}
