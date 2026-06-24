class Formatters {
  static String formatPrice(double price) {
    return '¥${price.toStringAsFixed(2)}';
  }

  static String formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }

  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    return '$minutes分钟';
  }

  static String formatPhone(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone;
  }
}
