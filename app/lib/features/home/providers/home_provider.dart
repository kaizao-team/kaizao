import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_models.dart';
import '../repositories/home_repository.dart';
import '../../auth/providers/auth_provider.dart';

class HomeState {
  final bool isLoading;
  final DemanderHomeData? demanderData;
  final ExpertHomeData? expertData;
  final String? errorMessage;

  const HomeState({
    this.isLoading = false,
    this.demanderData,
    this.expertData,
    this.errorMessage,
  });

  HomeState copyWith({
    bool? isLoading,
    DemanderHomeData? demanderData,
    ExpertHomeData? expertData,
    String? Function()? errorMessage,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      demanderData: demanderData ?? this.demanderData,
      expertData: expertData ?? this.expertData,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;
  final int _userRole;

  HomeNotifier(this._repository, this._userRole) : super(const HomeState()) {
    loadHome();
  }

  bool get _isDemander => _userRole != 2;

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      if (_isDemander) {
        final data = await _repository.fetchDemanderHome();
        if (!mounted) return;
        state = state.copyWith(isLoading: false, demanderData: data);
      } else {
        final data = await _repository.fetchExpertHome();
        if (!mounted) return;
        state = state.copyWith(isLoading: false, expertData: data);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadHome();
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

final homeStateProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return HomeNotifier(repository, authState.userRole);
});
