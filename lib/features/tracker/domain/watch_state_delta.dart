import 'episode_key.dart';

class WatchStateDelta {
  const WatchStateDelta({this.added = const {}, this.removed = const {}});

  final Set<EpisodeKey> added;
  final Set<EpisodeKey> removed;

  WatchStateDelta copyWith({Set<EpisodeKey>? added, Set<EpisodeKey>? removed}) {
    return WatchStateDelta(
      added: added ?? this.added,
      removed: removed ?? this.removed,
    );
  }

  Map<String, dynamic> toJson() => {
    'added': added.map((key) => key.storageKey).toList(),
    'removed': removed.map((key) => key.storageKey).toList(),
  };

  factory WatchStateDelta.fromJson(Map<String, dynamic> json) {
    return WatchStateDelta(
      added: _parseKeys(json['added']),
      removed: _parseKeys(json['removed']),
    );
  }

  static Set<EpisodeKey> _parseKeys(dynamic raw) {
    if (raw is! List) return {};

    return raw.whereType<String>().map(EpisodeKey.parse).toSet();
  }
}
