import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/operator_repository.dart';
import '../datasources/operator_supabase_datasource.dart';

export '../../domain/entities/operator_order_row.dart';

/// Concrete implementation of [OperatorRepository] backed by Supabase.
class OperatorRepositoryImpl implements OperatorRepository {
  final OperatorSupabaseDatasource _datasource;

  const OperatorRepositoryImpl(this._datasource);

  @override
  Future<List<OperatorOrderRow>> fetchOrdersByStatuses(
    List<String> statuses,
  ) async {
    try {
      final rows = await _datasource.fetchOrdersByStatuses(statuses);
      return rows.map(OperatorOrderRow.fromMap).toList();
    } on PostgrestException catch (e) {
      throw OperatorException(e.message, cause: e);
    } catch (e) {
      throw OperatorException(e.toString(), cause: e);
    }
  }

  @override
  Future<void> transitionOrder(String orderId, String newStatus) async {
    try {
      await _datasource.transitionOrder(orderId, newStatus);
    } on PostgrestException catch (e) {
      throw OperatorException(e.message, cause: e);
    } catch (e) {
      throw OperatorException(e.toString(), cause: e);
    }
  }
}
