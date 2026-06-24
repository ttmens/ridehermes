import 'package:flutter/material.dart';

class OrderStatus {
  static const int pending = 1;
  static const int assigned = 2;
  static const int accepted = 3;
  static const int waitingPickup = 5;
  static const int inTrip = 6;
  static const int completed = 7;
  static const int cancelled = 8;

  static String text(int status) {
    return switch (status) {
      pending => '待派单',
      assigned => '已派单',
      accepted => '已接单',
      waitingPickup => '已到达',
      inTrip => '行程中',
      completed => '已完成',
      cancelled => '已取消',
      _ => '未知',
    };
  }

  static Color color(int status) {
    return switch (status) {
      pending => const Color(0xFFF59E0B),
      assigned => const Color(0xFF3B82F6),
      accepted || waitingPickup => const Color(0xFF0D9488),
      inTrip => const Color(0xFF22C55E),
      completed => const Color(0xFF6B7280),
      cancelled => const Color(0xFFEF4444),
      _ => const Color(0xFF6B7280),
    };
  }

  static bool canCancel(int status) =>
      status == pending || status == assigned || status == accepted;
}
