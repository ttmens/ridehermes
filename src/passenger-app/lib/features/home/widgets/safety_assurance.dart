import 'package:flutter/material.dart';

class _SafetyItem {
  final IconData icon;
  final String label;
  const _SafetyItem(this.icon, this.label);
}

class SafetyAssurance extends StatelessWidget {
  const SafetyAssurance({super.key});

  static const _items = [
    _SafetyItem(Icons.share_location, '行程分享'),
    _SafetyItem(Icons.shield, '一键报警'),
    _SafetyItem(Icons.verified_user, '司机认证'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: _items.map((it) {
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(it.icon, size: 26, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 6),
                  Text(
                    it.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
