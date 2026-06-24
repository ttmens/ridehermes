import type { ThemeConfig } from 'antd';

// 与 Flutter 端 AppColors 保持对齐
export const colors = {
  primary: '#0D9488',
  primaryLight: '#5EEAD4',
  primaryDark: '#0F766E',
  success: '#22C55E',
  warning: '#F59E0B',
  error: '#EF4444',
  info: '#3B82F6',
  textPrimary: '#1F2937',
  textSecondary: '#6B7280',
  textHint: '#9CA3AF',
  divider: '#E5E7EB',
  background: '#F9FAFB',
  surface: '#FFFFFF',
};

export const themeConfig: ThemeConfig = {
  token: {
    colorPrimary: colors.primary,
    colorSuccess: colors.success,
    colorWarning: colors.warning,
    colorError: colors.error,
    colorInfo: colors.info,
    colorBgContainer: colors.surface,
    colorBgLayout: colors.background,
    colorBorderSecondary: colors.divider,
    colorText: colors.textPrimary,
    colorTextSecondary: colors.textSecondary,
    colorTextTertiary: colors.textHint,
    borderRadius: 8,
    fontSize: 14,
  },
  components: {
    Layout: {
      headerBg: colors.surface,
      siderBg: colors.surface,
    },
    Menu: {
      itemSelectedBg: '#E6FFFB',
      itemSelectedColor: colors.primary,
    },
    Card: {
      borderRadiusLG: 12,
    },
    Table: {
      borderRadius: 12,
    },
  },
};
