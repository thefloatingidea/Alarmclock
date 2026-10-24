import 'package:flutter/foundation.dart';

import 'quality_tier.dart';

/// The single source of truth the whole scene listens to.
///
/// In the proof of concept the slider writes [progress] and [dusk]. Later the
/// alarm integration writes [progress] from a DestructionClock instead.
class DestructionController {
  /// 0 = healthy, 1 = fully destroyed.
  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  /// 0 = day, 1 = night.
  final ValueNotifier<double> dusk = ValueNotifier<double>(0);

  final ValueNotifier<QualityTier> quality =
      ValueNotifier<QualityTier>(QualityTier.high);

  void dispose() {
    progress.dispose();
    dusk.dispose();
    quality.dispose();
  }
}
