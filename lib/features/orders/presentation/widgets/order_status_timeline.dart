import 'package:flutter/material.dart';
import '../../domain/entities/order_entity.dart';

/// Visual vertical timeline showing all FSM states for an order.
///
/// Design:
/// - Completed steps: neon green (#00FF88) filled circle + label
/// - Current step: primary blue (#1A73E8) filled circle + label (pulsing)
/// - Pending steps: grey (#666666) outlined circle + label
///
/// When the current status is a terminal state (cancelled / refunded), the
/// "happy path" steps that were never reached are hidden — only completed
/// steps and the active terminal node are shown.
class OrderStatusTimeline extends StatefulWidget {
  final OrderStatus currentStatus;

  const OrderStatusTimeline({super.key, required this.currentStatus});

  @override
  State<OrderStatusTimeline> createState() => _OrderStatusTimelineState();
}

class _OrderStatusTimelineState extends State<OrderStatusTimeline>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<OrderStatus> _visibleStatuses() {
    final current = widget.currentStatus;
    final currentIdx = current.stepIndex;

    if (current.isFinal) {
      // Show only steps that were completed + the terminal node.
      // "Happy path" pending steps (after terminal divergence) are omitted.
      return OrderStatus.values
          .where((s) => s.stepIndex <= currentIdx)
          .toList();
    }

    // Show all 11 steps for non-terminal active orders.
    return OrderStatus.values;
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _visibleStatuses();
    final currentIdx = widget.currentStatus.stepIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(statuses.length, (i) {
        final status = statuses[i];
        final idx = status.stepIndex;
        final isDone = idx < currentIdx;
        final isCurrent = idx == currentIdx;
        final isPending = idx > currentIdx;
        final isLast = i == statuses.length - 1;

        return _TimelineRow(
          status: status,
          isDone: isDone,
          isCurrent: isCurrent,
          isPending: isPending,
          isLast: isLast,
          pulseAnimation: _pulseAnimation,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final OrderStatus status;
  final bool isDone;
  final bool isCurrent;
  final bool isPending;
  final bool isLast;
  final Animation<double> pulseAnimation;

  const _TimelineRow({
    required this.status,
    required this.isDone,
    required this.isCurrent,
    required this.isPending,
    required this.isLast,
    required this.pulseAnimation,
  });

  static const _neonGreen = Color(0xFF00FF88);
  static const _primaryBlue = Color(0xFF1A73E8);
  static const _pendingGrey = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isDone
        ? _neonGreen
        : isCurrent
            ? _primaryBlue
            : _pendingGrey;

    final Widget dot = isCurrent
        ? AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) => Opacity(
              opacity: pulseAnimation.value,
              child: child,
            ),
            child: _buildDot(dotColor, filled: true),
          )
        : _buildDot(dotColor, filled: !isPending);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connector line column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                dot,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? _neonGreen : _pendingGrey,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isDone
                      ? _neonGreen
                      : isCurrent
                          ? Colors.white
                          : _pendingGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color, {required bool filled}) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: filled && !isCurrent
          ? Center(
              child: Icon(
                Icons.check,
                size: 10,
                color: Colors.black,
              ),
            )
          : null,
    );
  }
}
