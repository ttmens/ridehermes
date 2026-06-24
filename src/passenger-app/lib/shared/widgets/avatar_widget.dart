import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double radius;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              initials ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
