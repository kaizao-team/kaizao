import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_models.dart';
import '../repositories/match_repository.dart';

class BidListState {
  final bool isLoading;
  final List<BidItem> bids;
  final String? errorMessage;

  const BidListState({
    this.isLoading = false,
    this.bids = const [],
    this.errorMessage,
  });

  BidListState copyWith({
    bool? isLoading,
    List<BidItem>? bids,
    String? Function()? errorMessage,
  }) {
    return BidListState(
      isLoading: isLoading ?? this.isLoading,
      bids: bids ?? this.bids,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class BidListNotifier extends StateNotifier<BidListState> {
  final MatchRepository _repository;
  final String projectId;

  BidListNotifier(this._repository, this.projectId)
      : super(const BidListState()) {
    loadBids();
  }

  Future<void> loadBids() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final bids = await _repository.fetchBids(projectId);
      if (!mounted) return;
      final sorted = List<BidItem>.from(bids)
        ..sort((a, b) {
          if (a.isAiRecommended && !b.isAiRecommended) return -1;
          if (!a.isAiRecommended && b.isAiRecommended) return 1;
          return b.matchScore.compareTo(a.matchScore);
        });
      state = state.copyWith(isLoading: false, bids: sorted);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<bool> acceptBid(String bidId) async {
    try {
      await _repository.acceptBid(bidId);
      if (!mounted) return false;
      state = state.copyWith(
        bids: state.bids
            .map((b) =>
                b.id == bidId ? b.copyWith(status: BidStatus.accepted) : b)
            .toList(),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: () => e.toString());
      return false;
    }
  }

  Future<bool> withdrawBid(String bidId) async {
    try {
      await _repository.withdrawBid(bidId);
      if (!mounted) return false;
      state = state.copyWith(
        bids: state.bids
            .map((b) =>
                b.id == bidId ? b.copyWith(status: BidStatus.withdrawn) : b)
            .toList(),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: () => e.toString());
      return false;
    }
  }
}

final bidListProvider = StateNotifierProvider.autoDispose
    .family<BidListNotifier, BidListState, String>((ref, projectId) {
  return BidListNotifier(MatchRepository(), projectId);
});

// Bid form state
class BidFormState {
  final bool isLoading;
  final bool isSubmitting;
  final AiSuggestion? suggestion;
  final BidFormType bidType;
  final double? amount;
  final int? durationDays;
  final String proposal;
  final String? errorMessage;

  const BidFormState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.suggestion,
    this.bidType = BidFormType.personal,
    this.amount,
    this.durationDays,
    this.proposal = '',
    this.errorMessage,
  });

  BidFormState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    AiSuggestion? suggestion,
    BidFormType? bidType,
    double? Function()? amount,
    int? Function()? durationDays,
    String? proposal,
    String? Function()? errorMessage,
  }) {
    return BidFormState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      suggestion: suggestion ?? this.suggestion,
      bidType: bidType ?? this.bidType,
      amount: amount != null ? amount() : this.amount,
      durationDays:
          durationDays != null ? durationDays() : this.durationDays,
      proposal: proposal ?? this.proposal,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  bool get isAmountBelowBudget {
    if (amount == null || suggestion == null) return false;
    return amount! < suggestion!.suggestedPriceMin;
  }

  bool get isAmountZero => amount != null && amount! <= 0;

  bool get canSubmit =>
      amount != null &&
      amount! > 0 &&
      durationDays != null &&
      durationDays! > 0 &&
      proposal.isNotEmpty;
}

class BidFormNotifier extends StateNotifier<BidFormState> {
  final MatchRepository _repository;
  final String projectId;

  BidFormNotifier(this._repository, this.projectId)
      : super(const BidFormState()) {
    _loadSuggestion();
  }

  Future<void> _loadSuggestion() async {
    state = state.copyWith(isLoading: true);
    try {
      final suggestion = await _repository.fetchAiSuggestion(projectId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, suggestion: suggestion);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  void reloadSuggestion() => _loadSuggestion();

  void setBidType(BidFormType type) {
    state = state.copyWith(bidType: type);
  }

  void setAmount(double value) {
    state = state.copyWith(amount: () => value, errorMessage: () => null);
  }

  void setDuration(int days) {
    state = state.copyWith(durationDays: () => days);
  }

  void setProposal(String text) {
    state = state.copyWith(proposal: text);
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);
    try {
      await _repository.submitBid(
        projectId: projectId,
        amount: state.amount!,
        durationDays: state.durationDays!,
        proposal: state.proposal,
        bidType: state.bidType.name,
      );
      if (!mounted) return false;
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => e.toString(),
      );
      return false;
    }
  }
}

final bidFormProvider = StateNotifierProvider.autoDispose
    .family<BidFormNotifier, BidFormState, String>((ref, projectId) {
  return BidFormNotifier(MatchRepository(), projectId);
});
