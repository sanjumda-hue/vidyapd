import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prediction_repository.dart';
import '../domain/predict_input.dart';
import '../domain/prediction_response.dart';

/// Holds the form state. Every field edit rebuilds only the widgets that watch
/// the slice they care about.
class PredictInputController extends StateNotifier<PredictInput> {
  PredictInputController() : super(const PredictInput());

  void update(PredictInput Function(PredictInput) fn) => state = fn(state);

  void toggleBranch(String code) => state = state.copyWith(
        branchCodes: {...state.branchCodes}..toggle(code),
      );

  void toggleState(String code) => state = state.copyWith(
        stateCodes: {...state.stateCodes}..toggle(code),
      );

  void toggleCollegeType(String code) => state = state.copyWith(
        collegeTypes: {...state.collegeTypes}..toggle(code),
      );

  void reset() => state = const PredictInput();
}

extension<T> on Set<T> {
  void toggle(T value) => contains(value) ? remove(value) : add(value);
}

final predictInputProvider =
    StateNotifierProvider<PredictInputController, PredictInput>(
  (ref) => PredictInputController(),
);

/// null until the student presses Predict; then loading, then data or error.
final predictionResultProvider =
    StateNotifierProvider<PredictionResultController, AsyncValue<PredictionResponse>?>(
  (ref) => PredictionResultController(ref),
);

class PredictionResultController
    extends StateNotifier<AsyncValue<PredictionResponse>?> {
  PredictionResultController(this._ref) : super(null);
  final Ref _ref;

  Future<void> run(PredictInput input) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(predictionRepositoryProvider).predict(input),
    );
  }

  void clear() => state = null;
}

/// Put the Predict screen back to a blank form with no results.
///
/// Exposed here rather than having callers invalidate the two providers
/// themselves, so which providers make up "the form" stays inside this
/// feature. The shell calls it on every rail tap.
void resetPrediction(WidgetRef ref) {
  ref.read(predictInputProvider.notifier).reset();
  ref.read(predictionResultProvider.notifier).clear();
}
