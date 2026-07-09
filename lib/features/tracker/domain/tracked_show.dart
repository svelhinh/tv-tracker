import '../../import/domain/tv_time_show.dart';
import 'show_progress.dart';

class TrackedShow {
  const TrackedShow({required this.show, required this.progress});

  final TvTimeShow show;
  final ShowProgress progress;
}
