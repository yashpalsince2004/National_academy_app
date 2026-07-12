import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/batch_model.dart';
import '../../data/repositories/batch_repository_impl.dart';
import '../../domain/repositories/batch_repository.dart';

final batchControllerProvider = StateNotifierProvider<BatchController, AsyncValue<List<BatchModel>>>((ref) {
  final repository = ref.watch(batchRepositoryProvider);
  return BatchController(repository: repository);
});

class BatchController extends StateNotifier<AsyncValue<List<BatchModel>>> {
  final BatchRepository repository;

  BatchController({required this.repository}) : super(const AsyncValue.loading()) {
    loadBatches();
  }

  Future<void> loadBatches() async {
    state = const AsyncValue.loading();
    try {
      final batches = await repository.fetchBatches();
      state = AsyncValue.data(batches);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createBatch({
    required String name,
    required String courseId,
    required String examType,
    required String classLevel,
    required String medium,
    required List<String> lectureDays,
    required int capacity,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? roomNumber,
    String? color,
    String? remarks,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newBatch = BatchModel(
        id: '', // database will generate it
        courseId: courseId,
        name: name,
        capacity: capacity,
        startDate: startDate,
        endDate: endDate,
        examType: examType,
        classLevel: classLevel,
        medium: medium,
        lectureDays: lectureDays,
        startTime: startTime,
        endTime: endTime,
        roomNumber: roomNumber,
        color: color,
        remarks: remarks,
        status: 'active',
      );
      await repository.createBatch(newBatch);
      await loadBatches();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateBatch(BatchModel updatedBatch) async {
    state = const AsyncValue.loading();
    try {
      await repository.updateBatch(updatedBatch);
      await loadBatches();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteBatch(String id) async {
    state = const AsyncValue.loading();
    try {
      await repository.deleteBatch(id);
      await loadBatches();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> archiveBatch(String id) async {
    state = const AsyncValue.loading();
    try {
      await repository.archiveBatch(id);
      await loadBatches();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
