import 'package:flutter/material.dart';

class QuickCommand {
  final IconData icon;
  final String label;
  final String text;

  const QuickCommand({
    required this.icon,
    required this.label,
    required this.text,
  });
}

class QuickCommands extends StatelessWidget {
  final Function(String) onTap;

  const QuickCommands({super.key, required this.onTap});

  static const commands = [
    QuickCommand(icon: Icons.home, label: '回家', text: '我要回家'),
    QuickCommand(icon: Icons.business, label: '公司', text: '我要去公司'),
    QuickCommand(icon: Icons.airplanemode_active, label: '机场', text: '我要去机场'),
    QuickCommand(icon: Icons.train, label: '火车站', text: '我要去火车站'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: commands.map((cmd) {
          return GestureDetector(
            onTap: () => onTap(cmd.text),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(cmd.icon, color: Theme.of(context).colorScheme.primary, size: 30),
                ),
                const SizedBox(height: 8),
                Text(cmd.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
