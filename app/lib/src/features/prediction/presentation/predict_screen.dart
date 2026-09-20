import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reference/data/reference_repository.dart';
import '../../reference/domain/reference_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/demo_data_banner.dart';
import '../../shared/num_format.dart';
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

    // The form is built once as a list of fields and then laid out two ways.
    // On a desktop window it sits in a fixed panel on the left with the results
    // beside it, so a student can change a filter and watch the list react
    // without scrolling back up. Narrow, it is the single column it always was.
    final formFields = <Widget>[
            // Only when the invented colleges are actually loaded. This was
            // unconditional, so it warned about (DEMO) colleges on every page
            // load long after real cut-offs had replaced them.
            if (reference.hasDemoData) ...[
              const DemoDataBanner(),
              const SizedBox(height: 16),
            ],

            _Label('Exam'),
            DropdownButtonFormField<String>(
              // Without this the button sizes to its widest item and spills out
              // of the form panel. With it the button fills the field and the
              // label below ellipsises instead.
              isExpanded: true,
              initialValue: input.examCode,
              hint: const Text('Select your exam'),
              items: [
                for (final e in reference.exams)
                  DropdownMenuItem(
                    value: e.code,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        ),
                        if (!e.hasCutoffData) ...[
                          const SizedBox(width: 8),
                          Text('no data yet',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.outline)),
                        ],
                      ],
                    ),
                  ),
              ],
              onChanged: (v) {
                final picked =
                    reference.exams.where((e) => e.code == v).firstOrNull;
                controller.update(
                  // Switching exam can invalidate whatever was typed, so clear
                  // every input field rather than carrying a rank over into a
                  // score box.
                  (s) => s.copyWith(
                    examCode: v,
                    rank: null,
                    percentile: null,
                    score: null,
                    usePercentile: false,
                    usesMarks: picked?.usesMarks ?? false,
                    maxScore: picked?.maxScore,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Two reasons the toggle can be absent. A marks-based exam has no
            // rank to offer at all. And an exam that reports a percentile but
            // has no conversion data loaded cannot answer one either -- that
            // was JEE Main until recently, where picking Percentile and hitting
            // Predict returned a 400 every time.
            if (!input.usesMarks && (exam?.hasPercentileData ?? false)) ...[
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

            _Label(input.usesMarks
                ? (input.maxScore == null
                    ? 'Score'
                    : 'Score (out of ${plainNum(input.maxScore!)})')
                : input.usePercentile
                    ? 'Percentile'
                    : 'Rank'),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: input.usesMarks
                    ? 'e.g. 300'
                    : input.usePercentile
                        ? 'e.g. 94.2'
                        : 'e.g. 45821',
                prefixIcon: const Icon(Icons.numbers_rounded),
                // Entering 400 out of 390 is the one mistake this field invites,
                // and the server rejects it. Say so before the round trip.
                errorText: input.usesMarks &&
                        input.score != null &&
                        input.maxScore != null &&
                        input.score! > input.maxScore!
                    ? 'The paper is out of ${plainNum(input.maxScore!)}.'
                    : null,
              ),
              onChanged: (v) => controller.update((s) => input.usesMarks
                  ? s.copyWith(score: double.tryParse(v))
                  : input.usePercentile
                      ? s.copyWith(percentile: double.tryParse(v))
                      : s.copyWith(rank: int.tryParse(v))),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Category'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: input.categoryCode,
                        hint: const Text('Category'),
                        items: [
                          for (final c in reference.categories)
                            DropdownMenuItem(
                              value: c.code,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            ),
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
                        isExpanded: true,
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
            const SizedBox(height: 10),

            _Label('Home state'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: input.homeStateCode,
              hint: const Text(
                'Needed for home-state quota seats',
                overflow: TextOverflow.ellipsis,
              ),
              items: [
                for (final s in reference.states)
                  DropdownMenuItem(
                    value: s.code,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
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
            const SizedBox(height: 4),

            _BranchFilter(
              branches: reference.branches.where((b) => b.isPopular).toList(),
              selected: input.branchCodes,
              onToggle: controller.toggleBranch,
            ),
            const SizedBox(height: 14),

            FilledButton.icon(
              // The theme's 50px minimum is a mobile default; this panel is
              // counting pixels.
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
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
    ];

    final results = result == null
        ? null
        : _Results(
            result: result,
            examName: exam?.name ?? '',
            examHasData: exam?.hasCutoffData ?? true,
          );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 1000) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  ...formFields,
                  const SizedBox(height: 28),
                  if (results != null) results,
                ],
              ),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 420,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 12, 18),
                child: Card(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    children: formFields,
                  ),
                ),
              ),
            ),
            Expanded(
              child: results == null
                  ? const _NoRunYet()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 16, 24, 32),
                      children: [results],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// The right-hand pane before anything has been predicted.
///
/// A blank half-screen reads as something failing to load, so it says what it
/// is waiting for.
class _NoRunYet extends StatelessWidget {
  const _NoRunYet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: Brand.selected(Theme.of(context).brightness),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              size: 48,
              color: dark ? Brand.light : Brand.deep,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No prediction yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 300,
            child: Text(
              'Fill the form and hit Predict. Results are historical matches '
              'from published cutoffs, never a promise of admission.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.result,
    required this.examName,
    required this.examHasData,
  });
  final AsyncValue<PredictionResponse> result;
  final String examName;
  final bool examHasData;

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
          return _EmptyResults(
            input: response.isScoreBased
                ? 'a score of ${plainNum(response.scoreUsed!)}'
                    '/${plainNum(response.maxScoreUsed!)}'
                : 'rank ${response.rankUsed}',
            examName: examName,
            examHasData: examHasData,
            homeStateSet: response.homeState != null,
          );
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
  const _EmptyResults({
    required this.input,
    required this.examName,
    required this.examHasData,
    required this.homeStateSet,
  });

  /// Already phrased: "rank 45821", or "a score of 300/390".
  final String input;
  final String examName;
  final bool examHasData;
  final bool homeStateSet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Two very different situations were showing the same vague message, and a
    // student hit Predict three times in a row trying to make sense of it.
    // Say which one it is.
    final (title, detail) = !examHasData
        ? (
            'No cutoff data for $examName yet',
            'Cutoffs for this exam have not been imported. Nothing is wrong '
                'with your entry -- there is simply nothing to compare it '
                'against. Exams without data are marked in the dropdown.',
          )
        // Home state first, and not as a footnote. Every COMEDK seat sits in
        // either the home-state pool or the Kalyana Karnataka one, so leaving
        // this blank removes the entire exam -- and being told to widen the
        // branch filters sends you looking in the wrong place.
        : !homeStateSet
            ? (
                'No matches without a home state',
                'Home-state and regional quota seats are left out until you '
                    'pick a home state, because eligibility for them cannot be '
                    'checked otherwise. On some exams -- COMEDK is entirely '
                    'home-state and Kalyana Karnataka seats -- that removes '
                    'everything. Set it and run again.',
              )
            : (
                'No historical matches',
                'Nothing in the cutoff database overlaps $input for these '
                    'filters. Try clearing the branch filters or widening them.',
              );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(examHasData ? Icons.search_off_rounded : Icons.inbox_outlined,
              size: 36, color: scheme.outline),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The optional branch filter, collapsed by default.
///
/// Fourteen chips wrap to three rows, which on its own was 158 of the 494
/// pixels this panel has -- and the reason the form could not be seen without
/// scrolling. Collapsed it is one row; nothing is removed, and whatever is
/// currently selected stays visible so a filter can never be on without the
/// student seeing it.
class _BranchFilter extends StatefulWidget {
  const _BranchFilter({
    required this.branches,
    required this.selected,
    required this.onToggle,
  });

  final List<BranchOption> branches;
  final Set<String> selected;
  final void Function(String code) onToggle;

  @override
  State<_BranchFilter> createState() => _BranchFilterState();
}

class _BranchFilterState extends State<_BranchFilter> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = _open
        ? widget.branches
        : widget.branches.where((b) => widget.selected.contains(b.code)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Text(
                  'Preferred branches (optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (widget.selected.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '· ${widget.selected.length}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 19,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (shown.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final b in shown)
                FilterChip(
                  label: Text(b.code, style: const TextStyle(fontSize: 12)),
                  tooltip: b.name,
                  selected: widget.selected.contains(b.code),
                  onSelected: (_) => widget.onToggle(b.code),
                  // Chips carry a 48px tap target by default, which is a
                  // finger. This panel is read with a mouse.
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}
