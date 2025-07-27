import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/qr_local_data_source.dart';
import '../../data/datasources/qr_remote_data_source.dart';
import '../../data/datasources/qr_shared_prefs_data_source.dart';
import '../../data/datasources/qr_supabase_data_source.dart';
import '../../data/repositories/qr_repository_impl.dart';
import '../../domain/repositories/qr_repository.dart';
import '../../domain/use_cases/generate_qr_use_case.dart';

// Data Source Providers
final qrRemoteDataSourceProvider = Provider<QRRemoteDataSource>((ref) {
  return QRSupabaseDataSource(client: Supabase.instance.client);
});

final qrLocalDataSourceProvider = Provider<QRLocalDataSource>((ref) {
  return QRSharedPrefsDataSource();
});

// Repository Provider
final qrRepositoryProvider = Provider<QRRepository>((ref) {
  return QRRepositoryImpl(
    remoteDataSource: ref.watch(qrRemoteDataSourceProvider),
    localDataSource: ref.watch(qrLocalDataSourceProvider),
  );
});

// Use Cases Providers
final generateQRUseCaseProvider = Provider<GenerateQRUseCase>((ref) {
  return GenerateQRUseCase(repository: ref.watch(qrRepositoryProvider));
});

final getUserQRCodesUseCaseProvider = Provider<GetUserQRCodesUseCase>((ref) {
  return GetUserQRCodesUseCase(repository: ref.watch(qrRepositoryProvider));
});

final updateQRCodeUseCaseProvider = Provider<UpdateQRCodeUseCase>((ref) {
  return UpdateQRCodeUseCase(repository: ref.watch(qrRepositoryProvider));
});

final deleteQRCodeUseCaseProvider = Provider<DeleteQRCodeUseCase>((ref) {
  return DeleteQRCodeUseCase(repository: ref.watch(qrRepositoryProvider));
});