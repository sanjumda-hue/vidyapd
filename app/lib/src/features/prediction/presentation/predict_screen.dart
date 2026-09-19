import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference/data/reference_repository.dart';
import '../../reference/domain/reference_data.dart';
import '../../shared/demo_data_banner.dart';
import '../application/prediction_controller.dart';
import '../domain/prediction_response.dart';
import 'widgets/match_card.dart';
import 'widgets/result_summary.dart';

class PredictScreen extends ConsumerWidget {
  const PredictScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = ref.watch(referenceDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Predict My College')),
      body: reference.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (data) => _PredictBody(reference: data),
      ),
    );
  }
}

class _PredictBody extends ConsumerWidget {
  const _PredictBody({required this.reference});
  final ReferenceData reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(predictInputProvider);
    final controller = ref.read(predictInputProvider.notifier);
    final result = ref.watch(predictionResultProvider);
    final exam = reference.exams.where((e) => e.code == input.examCode).firstOrNull;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            const DemoDataBanner(),
            const SizedBox(height: 16),

            _Label('Exam'),
            DropdownButtonFormField<String>(
              initialValue: input.examCode,
              hint: const Text('Select your exam'),
              items: [
                for (final e in reference.exams)
                  DropdownMenuItem(value: e.code, child: Text(e.name)),
              ],
              onChanged: (v) => controller.update(
                // Switching exam can invalidate a percentile entry, so clear it.
                (s) => s.copyWith(examCode: v, percentile: null, usePercentile: false),
              ),
            ),
            const SizedBox(height: 16),

            if (exam?.hasPercentile ?? false) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Rank')),
                  ButtonSegment(value: true, label: Text('Percentile')),
                ],
                selected: {input.usePercentile},
                onSelectionChanged: (s) =>
                    controller.update((x) => x.copyWith(usePercentile: s.first)),
              ),
              const SizedBox(height: 12),
            ],

            _Label(input.usePercentile ? 'Percentile' : 'Rank'),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: input.usePercentile ? 'e.g. 94.2' : 'e.g. 45821',
                prefixIcon: const Icon(Icons.numbers_rounded),
              ),
              onChanged: (v) => controller.update((s) => input.usePercentile
                  ? s.copyWith(percentile: double.tryParse(v))
                  : s.copyWith(rank: int.tryParse(v))),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Category'),
                      DropdownButtonFormField<String>(
                        initialValue: input.categoryCode,
                        hint: const Text('Category'),
                        items: [
                          for (final c in reference.categories)
                            DropdownMenuItem(value: c.code, child: Text(c.name)),
                        ],
                        onChanged: (v) =>
                            controller.update((s) => s.copyWith(categoryCode: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Gender'),
                      DropdownButtonFormField<String>(
                        initialValue: input.gender,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => controller
                            .update((s) => s.copyWith(gender: v ?? 'male')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _Label('Home state'),
            DropdownButtonFormField<String>(
              initialValue: input.homeStateCode,
              hint: const Text('Needed for home-state quota seats'),
              items: [
                for (final s in reference.states)
                  DropdownMenuItem(value: s.code, child: Text(s.name)),
              ],
              onChanged: (v) =>
                  controller.update((s) => s.copyWith(homeStateCode: v)),
            ),
            const SizedBox(height: 4),

            CheckboxListTile(
              value: input.isPwd,
              onChanged: (v) =>
                  controller.update((s) => s.copyWith(isPwd: v ?? false)),
              title: const Text('PwD candidate'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            const SizedBox(height: 8),

            _Label('Preferred branches (optional)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in reference.branches.where((b) => b.isPopular))
                  FilterChip(
                    label: Text(b.code),
                    tooltip: b.name,
                    selected: input.branchCodes.contains(b.code),
                    onSelected: (_) => controller.toggleBranch(b.code),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: input.isValid && result?.isLoading != true
                  ? () => ref.read(predictionResultProvider.notifier).run(input)
                  : null,
              icon: result?.isLoading == true
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_graph_rounded),
              label: Text(result?.isLoading == true ? 'Matching...' : 'Predict'),
            ),
            const SizedBox(height: 28),

            if (result != null) _Results(result: result),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result});
  final AsyncValue<PredictionResponse> result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return result.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      )),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$e', style: TextStyle(color: scheme.onErrorContainer)),
      ),
      data: (response) {
        if (response.matches.isEmpty) {
          return _EmptyResults(rank: response.rankUsed);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResultSummary(response: response),
            const SizedBox(height: 16),
            for (final m in response.matches) ...[
              MatchCard(match: m),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            // Required on every result list. See docs/04-prediction-engine.md.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      response.disclaimer,
                      style: TextStyle(
                          fontSize: 12, height: 1.45,
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: scheme.outline),
          const SizedBox(height: 10),
          const Text('No historical matches',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Nothing in the cutoff database overlaps rank $rank for these '
            'filters. Either no data has been imported for this exam yet, or '
            'the filters are too narrow.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}
