import React from 'react';
import { Button } from 'antd';
import { InboxOutlined } from '@ant-design/icons';
import { colors } from '@/styles/theme';

interface EmptyStateProps {
  icon?: React.ReactNode;
  description: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export default function EmptyState({ icon, description, action }: EmptyStateProps) {
  const displayIcon = icon ?? <InboxOutlined />;

  return (
    <div style={{ padding: '48px 0', textAlign: 'center' }}>
      <div style={{ fontSize: 48, color: colors.textHint, marginBottom: 12 }}>
        {displayIcon}
      </div>
      <div style={{ color: colors.textSecondary, marginBottom: action ? 16 : 0 }}>
        {description}
      </div>
      {action && (
        <Button type="primary" onClick={action.onClick}>
          {action.label}
        </Button>
      )}
    </div>
  );
}
