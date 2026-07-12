import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dpp_model.dart';
import '../../data/repositories/dpp_repository_impl.dart';
import '../../domain/repositories/dpp_repository.dart';

class DppHistoryState {
  final bool isLoading;
  final String? error;
  final List<DppModel> dpps;
  final String searchQuery;
  final String? selectedSubjectId;
  final String selectedDifficulty;

  DppHistoryState({
    this.isLoading = false,
    this.error,
    this.dpps = const [],
    this.searchQuery = '',
    this.selectedSubjectId,
    this.selectedDifficulty = 'All',
  });

  DppHistoryState copyWith({
    bool? isLoading,
    String? error,
    List<DppModel>? dpps,
    String? searchQuery,
    String? selectedSubjectId,
    String? selectedDifficulty,
  }) {
    return DppHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dpps: dpps ?? this.dpps,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
    );
  }
}

final dppHistoryControllerProvider =
    StateNotifierProvider<DppHistoryController, DppHistoryState>((ref) {
  final repository = ref.watch(dppRepositoryProvider);
  return DppHistoryController(repository: repository);
});

class DppHistoryController extends StateNotifier<DppHistoryState> {
  final DppRepository repository;

  DppHistoryController({required this.repository}) : super(DppHistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await repository.fetchDpps(
        searchQuery: state.searchQuery,
        subjectId: state.selectedSubjectId,
        difficulty: state.selectedDifficulty,
      );
      state = state.copyWith(
        isLoading: false,
        dpps: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadHistory();
  }

  void updateFilterSubject(String? subjectId) {
    state = state.copyWith(selectedSubjectId: subjectId);
    loadHistory();
  }

  void updateFilterDifficulty(String difficulty) {
    state = state.copyWith(selectedDifficulty: difficulty);
    loadHistory();
  }

  Future<void> deleteDpp(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await repository.deleteDpp(id);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<DppModel?> duplicateDpp(DppModel dpp) async {
    state = state.copyWith(isLoading: true);
    try {
      final questions = await repository.fetchQuestionsForDpp(dpp.id);
      final duplicated = dpp.copyWith(
        id: '',
        title: '${dpp.title} (Copy)',
        createdAt: DateTime.now(),
        status: 'draft',
      );
      final saved = await repository.createDpp(duplicated);
      await repository.saveQuestions(saved.id, questions);
      await loadHistory();
      return saved.copyWith(questions: questions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}
