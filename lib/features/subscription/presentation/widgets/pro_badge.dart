import 'package:flutter/material.dart';

/// Golden PRO badge widget
/// Shows a gradient gold badge with star icon and "PRO" text
class ProBadge extends StatelessWidget {
  final bool mini;

  const ProBadge({
    super.key,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mini ? 6 : 10,
        vertical: mini ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(mini ? 4 : 6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: mini ? 10 : 14,
            color: Colors.white,
          ),
          SizedBox(width: mini ? 2 : 4),
          Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: mini ? 8 : 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ProBadge positioned in top-right corner of a widget
class ProBadgeOverlay extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final bool mini;

  const ProBadgeOverlay({
    super.key,
    required this.child,
    this.showBadge = true,
    this.mini = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: ProBadge(mini: mini),
        ),
      ],
    );
  }
}
