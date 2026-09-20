import 'package:intl/intl.dart';

final _decimal = NumberFormat.decimalPattern('en_IN');

/// Formats a cut-off figure for display.
///
/// Ranks are whole numbers in the lakhs and want Indian grouping ("1,17,380").
/// Scores are small and often fractional -- a weighted cut-off comes back as
/// 312.9 -- and must not be rounded to 313, because the whole point of the
/// weighted figure is that it sits between two years. One formatter handles
/// both; what it must not do is print "308.0" for a whole-number score.
String plainNum(num v) => _decimal.format(v);

/// A score written the way a candidate reads it: "300/390".
String outOf(num score, num? max) =>
    max == null ? plainNum(score) : '${plainNum(score)}/${plainNum(max)}';
