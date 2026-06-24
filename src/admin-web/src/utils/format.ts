export function maskPhone(phone: string): string {
  if (phone.length === 11) {
    return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2');
  }
  return phone;
}

export function formatPrice(price: number): string {
  return `¥${price.toFixed(2)}`;
}

export function formatDistance(meters: number): string {
  if (meters < 1000) return `${meters}m`;
  return `${(meters / 1000).toFixed(1)}km`;
}

export function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}秒`;
  if (seconds < 3600) return `${Math.round(seconds / 60)}分钟`;
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.round((seconds % 3600) / 60);
  return `${hours}小时${minutes}分钟`;
}
