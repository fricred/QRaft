import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/glass_button.dart';
import '../providers/operator_providers.dart';

/// Valid operator FSM transitions, matching the DB trigger constraints.
///
/// Keys are current status strings; values are allowed next status strings.
/// Only operator-initiated transitions are listed (payment transitions are
/// handled by the Wompi webhook / apply_payment_event RPC).
const Map<String, List<String>> kValidTransitions = {
  'paid': ['received_by_ops'],
  'received_by_ops': ['engraving', 'cancelled'],
  'engraving': ['engraving_done', 'engraving_failed'],
  'engraving_failed': ['received_by_ops'],
  'engraving_done': ['shipped'],
  'shipped': ['delivered'],
};

/// Human-readable action button labels for each transition.
const Map<String, String> kTransitionLabels = {
  'received_by_ops': 'Confirmar pedido',
  'engraving': 'Iniciar grabado',
  'engraving_done': 'Marcar grabado',
  'engraving_failed': 'Marcar error grabado',
  'shipped': 'Marcar enviado',
  'delivered': 'Marcar entregado',
  'cancelled': 'Cancelar pedido',
};

/// Gradient colors per next-status (to visually differentiate actions).
List<Color> _colorsForStatus(String nextStatus) {
  switch (nextStatus) {
    case 'cancelled':
    case 'engraving_failed':
      return [const Color(0xFFE53935), const Color(0xFFB71C1C)];
    case 'engraving_done':
    case 'delivered':
      return [const Color(0xFF00FF88), const Color(0xFF00CC6A)];
    case 'shipped':
      return [const Color(0xFF00BCD4), const Color(0xFF0097A7)];
    default:
      return [const Color(0xFF1A73E8), const Color(0xFF6C5CE7)];
  }
}

/// Bottom action bar shown on [OperatorOrderDetailScreen].
///
/// Renders one [GlassButton] per valid next-state transition for the given
/// [currentStatus]. Pressing a button calls
/// [TransitionOrderNotifier.performTransition] via [transitionOrderStateProvider].
class OperatorStatusActionBar extends ConsumerWidget {
  final String currentStatus;
  final String orderId;

  /// Called after a successful transition (e.g. to pop the screen).
  final VoidCallback? onSuccess;

  const OperatorStatusActionBar({
    super.key,
    required this.currentStatus,
    required this.orderId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextStatuses = kValidTransitions[currentStatus] ?? [];

    // Listen to transition state to detect success / error.
    ref.listen<TransitionOrderState>(transitionOrderStateProvider, (prev, next) {
      if (!next.isLoading && prev?.isLoading == true) {
        if (next.success && onSuccess != null) {
          ref.read(transitionOrderStateProvider.notifier).reset();
          onSuccess!();
        } else if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${next.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(transitionOrderStateProvider.notifier).reset();
        }
      }
    });

    final transitionState = ref.watch(transitionOrderStateProvider);

    if (nextStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final nextStatus in nextStatuses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassButton(
                key: Key('operator_transition_btn_$nextStatus'),
                text: kTransitionLabels[nextStatus] ?? nextStatus,
                gradientColors: _colorsForStatus(nextStatus),
                isLoading: transitionState.isLoading,
                width: double.infinity,
                height: 52,
                fontSize: 15,
                onPressed: transitionState.isLoading
                    ? null
                    : () => ref
                        .read(transitionOrderStateProvider.notifier)
                        .performTransition(orderId, nextStatus),
              ),
            ),
        ],
      ),
    );
  }
}
