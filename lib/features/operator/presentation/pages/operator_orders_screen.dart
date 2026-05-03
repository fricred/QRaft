import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/operator_providers.dart';
import '../widgets/operator_order_card.dart';
import 'operator_order_detail_screen.dart';

/// Tab configuration: label + DB status strings to include.
class _Tab {
  final String label;
  final List<String> statuses;

  const _Tab(this.label, this.statuses);
}

const _tabs = [
  _Tab('Por atender', ['paid']),
  _Tab('En proceso', ['received_by_ops', 'engraving']),
  _Tab('Listos/Enviados', ['engraving_done', 'shipped']),
  _Tab('Todos', [
    'paid',
    'received_by_ops',
    'engraving',
    'engraving_failed',
    'engraving_done',
    'shipped',
    'delivered',
  ]),
];

/// Operator order queue screen with 4 status-filter tabs.
///
/// Displays all orders visible to the operator (RLS bypass pending plan 11-03).
/// Each tab shows orders filtered to the relevant status group, with stale-order
/// red flag indicators and pull-to-refresh.
class OperatorOrdersScreen extends ConsumerStatefulWidget {
  const OperatorOrdersScreen({super.key});

  @override
  ConsumerState<OperatorOrdersScreen> createState() =>
      _OperatorOrdersScreenState();
}

class _OperatorOrdersScreenState extends ConsumerState<OperatorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('operator_orders_screen_root'),
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text(
          'Cola de Pedidos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF00FF88),
          unselectedLabelColor: const Color(0xFF888888),
          indicatorColor: const Color(0xFF00FF88),
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((t) => _OrderQueueTab(statuses: t.statuses))
            .toList(),
      ),
    );
  }
}

/// Single tab body — shows a refreshable list of [OperatorOrderCard]s.
class _OrderQueueTab extends ConsumerWidget {
  final List<String> statuses;

  const _OrderQueueTab({required this.statuses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(operatorOrdersProvider(statuses));

    return ordersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FF88)),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error al cargar pedidos:\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(operatorOrdersProvider(statuses)),
                child: const Text('Reintentar',
                    style: TextStyle(color: Color(0xFF1A73E8))),
              ),
            ],
          ),
        ),
      ),
      data: (orders) => RefreshIndicator(
        color: const Color(0xFF00FF88),
        onRefresh: () async {
          ref.invalidate(operatorOrdersProvider(statuses));
          await ref.read(operatorOrdersProvider(statuses).future);
        },
        child: orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No hay pedidos en esta categoria',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OperatorOrderCard(
                      order: order,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OperatorOrderDetailScreen(
                              orderId: order.id,
                              orderNumber: order.orderNumber,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
