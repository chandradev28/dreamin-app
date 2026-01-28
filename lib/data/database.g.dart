// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HistoryEntriesTable extends HistoryEntries
    with TableInfo<$HistoryEntriesTable, HistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _trackJsonMeta =
      const VerificationMeta('trackJson');
  @override
  late final GeneratedColumn<String> trackJson = GeneratedColumn<String>(
      'track_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playedAtMeta =
      const VerificationMeta('playedAt');
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
      'played_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _playedDurationMsMeta =
      const VerificationMeta('playedDurationMs');
  @override
  late final GeneratedColumn<int> playedDurationMs = GeneratedColumn<int>(
      'played_duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _artistIdMeta =
      const VerificationMeta('artistId');
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
      'artist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        trackId,
        source,
        trackJson,
        playedAt,
        playedDurationMs,
        genre,
        artistId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_entries';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('track_json')) {
      context.handle(_trackJsonMeta,
          trackJson.isAcceptableOrUnknown(data['track_json']!, _trackJsonMeta));
    } else if (isInserting) {
      context.missing(_trackJsonMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(_playedAtMeta,
          playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta));
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('played_duration_ms')) {
      context.handle(
          _playedDurationMsMeta,
          playedDurationMs.isAcceptableOrUnknown(
              data['played_duration_ms']!, _playedDurationMsMeta));
    } else if (isInserting) {
      context.missing(_playedDurationMsMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('artist_id')) {
      context.handle(_artistIdMeta,
          artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta));
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      trackJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_json'])!,
      playedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}played_at'])!,
      playedDurationMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}played_duration_ms'])!,
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre']),
      artistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_id'])!,
    );
  }

  @override
  $HistoryEntriesTable createAlias(String alias) {
    return $HistoryEntriesTable(attachedDatabase, alias);
  }
}

class HistoryEntry extends DataClass implements Insertable<HistoryEntry> {
  final int id;
  final String trackId;
  final int source;
  final String trackJson;
  final DateTime playedAt;
  final int playedDurationMs;
  final String? genre;
  final String artistId;
  const HistoryEntry(
      {required this.id,
      required this.trackId,
      required this.source,
      required this.trackJson,
      required this.playedAt,
      required this.playedDurationMs,
      this.genre,
      required this.artistId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['source'] = Variable<int>(source);
    map['track_json'] = Variable<String>(trackJson);
    map['played_at'] = Variable<DateTime>(playedAt);
    map['played_duration_ms'] = Variable<int>(playedDurationMs);
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    map['artist_id'] = Variable<String>(artistId);
    return map;
  }

  HistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return HistoryEntriesCompanion(
      id: Value(id),
      trackId: Value(trackId),
      source: Value(source),
      trackJson: Value(trackJson),
      playedAt: Value(playedAt),
      playedDurationMs: Value(playedDurationMs),
      genre:
          genre == null && nullToAbsent ? const Value.absent() : Value(genre),
      artistId: Value(artistId),
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      source: serializer.fromJson<int>(json['source']),
      trackJson: serializer.fromJson<String>(json['trackJson']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      playedDurationMs: serializer.fromJson<int>(json['playedDurationMs']),
      genre: serializer.fromJson<String?>(json['genre']),
      artistId: serializer.fromJson<String>(json['artistId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'source': serializer.toJson<int>(source),
      'trackJson': serializer.toJson<String>(trackJson),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'playedDurationMs': serializer.toJson<int>(playedDurationMs),
      'genre': serializer.toJson<String?>(genre),
      'artistId': serializer.toJson<String>(artistId),
    };
  }

  HistoryEntry copyWith(
          {int? id,
          String? trackId,
          int? source,
          String? trackJson,
          DateTime? playedAt,
          int? playedDurationMs,
          Value<String?> genre = const Value.absent(),
          String? artistId}) =>
      HistoryEntry(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        source: source ?? this.source,
        trackJson: trackJson ?? this.trackJson,
        playedAt: playedAt ?? this.playedAt,
        playedDurationMs: playedDurationMs ?? this.playedDurationMs,
        genre: genre.present ? genre.value : this.genre,
        artistId: artistId ?? this.artistId,
      );
  HistoryEntry copyWithCompanion(HistoryEntriesCompanion data) {
    return HistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      source: data.source.present ? data.source.value : this.source,
      trackJson: data.trackJson.present ? data.trackJson.value : this.trackJson,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      playedDurationMs: data.playedDurationMs.present
          ? data.playedDurationMs.value
          : this.playedDurationMs,
      genre: data.genre.present ? data.genre.value : this.genre,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntry(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('playedAt: $playedAt, ')
          ..write('playedDurationMs: $playedDurationMs, ')
          ..write('genre: $genre, ')
          ..write('artistId: $artistId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, source, trackJson, playedAt,
      playedDurationMs, genre, artistId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryEntry &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.source == this.source &&
          other.trackJson == this.trackJson &&
          other.playedAt == this.playedAt &&
          other.playedDurationMs == this.playedDurationMs &&
          other.genre == this.genre &&
          other.artistId == this.artistId);
}

class HistoryEntriesCompanion extends UpdateCompanion<HistoryEntry> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<int> source;
  final Value<String> trackJson;
  final Value<DateTime> playedAt;
  final Value<int> playedDurationMs;
  final Value<String?> genre;
  final Value<String> artistId;
  const HistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.source = const Value.absent(),
    this.trackJson = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.playedDurationMs = const Value.absent(),
    this.genre = const Value.absent(),
    this.artistId = const Value.absent(),
  });
  HistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required int source,
    required String trackJson,
    required DateTime playedAt,
    required int playedDurationMs,
    this.genre = const Value.absent(),
    required String artistId,
  })  : trackId = Value(trackId),
        source = Value(source),
        trackJson = Value(trackJson),
        playedAt = Value(playedAt),
        playedDurationMs = Value(playedDurationMs),
        artistId = Value(artistId);
  static Insertable<HistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<int>? source,
    Expression<String>? trackJson,
    Expression<DateTime>? playedAt,
    Expression<int>? playedDurationMs,
    Expression<String>? genre,
    Expression<String>? artistId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (source != null) 'source': source,
      if (trackJson != null) 'track_json': trackJson,
      if (playedAt != null) 'played_at': playedAt,
      if (playedDurationMs != null) 'played_duration_ms': playedDurationMs,
      if (genre != null) 'genre': genre,
      if (artistId != null) 'artist_id': artistId,
    });
  }

  HistoryEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? trackId,
      Value<int>? source,
      Value<String>? trackJson,
      Value<DateTime>? playedAt,
      Value<int>? playedDurationMs,
      Value<String?>? genre,
      Value<String>? artistId}) {
    return HistoryEntriesCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      source: source ?? this.source,
      trackJson: trackJson ?? this.trackJson,
      playedAt: playedAt ?? this.playedAt,
      playedDurationMs: playedDurationMs ?? this.playedDurationMs,
      genre: genre ?? this.genre,
      artistId: artistId ?? this.artistId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (trackJson.present) {
      map['track_json'] = Variable<String>(trackJson.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (playedDurationMs.present) {
      map['played_duration_ms'] = Variable<int>(playedDurationMs.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('playedAt: $playedAt, ')
          ..write('playedDurationMs: $playedDurationMs, ')
          ..write('genre: $genre, ')
          ..write('artistId: $artistId')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _trackJsonMeta =
      const VerificationMeta('trackJson');
  @override
  late final GeneratedColumn<String> trackJson = GeneratedColumn<String>(
      'track_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, trackId, source, trackJson, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(Insertable<Favorite> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('track_json')) {
      context.handle(_trackJsonMeta,
          trackJson.isAcceptableOrUnknown(data['track_json']!, _trackJsonMeta));
    } else if (isInserting) {
      context.missing(_trackJsonMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      trackJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_json'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final String trackId;
  final int source;
  final String trackJson;
  final DateTime addedAt;
  const Favorite(
      {required this.id,
      required this.trackId,
      required this.source,
      required this.trackJson,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['source'] = Variable<int>(source);
    map['track_json'] = Variable<String>(trackJson);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      trackId: Value(trackId),
      source: Value(source),
      trackJson: Value(trackJson),
      addedAt: Value(addedAt),
    );
  }

  factory Favorite.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      source: serializer.fromJson<int>(json['source']),
      trackJson: serializer.fromJson<String>(json['trackJson']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'source': serializer.toJson<int>(source),
      'trackJson': serializer.toJson<String>(trackJson),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Favorite copyWith(
          {int? id,
          String? trackId,
          int? source,
          String? trackJson,
          DateTime? addedAt}) =>
      Favorite(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        source: source ?? this.source,
        trackJson: trackJson ?? this.trackJson,
        addedAt: addedAt ?? this.addedAt,
      );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      source: data.source.present ? data.source.value : this.source,
      trackJson: data.trackJson.present ? data.trackJson.value : this.trackJson,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, source, trackJson, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.source == this.source &&
          other.trackJson == this.trackJson &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<int> source;
  final Value<String> trackJson;
  final Value<DateTime> addedAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.source = const Value.absent(),
    this.trackJson = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required int source,
    required String trackJson,
    required DateTime addedAt,
  })  : trackId = Value(trackId),
        source = Value(source),
        trackJson = Value(trackJson),
        addedAt = Value(addedAt);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<int>? source,
    Expression<String>? trackJson,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (source != null) 'source': source,
      if (trackJson != null) 'track_json': trackJson,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FavoritesCompanion copyWith(
      {Value<int>? id,
      Value<String>? trackId,
      Value<int>? source,
      Value<String>? trackJson,
      Value<DateTime>? addedAt}) {
    return FavoritesCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      source: source ?? this.source,
      trackJson: trackJson ?? this.trackJson,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (trackJson.present) {
      map['track_json'] = Variable<String>(trackJson.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistsTable extends LocalPlaylists
    with TableInfo<$LocalPlaylistsTable, LocalPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, coverUrl, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_playlists';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPlaylist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylist(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalPlaylistsTable createAlias(String alias) {
    return $LocalPlaylistsTable(attachedDatabase, alias);
  }
}

class LocalPlaylist extends DataClass implements Insertable<LocalPlaylist> {
  final int id;
  final String name;
  final String? coverUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalPlaylist(
      {required this.id,
      required this.name,
      this.coverUrl,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPlaylist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPlaylist copyWith(
          {int? id,
          String? name,
          Value<String?> coverUrl = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      LocalPlaylist(
        id: id ?? this.id,
        name: name ?? this.name,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalPlaylist copyWithCompanion(LocalPlaylistsCompanion data) {
    return LocalPlaylist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, coverUrl, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylist &&
          other.id == this.id &&
          other.name == this.name &&
          other.coverUrl == this.coverUrl &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalPlaylistsCompanion extends UpdateCompanion<LocalPlaylist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> coverUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LocalPlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalPlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.coverUrl = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalPlaylist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? coverUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalPlaylistsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? coverUrl,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return LocalPlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTable extends PlaylistTracks
    with TableInfo<$PlaylistTracksTable, PlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_playlists (id)'));
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _trackJsonMeta =
      const VerificationMeta('trackJson');
  @override
  late final GeneratedColumn<String> trackJson = GeneratedColumn<String>(
      'track_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, trackId, source, trackJson, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistTrack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('track_json')) {
      context.handle(_trackJsonMeta,
          trackJson.isAcceptableOrUnknown(data['track_json']!, _trackJsonMeta));
    } else if (isInserting) {
      context.missing(_trackJsonMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrack(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}playlist_id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      trackJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_json'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $PlaylistTracksTable createAlias(String alias) {
    return $PlaylistTracksTable(attachedDatabase, alias);
  }
}

class PlaylistTrack extends DataClass implements Insertable<PlaylistTrack> {
  final int id;
  final int playlistId;
  final String trackId;
  final int source;
  final String trackJson;
  final int position;
  const PlaylistTrack(
      {required this.id,
      required this.playlistId,
      required this.trackId,
      required this.source,
      required this.trackJson,
      required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<int>(playlistId);
    map['track_id'] = Variable<String>(trackId);
    map['source'] = Variable<int>(source);
    map['track_json'] = Variable<String>(trackJson);
    map['position'] = Variable<int>(position);
    return map;
  }

  PlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      source: Value(source),
      trackJson: Value(trackJson),
      position: Value(position),
    );
  }

  factory PlaylistTrack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrack(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      source: serializer.fromJson<int>(json['source']),
      trackJson: serializer.fromJson<String>(json['trackJson']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<int>(playlistId),
      'trackId': serializer.toJson<String>(trackId),
      'source': serializer.toJson<int>(source),
      'trackJson': serializer.toJson<String>(trackJson),
      'position': serializer.toJson<int>(position),
    };
  }

  PlaylistTrack copyWith(
          {int? id,
          int? playlistId,
          String? trackId,
          int? source,
          String? trackJson,
          int? position}) =>
      PlaylistTrack(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        trackId: trackId ?? this.trackId,
        source: source ?? this.source,
        trackJson: trackJson ?? this.trackJson,
        position: position ?? this.position,
      );
  PlaylistTrack copyWithCompanion(PlaylistTracksCompanion data) {
    return PlaylistTrack(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      source: data.source.present ? data.source.value : this.source,
      trackJson: data.trackJson.present ? data.trackJson.value : this.trackJson,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrack(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, trackId, source, trackJson, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrack &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.source == this.source &&
          other.trackJson == this.trackJson &&
          other.position == this.position);
}

class PlaylistTracksCompanion extends UpdateCompanion<PlaylistTrack> {
  final Value<int> id;
  final Value<int> playlistId;
  final Value<String> trackId;
  final Value<int> source;
  final Value<String> trackJson;
  final Value<int> position;
  const PlaylistTracksCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.source = const Value.absent(),
    this.trackJson = const Value.absent(),
    this.position = const Value.absent(),
  });
  PlaylistTracksCompanion.insert({
    this.id = const Value.absent(),
    required int playlistId,
    required String trackId,
    required int source,
    required String trackJson,
    required int position,
  })  : playlistId = Value(playlistId),
        trackId = Value(trackId),
        source = Value(source),
        trackJson = Value(trackJson),
        position = Value(position);
  static Insertable<PlaylistTrack> custom({
    Expression<int>? id,
    Expression<int>? playlistId,
    Expression<String>? trackId,
    Expression<int>? source,
    Expression<String>? trackJson,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (source != null) 'source': source,
      if (trackJson != null) 'track_json': trackJson,
      if (position != null) 'position': position,
    });
  }

  PlaylistTracksCompanion copyWith(
      {Value<int>? id,
      Value<int>? playlistId,
      Value<String>? trackId,
      Value<int>? source,
      Value<String>? trackJson,
      Value<int>? position}) {
    return PlaylistTracksCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      source: source ?? this.source,
      trackJson: trackJson ?? this.trackJson,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (trackJson.present) {
      map['track_json'] = Variable<String>(trackJson.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $CachedTracksTable extends CachedTracks
    with TableInfo<$CachedTracksTable, CachedTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _trackJsonMeta =
      const VerificationMeta('trackJson');
  @override
  late final GeneratedColumn<String> trackJson = GeneratedColumn<String>(
      'track_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, trackId, source, trackJson, filePath, fileSize, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_tracks';
  @override
  VerificationContext validateIntegrity(Insertable<CachedTrack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('track_json')) {
      context.handle(_trackJsonMeta,
          trackJson.isAcceptableOrUnknown(data['track_json']!, _trackJsonMeta));
    } else if (isInserting) {
      context.missing(_trackJsonMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTrack(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      trackJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_json'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedTracksTable createAlias(String alias) {
    return $CachedTracksTable(attachedDatabase, alias);
  }
}

class CachedTrack extends DataClass implements Insertable<CachedTrack> {
  final int id;
  final String trackId;
  final int source;
  final String trackJson;
  final String filePath;
  final int fileSize;
  final DateTime cachedAt;
  const CachedTrack(
      {required this.id,
      required this.trackId,
      required this.source,
      required this.trackJson,
      required this.filePath,
      required this.fileSize,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['source'] = Variable<int>(source);
    map['track_json'] = Variable<String>(trackJson);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedTracksCompanion toCompanion(bool nullToAbsent) {
    return CachedTracksCompanion(
      id: Value(id),
      trackId: Value(trackId),
      source: Value(source),
      trackJson: Value(trackJson),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedTrack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTrack(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      source: serializer.fromJson<int>(json['source']),
      trackJson: serializer.fromJson<String>(json['trackJson']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'source': serializer.toJson<int>(source),
      'trackJson': serializer.toJson<String>(trackJson),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedTrack copyWith(
          {int? id,
          String? trackId,
          int? source,
          String? trackJson,
          String? filePath,
          int? fileSize,
          DateTime? cachedAt}) =>
      CachedTrack(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        source: source ?? this.source,
        trackJson: trackJson ?? this.trackJson,
        filePath: filePath ?? this.filePath,
        fileSize: fileSize ?? this.fileSize,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedTrack copyWithCompanion(CachedTracksCompanion data) {
    return CachedTrack(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      source: data.source.present ? data.source.value : this.source,
      trackJson: data.trackJson.present ? data.trackJson.value : this.trackJson,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTrack(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trackId, source, trackJson, filePath, fileSize, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTrack &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.source == this.source &&
          other.trackJson == this.trackJson &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.cachedAt == this.cachedAt);
}

class CachedTracksCompanion extends UpdateCompanion<CachedTrack> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<int> source;
  final Value<String> trackJson;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<DateTime> cachedAt;
  const CachedTracksCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.source = const Value.absent(),
    this.trackJson = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedTracksCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required int source,
    required String trackJson,
    required String filePath,
    required int fileSize,
    required DateTime cachedAt,
  })  : trackId = Value(trackId),
        source = Value(source),
        trackJson = Value(trackJson),
        filePath = Value(filePath),
        fileSize = Value(fileSize),
        cachedAt = Value(cachedAt);
  static Insertable<CachedTrack> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<int>? source,
    Expression<String>? trackJson,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (source != null) 'source': source,
      if (trackJson != null) 'track_json': trackJson,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedTracksCompanion copyWith(
      {Value<int>? id,
      Value<String>? trackId,
      Value<int>? source,
      Value<String>? trackJson,
      Value<String>? filePath,
      Value<int>? fileSize,
      Value<DateTime>? cachedAt}) {
    return CachedTracksCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      source: source ?? this.source,
      trackJson: trackJson ?? this.trackJson,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (trackJson.present) {
      map['track_json'] = Variable<String>(trackJson.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTracksCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('trackJson: $trackJson, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $PlayCountsTable extends PlayCounts
    with TableInfo<$PlayCountsTable, PlayCount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayCountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _artistIdMeta =
      const VerificationMeta('artistId');
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
      'artist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _playCountMeta =
      const VerificationMeta('playCount');
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
      'play_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _skipCountMeta =
      const VerificationMeta('skipCount');
  @override
  late final GeneratedColumn<int> skipCount = GeneratedColumn<int>(
      'skip_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
      'last_played_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        trackId,
        source,
        artistId,
        genre,
        playCount,
        skipCount,
        lastPlayedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_counts';
  @override
  VerificationContext validateIntegrity(Insertable<PlayCount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(_artistIdMeta,
          artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta));
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    }
    if (data.containsKey('play_count')) {
      context.handle(_playCountMeta,
          playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta));
    }
    if (data.containsKey('skip_count')) {
      context.handle(_skipCountMeta,
          skipCount.isAcceptableOrUnknown(data['skip_count']!, _skipCountMeta));
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayCount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayCount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      artistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_id'])!,
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre']),
      playCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}play_count'])!,
      skipCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}skip_count'])!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_played_at']),
    );
  }

  @override
  $PlayCountsTable createAlias(String alias) {
    return $PlayCountsTable(attachedDatabase, alias);
  }
}

class PlayCount extends DataClass implements Insertable<PlayCount> {
  final int id;
  final String trackId;
  final int source;
  final String artistId;
  final String? genre;
  final int playCount;
  final int skipCount;
  final DateTime? lastPlayedAt;
  const PlayCount(
      {required this.id,
      required this.trackId,
      required this.source,
      required this.artistId,
      this.genre,
      required this.playCount,
      required this.skipCount,
      this.lastPlayedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['source'] = Variable<int>(source);
    map['artist_id'] = Variable<String>(artistId);
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    map['play_count'] = Variable<int>(playCount);
    map['skip_count'] = Variable<int>(skipCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    return map;
  }

  PlayCountsCompanion toCompanion(bool nullToAbsent) {
    return PlayCountsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      source: Value(source),
      artistId: Value(artistId),
      genre:
          genre == null && nullToAbsent ? const Value.absent() : Value(genre),
      playCount: Value(playCount),
      skipCount: Value(skipCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory PlayCount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayCount(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      source: serializer.fromJson<int>(json['source']),
      artistId: serializer.fromJson<String>(json['artistId']),
      genre: serializer.fromJson<String?>(json['genre']),
      playCount: serializer.fromJson<int>(json['playCount']),
      skipCount: serializer.fromJson<int>(json['skipCount']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'source': serializer.toJson<int>(source),
      'artistId': serializer.toJson<String>(artistId),
      'genre': serializer.toJson<String?>(genre),
      'playCount': serializer.toJson<int>(playCount),
      'skipCount': serializer.toJson<int>(skipCount),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
    };
  }

  PlayCount copyWith(
          {int? id,
          String? trackId,
          int? source,
          String? artistId,
          Value<String?> genre = const Value.absent(),
          int? playCount,
          int? skipCount,
          Value<DateTime?> lastPlayedAt = const Value.absent()}) =>
      PlayCount(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        source: source ?? this.source,
        artistId: artistId ?? this.artistId,
        genre: genre.present ? genre.value : this.genre,
        playCount: playCount ?? this.playCount,
        skipCount: skipCount ?? this.skipCount,
        lastPlayedAt:
            lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
      );
  PlayCount copyWithCompanion(PlayCountsCompanion data) {
    return PlayCount(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      source: data.source.present ? data.source.value : this.source,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      genre: data.genre.present ? data.genre.value : this.genre,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      skipCount: data.skipCount.present ? data.skipCount.value : this.skipCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayCount(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('artistId: $artistId, ')
          ..write('genre: $genre, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, trackId, source, artistId, genre, playCount, skipCount, lastPlayedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayCount &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.source == this.source &&
          other.artistId == this.artistId &&
          other.genre == this.genre &&
          other.playCount == this.playCount &&
          other.skipCount == this.skipCount &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class PlayCountsCompanion extends UpdateCompanion<PlayCount> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<int> source;
  final Value<String> artistId;
  final Value<String?> genre;
  final Value<int> playCount;
  final Value<int> skipCount;
  final Value<DateTime?> lastPlayedAt;
  const PlayCountsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.source = const Value.absent(),
    this.artistId = const Value.absent(),
    this.genre = const Value.absent(),
    this.playCount = const Value.absent(),
    this.skipCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  PlayCountsCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required int source,
    required String artistId,
    this.genre = const Value.absent(),
    this.playCount = const Value.absent(),
    this.skipCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  })  : trackId = Value(trackId),
        source = Value(source),
        artistId = Value(artistId);
  static Insertable<PlayCount> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<int>? source,
    Expression<String>? artistId,
    Expression<String>? genre,
    Expression<int>? playCount,
    Expression<int>? skipCount,
    Expression<DateTime>? lastPlayedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (source != null) 'source': source,
      if (artistId != null) 'artist_id': artistId,
      if (genre != null) 'genre': genre,
      if (playCount != null) 'play_count': playCount,
      if (skipCount != null) 'skip_count': skipCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  PlayCountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? trackId,
      Value<int>? source,
      Value<String>? artistId,
      Value<String?>? genre,
      Value<int>? playCount,
      Value<int>? skipCount,
      Value<DateTime?>? lastPlayedAt}) {
    return PlayCountsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      source: source ?? this.source,
      artistId: artistId ?? this.artistId,
      genre: genre ?? this.genre,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (skipCount.present) {
      map['skip_count'] = Variable<int>(skipCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayCountsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('artistId: $artistId, ')
          ..write('genre: $genre, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}

class $GenreFrequencyTable extends GenreFrequency
    with TableInfo<$GenreFrequencyTable, GenreFrequencyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenreFrequencyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
      'genre', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playCountMeta =
      const VerificationMeta('playCount');
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
      'play_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
      'last_played_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, genre, playCount, lastPlayedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genre_frequency';
  @override
  VerificationContext validateIntegrity(Insertable<GenreFrequencyData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('genre')) {
      context.handle(
          _genreMeta, genre.isAcceptableOrUnknown(data['genre']!, _genreMeta));
    } else if (isInserting) {
      context.missing(_genreMeta);
    }
    if (data.containsKey('play_count')) {
      context.handle(_playCountMeta,
          playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta));
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GenreFrequencyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenreFrequencyData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      genre: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre'])!,
      playCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}play_count'])!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_played_at']),
    );
  }

  @override
  $GenreFrequencyTable createAlias(String alias) {
    return $GenreFrequencyTable(attachedDatabase, alias);
  }
}

class GenreFrequencyData extends DataClass
    implements Insertable<GenreFrequencyData> {
  final int id;
  final String genre;
  final int playCount;
  final DateTime? lastPlayedAt;
  const GenreFrequencyData(
      {required this.id,
      required this.genre,
      required this.playCount,
      this.lastPlayedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['genre'] = Variable<String>(genre);
    map['play_count'] = Variable<int>(playCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    return map;
  }

  GenreFrequencyCompanion toCompanion(bool nullToAbsent) {
    return GenreFrequencyCompanion(
      id: Value(id),
      genre: Value(genre),
      playCount: Value(playCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory GenreFrequencyData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenreFrequencyData(
      id: serializer.fromJson<int>(json['id']),
      genre: serializer.fromJson<String>(json['genre']),
      playCount: serializer.fromJson<int>(json['playCount']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'genre': serializer.toJson<String>(genre),
      'playCount': serializer.toJson<int>(playCount),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
    };
  }

  GenreFrequencyData copyWith(
          {int? id,
          String? genre,
          int? playCount,
          Value<DateTime?> lastPlayedAt = const Value.absent()}) =>
      GenreFrequencyData(
        id: id ?? this.id,
        genre: genre ?? this.genre,
        playCount: playCount ?? this.playCount,
        lastPlayedAt:
            lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
      );
  GenreFrequencyData copyWithCompanion(GenreFrequencyCompanion data) {
    return GenreFrequencyData(
      id: data.id.present ? data.id.value : this.id,
      genre: data.genre.present ? data.genre.value : this.genre,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenreFrequencyData(')
          ..write('id: $id, ')
          ..write('genre: $genre, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, genre, playCount, lastPlayedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenreFrequencyData &&
          other.id == this.id &&
          other.genre == this.genre &&
          other.playCount == this.playCount &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class GenreFrequencyCompanion extends UpdateCompanion<GenreFrequencyData> {
  final Value<int> id;
  final Value<String> genre;
  final Value<int> playCount;
  final Value<DateTime?> lastPlayedAt;
  const GenreFrequencyCompanion({
    this.id = const Value.absent(),
    this.genre = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  GenreFrequencyCompanion.insert({
    this.id = const Value.absent(),
    required String genre,
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  }) : genre = Value(genre);
  static Insertable<GenreFrequencyData> custom({
    Expression<int>? id,
    Expression<String>? genre,
    Expression<int>? playCount,
    Expression<DateTime>? lastPlayedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (genre != null) 'genre': genre,
      if (playCount != null) 'play_count': playCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  GenreFrequencyCompanion copyWith(
      {Value<int>? id,
      Value<String>? genre,
      Value<int>? playCount,
      Value<DateTime?>? lastPlayedAt}) {
    return GenreFrequencyCompanion(
      id: id ?? this.id,
      genre: genre ?? this.genre,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenreFrequencyCompanion(')
          ..write('id: $id, ')
          ..write('genre: $genre, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}

class $ArtistFrequencyTable extends ArtistFrequency
    with TableInfo<$ArtistFrequencyTable, ArtistFrequencyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistFrequencyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _artistIdMeta =
      const VerificationMeta('artistId');
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
      'artist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistNameMeta =
      const VerificationMeta('artistName');
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
      'artist_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _playCountMeta =
      const VerificationMeta('playCount');
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
      'play_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
      'last_played_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, artistId, artistName, playCount, lastPlayedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artist_frequency';
  @override
  VerificationContext validateIntegrity(
      Insertable<ArtistFrequencyData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('artist_id')) {
      context.handle(_artistIdMeta,
          artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta));
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
          _artistNameMeta,
          artistName.isAcceptableOrUnknown(
              data['artist_name']!, _artistNameMeta));
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('play_count')) {
      context.handle(_playCountMeta,
          playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta));
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArtistFrequencyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtistFrequencyData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      artistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_id'])!,
      artistName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist_name'])!,
      playCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}play_count'])!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_played_at']),
    );
  }

  @override
  $ArtistFrequencyTable createAlias(String alias) {
    return $ArtistFrequencyTable(attachedDatabase, alias);
  }
}

class ArtistFrequencyData extends DataClass
    implements Insertable<ArtistFrequencyData> {
  final int id;
  final String artistId;
  final String artistName;
  final int playCount;
  final DateTime? lastPlayedAt;
  const ArtistFrequencyData(
      {required this.id,
      required this.artistId,
      required this.artistName,
      required this.playCount,
      this.lastPlayedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['artist_id'] = Variable<String>(artistId);
    map['artist_name'] = Variable<String>(artistName);
    map['play_count'] = Variable<int>(playCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    return map;
  }

  ArtistFrequencyCompanion toCompanion(bool nullToAbsent) {
    return ArtistFrequencyCompanion(
      id: Value(id),
      artistId: Value(artistId),
      artistName: Value(artistName),
      playCount: Value(playCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory ArtistFrequencyData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtistFrequencyData(
      id: serializer.fromJson<int>(json['id']),
      artistId: serializer.fromJson<String>(json['artistId']),
      artistName: serializer.fromJson<String>(json['artistName']),
      playCount: serializer.fromJson<int>(json['playCount']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'artistId': serializer.toJson<String>(artistId),
      'artistName': serializer.toJson<String>(artistName),
      'playCount': serializer.toJson<int>(playCount),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
    };
  }

  ArtistFrequencyData copyWith(
          {int? id,
          String? artistId,
          String? artistName,
          int? playCount,
          Value<DateTime?> lastPlayedAt = const Value.absent()}) =>
      ArtistFrequencyData(
        id: id ?? this.id,
        artistId: artistId ?? this.artistId,
        artistName: artistName ?? this.artistName,
        playCount: playCount ?? this.playCount,
        lastPlayedAt:
            lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
      );
  ArtistFrequencyData copyWithCompanion(ArtistFrequencyCompanion data) {
    return ArtistFrequencyData(
      id: data.id.present ? data.id.value : this.id,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      artistName:
          data.artistName.present ? data.artistName.value : this.artistName,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtistFrequencyData(')
          ..write('id: $id, ')
          ..write('artistId: $artistId, ')
          ..write('artistName: $artistName, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, artistId, artistName, playCount, lastPlayedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistFrequencyData &&
          other.id == this.id &&
          other.artistId == this.artistId &&
          other.artistName == this.artistName &&
          other.playCount == this.playCount &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class ArtistFrequencyCompanion extends UpdateCompanion<ArtistFrequencyData> {
  final Value<int> id;
  final Value<String> artistId;
  final Value<String> artistName;
  final Value<int> playCount;
  final Value<DateTime?> lastPlayedAt;
  const ArtistFrequencyCompanion({
    this.id = const Value.absent(),
    this.artistId = const Value.absent(),
    this.artistName = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  });
  ArtistFrequencyCompanion.insert({
    this.id = const Value.absent(),
    required String artistId,
    required String artistName,
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
  })  : artistId = Value(artistId),
        artistName = Value(artistName);
  static Insertable<ArtistFrequencyData> custom({
    Expression<int>? id,
    Expression<String>? artistId,
    Expression<String>? artistName,
    Expression<int>? playCount,
    Expression<DateTime>? lastPlayedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (artistId != null) 'artist_id': artistId,
      if (artistName != null) 'artist_name': artistName,
      if (playCount != null) 'play_count': playCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  ArtistFrequencyCompanion copyWith(
      {Value<int>? id,
      Value<String>? artistId,
      Value<String>? artistName,
      Value<int>? playCount,
      Value<DateTime?>? lastPlayedAt}) {
    return ArtistFrequencyCompanion(
      id: id ?? this.id,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistFrequencyCompanion(')
          ..write('id: $id, ')
          ..write('artistId: $artistId, ')
          ..write('artistName: $artistName, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}

class $SavedAlbumsTable extends SavedAlbums
    with TableInfo<$SavedAlbumsTable, SavedAlbum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedAlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _albumJsonMeta =
      const VerificationMeta('albumJson');
  @override
  late final GeneratedColumn<String> albumJson = GeneratedColumn<String>(
      'album_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, albumId, source, albumJson, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_albums';
  @override
  VerificationContext validateIntegrity(Insertable<SavedAlbum> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('album_json')) {
      context.handle(_albumJsonMeta,
          albumJson.isAcceptableOrUnknown(data['album_json']!, _albumJsonMeta));
    } else if (isInserting) {
      context.missing(_albumJsonMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedAlbum(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      albumJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_json'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $SavedAlbumsTable createAlias(String alias) {
    return $SavedAlbumsTable(attachedDatabase, alias);
  }
}

class SavedAlbum extends DataClass implements Insertable<SavedAlbum> {
  final int id;
  final String albumId;
  final int source;
  final String albumJson;
  final DateTime addedAt;
  const SavedAlbum(
      {required this.id,
      required this.albumId,
      required this.source,
      required this.albumJson,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['album_id'] = Variable<String>(albumId);
    map['source'] = Variable<int>(source);
    map['album_json'] = Variable<String>(albumJson);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  SavedAlbumsCompanion toCompanion(bool nullToAbsent) {
    return SavedAlbumsCompanion(
      id: Value(id),
      albumId: Value(albumId),
      source: Value(source),
      albumJson: Value(albumJson),
      addedAt: Value(addedAt),
    );
  }

  factory SavedAlbum.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedAlbum(
      id: serializer.fromJson<int>(json['id']),
      albumId: serializer.fromJson<String>(json['albumId']),
      source: serializer.fromJson<int>(json['source']),
      albumJson: serializer.fromJson<String>(json['albumJson']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'albumId': serializer.toJson<String>(albumId),
      'source': serializer.toJson<int>(source),
      'albumJson': serializer.toJson<String>(albumJson),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  SavedAlbum copyWith(
          {int? id,
          String? albumId,
          int? source,
          String? albumJson,
          DateTime? addedAt}) =>
      SavedAlbum(
        id: id ?? this.id,
        albumId: albumId ?? this.albumId,
        source: source ?? this.source,
        albumJson: albumJson ?? this.albumJson,
        addedAt: addedAt ?? this.addedAt,
      );
  SavedAlbum copyWithCompanion(SavedAlbumsCompanion data) {
    return SavedAlbum(
      id: data.id.present ? data.id.value : this.id,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      source: data.source.present ? data.source.value : this.source,
      albumJson: data.albumJson.present ? data.albumJson.value : this.albumJson,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedAlbum(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('source: $source, ')
          ..write('albumJson: $albumJson, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, albumId, source, albumJson, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedAlbum &&
          other.id == this.id &&
          other.albumId == this.albumId &&
          other.source == this.source &&
          other.albumJson == this.albumJson &&
          other.addedAt == this.addedAt);
}

class SavedAlbumsCompanion extends UpdateCompanion<SavedAlbum> {
  final Value<int> id;
  final Value<String> albumId;
  final Value<int> source;
  final Value<String> albumJson;
  final Value<DateTime> addedAt;
  const SavedAlbumsCompanion({
    this.id = const Value.absent(),
    this.albumId = const Value.absent(),
    this.source = const Value.absent(),
    this.albumJson = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  SavedAlbumsCompanion.insert({
    this.id = const Value.absent(),
    required String albumId,
    required int source,
    required String albumJson,
    required DateTime addedAt,
  })  : albumId = Value(albumId),
        source = Value(source),
        albumJson = Value(albumJson),
        addedAt = Value(addedAt);
  static Insertable<SavedAlbum> custom({
    Expression<int>? id,
    Expression<String>? albumId,
    Expression<int>? source,
    Expression<String>? albumJson,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (albumId != null) 'album_id': albumId,
      if (source != null) 'source': source,
      if (albumJson != null) 'album_json': albumJson,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  SavedAlbumsCompanion copyWith(
      {Value<int>? id,
      Value<String>? albumId,
      Value<int>? source,
      Value<String>? albumJson,
      Value<DateTime>? addedAt}) {
    return SavedAlbumsCompanion(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      source: source ?? this.source,
      albumJson: albumJson ?? this.albumJson,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (albumJson.present) {
      map['album_json'] = Variable<String>(albumJson.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedAlbumsCompanion(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('source: $source, ')
          ..write('albumJson: $albumJson, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $SavedPlaylistsTable extends SavedPlaylists
    with TableInfo<$SavedPlaylistsTable, SavedPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
      'source', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _playlistJsonMeta =
      const VerificationMeta('playlistJson');
  @override
  late final GeneratedColumn<String> playlistJson = GeneratedColumn<String>(
      'playlist_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playlistId, source, playlistJson, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_playlists';
  @override
  VerificationContext validateIntegrity(Insertable<SavedPlaylist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('playlist_json')) {
      context.handle(
          _playlistJsonMeta,
          playlistJson.isAcceptableOrUnknown(
              data['playlist_json']!, _playlistJsonMeta));
    } else if (isInserting) {
      context.missing(_playlistJsonMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedPlaylist(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source'])!,
      playlistJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_json'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $SavedPlaylistsTable createAlias(String alias) {
    return $SavedPlaylistsTable(attachedDatabase, alias);
  }
}

class SavedPlaylist extends DataClass implements Insertable<SavedPlaylist> {
  final int id;
  final String playlistId;
  final int source;
  final String playlistJson;
  final DateTime addedAt;
  const SavedPlaylist(
      {required this.id,
      required this.playlistId,
      required this.source,
      required this.playlistJson,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['source'] = Variable<int>(source);
    map['playlist_json'] = Variable<String>(playlistJson);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  SavedPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return SavedPlaylistsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      source: Value(source),
      playlistJson: Value(playlistJson),
      addedAt: Value(addedAt),
    );
  }

  factory SavedPlaylist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedPlaylist(
      id: serializer.fromJson<int>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      source: serializer.fromJson<int>(json['source']),
      playlistJson: serializer.fromJson<String>(json['playlistJson']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'source': serializer.toJson<int>(source),
      'playlistJson': serializer.toJson<String>(playlistJson),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  SavedPlaylist copyWith(
          {int? id,
          String? playlistId,
          int? source,
          String? playlistJson,
          DateTime? addedAt}) =>
      SavedPlaylist(
        id: id ?? this.id,
        playlistId: playlistId ?? this.playlistId,
        source: source ?? this.source,
        playlistJson: playlistJson ?? this.playlistJson,
        addedAt: addedAt ?? this.addedAt,
      );
  SavedPlaylist copyWithCompanion(SavedPlaylistsCompanion data) {
    return SavedPlaylist(
      id: data.id.present ? data.id.value : this.id,
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      source: data.source.present ? data.source.value : this.source,
      playlistJson: data.playlistJson.present
          ? data.playlistJson.value
          : this.playlistJson,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylist(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('source: $source, ')
          ..write('playlistJson: $playlistJson, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlistId, source, playlistJson, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedPlaylist &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.source == this.source &&
          other.playlistJson == this.playlistJson &&
          other.addedAt == this.addedAt);
}

class SavedPlaylistsCompanion extends UpdateCompanion<SavedPlaylist> {
  final Value<int> id;
  final Value<String> playlistId;
  final Value<int> source;
  final Value<String> playlistJson;
  final Value<DateTime> addedAt;
  const SavedPlaylistsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.source = const Value.absent(),
    this.playlistJson = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  SavedPlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String playlistId,
    required int source,
    required String playlistJson,
    required DateTime addedAt,
  })  : playlistId = Value(playlistId),
        source = Value(source),
        playlistJson = Value(playlistJson),
        addedAt = Value(addedAt);
  static Insertable<SavedPlaylist> custom({
    Expression<int>? id,
    Expression<String>? playlistId,
    Expression<int>? source,
    Expression<String>? playlistJson,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (source != null) 'source': source,
      if (playlistJson != null) 'playlist_json': playlistJson,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  SavedPlaylistsCompanion copyWith(
      {Value<int>? id,
      Value<String>? playlistId,
      Value<int>? source,
      Value<String>? playlistJson,
      Value<DateTime>? addedAt}) {
    return SavedPlaylistsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      source: source ?? this.source,
      playlistJson: playlistJson ?? this.playlistJson,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (playlistJson.present) {
      map['playlist_json'] = Variable<String>(playlistJson.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('source: $source, ')
          ..write('playlistJson: $playlistJson, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HistoryEntriesTable historyEntries = $HistoryEntriesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $LocalPlaylistsTable localPlaylists = $LocalPlaylistsTable(this);
  late final $PlaylistTracksTable playlistTracks = $PlaylistTracksTable(this);
  late final $CachedTracksTable cachedTracks = $CachedTracksTable(this);
  late final $PlayCountsTable playCounts = $PlayCountsTable(this);
  late final $GenreFrequencyTable genreFrequency = $GenreFrequencyTable(this);
  late final $ArtistFrequencyTable artistFrequency =
      $ArtistFrequencyTable(this);
  late final $SavedAlbumsTable savedAlbums = $SavedAlbumsTable(this);
  late final $SavedPlaylistsTable savedPlaylists = $SavedPlaylistsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        historyEntries,
        favorites,
        localPlaylists,
        playlistTracks,
        cachedTracks,
        playCounts,
        genreFrequency,
        artistFrequency,
        savedAlbums,
        savedPlaylists
      ];
}

typedef $$HistoryEntriesTableCreateCompanionBuilder = HistoryEntriesCompanion
    Function({
  Value<int> id,
  required String trackId,
  required int source,
  required String trackJson,
  required DateTime playedAt,
  required int playedDurationMs,
  Value<String?> genre,
  required String artistId,
});
typedef $$HistoryEntriesTableUpdateCompanionBuilder = HistoryEntriesCompanion
    Function({
  Value<int> id,
  Value<String> trackId,
  Value<int> source,
  Value<String> trackJson,
  Value<DateTime> playedAt,
  Value<int> playedDurationMs,
  Value<String?> genre,
  Value<String> artistId,
});

class $$HistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
      column: $table.playedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playedDurationMs => $composableBuilder(
      column: $table.playedDurationMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistId => $composableBuilder(
      column: $table.artistId, builder: (column) => ColumnFilters(column));
}

class $$HistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
      column: $table.playedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playedDurationMs => $composableBuilder(
      column: $table.playedDurationMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistId => $composableBuilder(
      column: $table.artistId, builder: (column) => ColumnOrderings(column));
}

class $$HistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryEntriesTable> {
  $$HistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get trackJson =>
      $composableBuilder(column: $table.trackJson, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get playedDurationMs => $composableBuilder(
      column: $table.playedDurationMs, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);
}

class $$HistoryEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HistoryEntriesTable,
    HistoryEntry,
    $$HistoryEntriesTableFilterComposer,
    $$HistoryEntriesTableOrderingComposer,
    $$HistoryEntriesTableAnnotationComposer,
    $$HistoryEntriesTableCreateCompanionBuilder,
    $$HistoryEntriesTableUpdateCompanionBuilder,
    (
      HistoryEntry,
      BaseReferences<_$AppDatabase, $HistoryEntriesTable, HistoryEntry>
    ),
    HistoryEntry,
    PrefetchHooks Function()> {
  $$HistoryEntriesTableTableManager(
      _$AppDatabase db, $HistoryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> trackId = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<String> trackJson = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
            Value<int> playedDurationMs = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<String> artistId = const Value.absent(),
          }) =>
              HistoryEntriesCompanion(
            id: id,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            playedAt: playedAt,
            playedDurationMs: playedDurationMs,
            genre: genre,
            artistId: artistId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String trackId,
            required int source,
            required String trackJson,
            required DateTime playedAt,
            required int playedDurationMs,
            Value<String?> genre = const Value.absent(),
            required String artistId,
          }) =>
              HistoryEntriesCompanion.insert(
            id: id,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            playedAt: playedAt,
            playedDurationMs: playedDurationMs,
            genre: genre,
            artistId: artistId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HistoryEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HistoryEntriesTable,
    HistoryEntry,
    $$HistoryEntriesTableFilterComposer,
    $$HistoryEntriesTableOrderingComposer,
    $$HistoryEntriesTableAnnotationComposer,
    $$HistoryEntriesTableCreateCompanionBuilder,
    $$HistoryEntriesTableUpdateCompanionBuilder,
    (
      HistoryEntry,
      BaseReferences<_$AppDatabase, $HistoryEntriesTable, HistoryEntry>
    ),
    HistoryEntry,
    PrefetchHooks Function()>;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  required String trackId,
  required int source,
  required String trackJson,
  required DateTime addedAt,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<int> id,
  Value<String> trackId,
  Value<int> source,
  Value<String> trackJson,
  Value<DateTime> addedAt,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get trackJson =>
      $composableBuilder(column: $table.trackJson, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
    Favorite,
    PrefetchHooks Function()> {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> trackId = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<String> trackJson = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) =>
              FavoritesCompanion(
            id: id,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            addedAt: addedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String trackId,
            required int source,
            required String trackJson,
            required DateTime addedAt,
          }) =>
              FavoritesCompanion.insert(
            id: id,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            addedAt: addedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoritesTable,
    Favorite,
    $$FavoritesTableFilterComposer,
    $$FavoritesTableOrderingComposer,
    $$FavoritesTableAnnotationComposer,
    $$FavoritesTableCreateCompanionBuilder,
    $$FavoritesTableUpdateCompanionBuilder,
    (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
    Favorite,
    PrefetchHooks Function()>;
typedef $$LocalPlaylistsTableCreateCompanionBuilder = LocalPlaylistsCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> coverUrl,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$LocalPlaylistsTableUpdateCompanionBuilder = LocalPlaylistsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> coverUrl,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$LocalPlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalPlaylistsTable, LocalPlaylist> {
  $$LocalPlaylistsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistTracksTable, List<PlaylistTrack>>
      _playlistTracksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.playlistTracks,
              aliasName: $_aliasNameGenerator(
                  db.localPlaylists.id, db.playlistTracks.playlistId));

  $$PlaylistTracksTableProcessedTableManager get playlistTracksRefs {
    final manager = $$PlaylistTracksTableTableManager($_db, $_db.playlistTracks)
        .filter((f) => f.playlistId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_playlistTracksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LocalPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> playlistTracksRefs(
      Expression<bool> Function($$PlaylistTracksTableFilterComposer f) f) {
    final $$PlaylistTracksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistTracks,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistTracksTableFilterComposer(
              $db: $db,
              $table: $db.playlistTracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> playlistTracksRefs<T extends Object>(
      Expression<T> Function($$PlaylistTracksTableAnnotationComposer a) f) {
    final $$PlaylistTracksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistTracks,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistTracksTableAnnotationComposer(
              $db: $db,
              $table: $db.playlistTracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LocalPlaylistsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPlaylistsTable,
    LocalPlaylist,
    $$LocalPlaylistsTableFilterComposer,
    $$LocalPlaylistsTableOrderingComposer,
    $$LocalPlaylistsTableAnnotationComposer,
    $$LocalPlaylistsTableCreateCompanionBuilder,
    $$LocalPlaylistsTableUpdateCompanionBuilder,
    (LocalPlaylist, $$LocalPlaylistsTableReferences),
    LocalPlaylist,
    PrefetchHooks Function({bool playlistTracksRefs})> {
  $$LocalPlaylistsTableTableManager(
      _$AppDatabase db, $LocalPlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              LocalPlaylistsCompanion(
            id: id,
            name: name,
            coverUrl: coverUrl,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> coverUrl = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              LocalPlaylistsCompanion.insert(
            id: id,
            name: name,
            coverUrl: coverUrl,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LocalPlaylistsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistTracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistTracksRefs) db.playlistTracks
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistTracksRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$LocalPlaylistsTableReferences
                            ._playlistTracksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LocalPlaylistsTableReferences(db, table, p0)
                                .playlistTracksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LocalPlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPlaylistsTable,
    LocalPlaylist,
    $$LocalPlaylistsTableFilterComposer,
    $$LocalPlaylistsTableOrderingComposer,
    $$LocalPlaylistsTableAnnotationComposer,
    $$LocalPlaylistsTableCreateCompanionBuilder,
    $$LocalPlaylistsTableUpdateCompanionBuilder,
    (LocalPlaylist, $$LocalPlaylistsTableReferences),
    LocalPlaylist,
    PrefetchHooks Function({bool playlistTracksRefs})>;
typedef $$PlaylistTracksTableCreateCompanionBuilder = PlaylistTracksCompanion
    Function({
  Value<int> id,
  required int playlistId,
  required String trackId,
  required int source,
  required String trackJson,
  required int position,
});
typedef $$PlaylistTracksTableUpdateCompanionBuilder = PlaylistTracksCompanion
    Function({
  Value<int> id,
  Value<int> playlistId,
  Value<String> trackId,
  Value<int> source,
  Value<String> trackJson,
  Value<int> position,
});

final class $$PlaylistTracksTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistTracksTable, PlaylistTrack> {
  $$PlaylistTracksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $LocalPlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.localPlaylists.createAlias($_aliasNameGenerator(
          db.playlistTracks.playlistId, db.localPlaylists.id));

  $$LocalPlaylistsTableProcessedTableManager get playlistId {
    final manager = $$LocalPlaylistsTableTableManager($_db, $_db.localPlaylists)
        .filter((f) => f.id($_item.playlistId));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$LocalPlaylistsTableFilterComposer get playlistId {
    final $$LocalPlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.localPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.localPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$LocalPlaylistsTableOrderingComposer get playlistId {
    final $$LocalPlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.localPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.localPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get trackJson =>
      $composableBuilder(column: $table.trackJson, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$LocalPlaylistsTableAnnotationComposer get playlistId {
    final $$LocalPlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.localPlaylists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LocalPlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.localPlaylists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistTracksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistTracksTable,
    PlaylistTrack,
    $$PlaylistTracksTableFilterComposer,
    $$PlaylistTracksTableOrderingComposer,
    $$PlaylistTracksTableAnnotationComposer,
    $$PlaylistTracksTableCreateCompanionBuilder,
    $$PlaylistTracksTableUpdateCompanionBuilder,
    (PlaylistTrack, $$PlaylistTracksTableReferences),
    PlaylistTrack,
    PrefetchHooks Function({bool playlistId})> {
  $$PlaylistTracksTableTableManager(
      _$AppDatabase db, $PlaylistTracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playlistId = const Value.absent(),
            Value<String> trackId = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<String> trackJson = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) =>
              PlaylistTracksCompanion(
            id: id,
            playlistId: playlistId,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            position: position,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playlistId,
            required String trackId,
            required int source,
            required String trackJson,
            required int position,
          }) =>
              PlaylistTracksCompanion.insert(
            id: id,
            playlistId: playlistId,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            position: position,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaylistTracksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable:
                        $$PlaylistTracksTableReferences._playlistIdTable(db),
                    referencedColumn:
                        $$PlaylistTracksTableReferences._playlistIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PlaylistTracksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistTracksTable,
    PlaylistTrack,
    $$PlaylistTracksTableFilterComposer,
    $$PlaylistTracksTableOrderingComposer,
    $$PlaylistTracksTableAnnotationComposer,
    $$PlaylistTracksTableCreateCompanionBuilder,
    $$PlaylistTracksTableUpdateCompanionBuilder,
    (PlaylistTrack, $$PlaylistTracksTableReferences),
    PlaylistTrack,
    PrefetchHooks Function({bool playlistId})>;
typedef $$CachedTracksTableCreateCompanionBuilder = CachedTracksCompanion
    Function({
  Value<int> id,
  required String trackId,
  required int source,
  required String trackJson,
  required String filePath,
  required int fileSize,
  required DateTime cachedAt,
});
typedef $$CachedTracksTableUpdateCompanionBuilder = CachedTracksCompanion
    Function({
  Value<int> id,
  Value<String> trackId,
  Value<int> source,
  Value<String> trackJson,
  Value<String> filePath,
  Value<int> fileSize,
  Value<DateTime> cachedAt,
});

class $$CachedTracksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTracksTable> {
  $$CachedTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTracksTable> {
  $$CachedTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackJson => $composableBuilder(
      column: $table.trackJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTracksTable> {
  $$CachedTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get trackJson =>
      $composableBuilder(column: $table.trackJson, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedTracksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedTracksTable,
    CachedTrack,
    $$CachedTracksTableFilterComposer,
    $$CachedTracksTableOrderingComposer,
    $$CachedTracksTableAnnotationComposer,
    $$CachedTracksTableCreateCompanionBuilder,
    $$CachedTracksTableUpdateCompanionBuilder,
    (
      CachedTrack,
      BaseReferences<_$AppDatabase, $CachedTracksTable, CachedTrack>
    ),
    CachedTrack,
    PrefetchHooks Function()> {
  $$CachedTracksTableTableManager(_$AppDatabase db, $CachedTracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> trackId = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<String> trackJson = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<int> fileSize = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              CachedTracksCompanion(
            id: id,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            filePath: filePath,
            fileSize: fileSize,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String trackId,
            required int source,
            required String trackJson,
            required String filePath,
            required int fileSize,
            required DateTime cachedAt,
          }) =>
              CachedTracksCompanion.insert(
            id: id,
            trackId: trackId,
            source: source,
            trackJson: trackJson,
            filePath: filePath,
            fileSize: fileSize,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedTracksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedTracksTable,
    CachedTrack,
    $$CachedTracksTableFilterComposer,
    $$CachedTracksTableOrderingComposer,
    $$CachedTracksTableAnnotationComposer,
    $$CachedTracksTableCreateCompanionBuilder,
    $$CachedTracksTableUpdateCompanionBuilder,
    (
      CachedTrack,
      BaseReferences<_$AppDatabase, $CachedTracksTable, CachedTrack>
    ),
    CachedTrack,
    PrefetchHooks Function()>;
typedef $$PlayCountsTableCreateCompanionBuilder = PlayCountsCompanion Function({
  Value<int> id,
  required String trackId,
  required int source,
  required String artistId,
  Value<String?> genre,
  Value<int> playCount,
  Value<int> skipCount,
  Value<DateTime?> lastPlayedAt,
});
typedef $$PlayCountsTableUpdateCompanionBuilder = PlayCountsCompanion Function({
  Value<int> id,
  Value<String> trackId,
  Value<int> source,
  Value<String> artistId,
  Value<String?> genre,
  Value<int> playCount,
  Value<int> skipCount,
  Value<DateTime?> lastPlayedAt,
});

class $$PlayCountsTableFilterComposer
    extends Composer<_$AppDatabase, $PlayCountsTable> {
  $$PlayCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistId => $composableBuilder(
      column: $table.artistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get skipCount => $composableBuilder(
      column: $table.skipCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));
}

class $$PlayCountsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayCountsTable> {
  $$PlayCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackId => $composableBuilder(
      column: $table.trackId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistId => $composableBuilder(
      column: $table.artistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get skipCount => $composableBuilder(
      column: $table.skipCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$PlayCountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayCountsTable> {
  $$PlayCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<int> get skipCount =>
      $composableBuilder(column: $table.skipCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);
}

class $$PlayCountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayCountsTable,
    PlayCount,
    $$PlayCountsTableFilterComposer,
    $$PlayCountsTableOrderingComposer,
    $$PlayCountsTableAnnotationComposer,
    $$PlayCountsTableCreateCompanionBuilder,
    $$PlayCountsTableUpdateCompanionBuilder,
    (PlayCount, BaseReferences<_$AppDatabase, $PlayCountsTable, PlayCount>),
    PlayCount,
    PrefetchHooks Function()> {
  $$PlayCountsTableTableManager(_$AppDatabase db, $PlayCountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayCountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayCountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> trackId = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<String> artistId = const Value.absent(),
            Value<String?> genre = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<int> skipCount = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
          }) =>
              PlayCountsCompanion(
            id: id,
            trackId: trackId,
            source: source,
            artistId: artistId,
            genre: genre,
            playCount: playCount,
            skipCount: skipCount,
            lastPlayedAt: lastPlayedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String trackId,
            required int source,
            required String artistId,
            Value<String?> genre = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<int> skipCount = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
          }) =>
              PlayCountsCompanion.insert(
            id: id,
            trackId: trackId,
            source: source,
            artistId: artistId,
            genre: genre,
            playCount: playCount,
            skipCount: skipCount,
            lastPlayedAt: lastPlayedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayCountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlayCountsTable,
    PlayCount,
    $$PlayCountsTableFilterComposer,
    $$PlayCountsTableOrderingComposer,
    $$PlayCountsTableAnnotationComposer,
    $$PlayCountsTableCreateCompanionBuilder,
    $$PlayCountsTableUpdateCompanionBuilder,
    (PlayCount, BaseReferences<_$AppDatabase, $PlayCountsTable, PlayCount>),
    PlayCount,
    PrefetchHooks Function()>;
typedef $$GenreFrequencyTableCreateCompanionBuilder = GenreFrequencyCompanion
    Function({
  Value<int> id,
  required String genre,
  Value<int> playCount,
  Value<DateTime?> lastPlayedAt,
});
typedef $$GenreFrequencyTableUpdateCompanionBuilder = GenreFrequencyCompanion
    Function({
  Value<int> id,
  Value<String> genre,
  Value<int> playCount,
  Value<DateTime?> lastPlayedAt,
});

class $$GenreFrequencyTableFilterComposer
    extends Composer<_$AppDatabase, $GenreFrequencyTable> {
  $$GenreFrequencyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));
}

class $$GenreFrequencyTableOrderingComposer
    extends Composer<_$AppDatabase, $GenreFrequencyTable> {
  $$GenreFrequencyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genre => $composableBuilder(
      column: $table.genre, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$GenreFrequencyTableAnnotationComposer
    extends Composer<_$AppDatabase, $GenreFrequencyTable> {
  $$GenreFrequencyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);
}

class $$GenreFrequencyTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GenreFrequencyTable,
    GenreFrequencyData,
    $$GenreFrequencyTableFilterComposer,
    $$GenreFrequencyTableOrderingComposer,
    $$GenreFrequencyTableAnnotationComposer,
    $$GenreFrequencyTableCreateCompanionBuilder,
    $$GenreFrequencyTableUpdateCompanionBuilder,
    (
      GenreFrequencyData,
      BaseReferences<_$AppDatabase, $GenreFrequencyTable, GenreFrequencyData>
    ),
    GenreFrequencyData,
    PrefetchHooks Function()> {
  $$GenreFrequencyTableTableManager(
      _$AppDatabase db, $GenreFrequencyTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenreFrequencyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenreFrequencyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenreFrequencyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> genre = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
          }) =>
              GenreFrequencyCompanion(
            id: id,
            genre: genre,
            playCount: playCount,
            lastPlayedAt: lastPlayedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String genre,
            Value<int> playCount = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
          }) =>
              GenreFrequencyCompanion.insert(
            id: id,
            genre: genre,
            playCount: playCount,
            lastPlayedAt: lastPlayedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GenreFrequencyTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GenreFrequencyTable,
    GenreFrequencyData,
    $$GenreFrequencyTableFilterComposer,
    $$GenreFrequencyTableOrderingComposer,
    $$GenreFrequencyTableAnnotationComposer,
    $$GenreFrequencyTableCreateCompanionBuilder,
    $$GenreFrequencyTableUpdateCompanionBuilder,
    (
      GenreFrequencyData,
      BaseReferences<_$AppDatabase, $GenreFrequencyTable, GenreFrequencyData>
    ),
    GenreFrequencyData,
    PrefetchHooks Function()>;
typedef $$ArtistFrequencyTableCreateCompanionBuilder = ArtistFrequencyCompanion
    Function({
  Value<int> id,
  required String artistId,
  required String artistName,
  Value<int> playCount,
  Value<DateTime?> lastPlayedAt,
});
typedef $$ArtistFrequencyTableUpdateCompanionBuilder = ArtistFrequencyCompanion
    Function({
  Value<int> id,
  Value<String> artistId,
  Value<String> artistName,
  Value<int> playCount,
  Value<DateTime?> lastPlayedAt,
});

class $$ArtistFrequencyTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistFrequencyTable> {
  $$ArtistFrequencyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistId => $composableBuilder(
      column: $table.artistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));
}

class $$ArtistFrequencyTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistFrequencyTable> {
  $$ArtistFrequencyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistId => $composableBuilder(
      column: $table.artistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ArtistFrequencyTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistFrequencyTable> {
  $$ArtistFrequencyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
      column: $table.artistName, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);
}

class $$ArtistFrequencyTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ArtistFrequencyTable,
    ArtistFrequencyData,
    $$ArtistFrequencyTableFilterComposer,
    $$ArtistFrequencyTableOrderingComposer,
    $$ArtistFrequencyTableAnnotationComposer,
    $$ArtistFrequencyTableCreateCompanionBuilder,
    $$ArtistFrequencyTableUpdateCompanionBuilder,
    (
      ArtistFrequencyData,
      BaseReferences<_$AppDatabase, $ArtistFrequencyTable, ArtistFrequencyData>
    ),
    ArtistFrequencyData,
    PrefetchHooks Function()> {
  $$ArtistFrequencyTableTableManager(
      _$AppDatabase db, $ArtistFrequencyTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistFrequencyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistFrequencyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistFrequencyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> artistId = const Value.absent(),
            Value<String> artistName = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
          }) =>
              ArtistFrequencyCompanion(
            id: id,
            artistId: artistId,
            artistName: artistName,
            playCount: playCount,
            lastPlayedAt: lastPlayedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String artistId,
            required String artistName,
            Value<int> playCount = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
          }) =>
              ArtistFrequencyCompanion.insert(
            id: id,
            artistId: artistId,
            artistName: artistName,
            playCount: playCount,
            lastPlayedAt: lastPlayedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ArtistFrequencyTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ArtistFrequencyTable,
    ArtistFrequencyData,
    $$ArtistFrequencyTableFilterComposer,
    $$ArtistFrequencyTableOrderingComposer,
    $$ArtistFrequencyTableAnnotationComposer,
    $$ArtistFrequencyTableCreateCompanionBuilder,
    $$ArtistFrequencyTableUpdateCompanionBuilder,
    (
      ArtistFrequencyData,
      BaseReferences<_$AppDatabase, $ArtistFrequencyTable, ArtistFrequencyData>
    ),
    ArtistFrequencyData,
    PrefetchHooks Function()>;
typedef $$SavedAlbumsTableCreateCompanionBuilder = SavedAlbumsCompanion
    Function({
  Value<int> id,
  required String albumId,
  required int source,
  required String albumJson,
  required DateTime addedAt,
});
typedef $$SavedAlbumsTableUpdateCompanionBuilder = SavedAlbumsCompanion
    Function({
  Value<int> id,
  Value<String> albumId,
  Value<int> source,
  Value<String> albumJson,
  Value<DateTime> addedAt,
});

class $$SavedAlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumJson => $composableBuilder(
      column: $table.albumJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedAlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumJson => $composableBuilder(
      column: $table.albumJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedAlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedAlbumsTable> {
  $$SavedAlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get albumJson =>
      $composableBuilder(column: $table.albumJson, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$SavedAlbumsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavedAlbumsTable,
    SavedAlbum,
    $$SavedAlbumsTableFilterComposer,
    $$SavedAlbumsTableOrderingComposer,
    $$SavedAlbumsTableAnnotationComposer,
    $$SavedAlbumsTableCreateCompanionBuilder,
    $$SavedAlbumsTableUpdateCompanionBuilder,
    (SavedAlbum, BaseReferences<_$AppDatabase, $SavedAlbumsTable, SavedAlbum>),
    SavedAlbum,
    PrefetchHooks Function()> {
  $$SavedAlbumsTableTableManager(_$AppDatabase db, $SavedAlbumsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedAlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedAlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedAlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> albumId = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<String> albumJson = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) =>
              SavedAlbumsCompanion(
            id: id,
            albumId: albumId,
            source: source,
            albumJson: albumJson,
            addedAt: addedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String albumId,
            required int source,
            required String albumJson,
            required DateTime addedAt,
          }) =>
              SavedAlbumsCompanion.insert(
            id: id,
            albumId: albumId,
            source: source,
            albumJson: albumJson,
            addedAt: addedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavedAlbumsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavedAlbumsTable,
    SavedAlbum,
    $$SavedAlbumsTableFilterComposer,
    $$SavedAlbumsTableOrderingComposer,
    $$SavedAlbumsTableAnnotationComposer,
    $$SavedAlbumsTableCreateCompanionBuilder,
    $$SavedAlbumsTableUpdateCompanionBuilder,
    (SavedAlbum, BaseReferences<_$AppDatabase, $SavedAlbumsTable, SavedAlbum>),
    SavedAlbum,
    PrefetchHooks Function()>;
typedef $$SavedPlaylistsTableCreateCompanionBuilder = SavedPlaylistsCompanion
    Function({
  Value<int> id,
  required String playlistId,
  required int source,
  required String playlistJson,
  required DateTime addedAt,
});
typedef $$SavedPlaylistsTableUpdateCompanionBuilder = SavedPlaylistsCompanion
    Function({
  Value<int> id,
  Value<String> playlistId,
  Value<int> source,
  Value<String> playlistJson,
  Value<DateTime> addedAt,
});

class $$SavedPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playlistJson => $composableBuilder(
      column: $table.playlistJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playlistJson => $composableBuilder(
      column: $table.playlistJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedPlaylistsTable> {
  $$SavedPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get playlistId => $composableBuilder(
      column: $table.playlistId, builder: (column) => column);

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get playlistJson => $composableBuilder(
      column: $table.playlistJson, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$SavedPlaylistsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavedPlaylistsTable,
    SavedPlaylist,
    $$SavedPlaylistsTableFilterComposer,
    $$SavedPlaylistsTableOrderingComposer,
    $$SavedPlaylistsTableAnnotationComposer,
    $$SavedPlaylistsTableCreateCompanionBuilder,
    $$SavedPlaylistsTableUpdateCompanionBuilder,
    (
      SavedPlaylist,
      BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>
    ),
    SavedPlaylist,
    PrefetchHooks Function()> {
  $$SavedPlaylistsTableTableManager(
      _$AppDatabase db, $SavedPlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> playlistId = const Value.absent(),
            Value<int> source = const Value.absent(),
            Value<String> playlistJson = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
          }) =>
              SavedPlaylistsCompanion(
            id: id,
            playlistId: playlistId,
            source: source,
            playlistJson: playlistJson,
            addedAt: addedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String playlistId,
            required int source,
            required String playlistJson,
            required DateTime addedAt,
          }) =>
              SavedPlaylistsCompanion.insert(
            id: id,
            playlistId: playlistId,
            source: source,
            playlistJson: playlistJson,
            addedAt: addedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavedPlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavedPlaylistsTable,
    SavedPlaylist,
    $$SavedPlaylistsTableFilterComposer,
    $$SavedPlaylistsTableOrderingComposer,
    $$SavedPlaylistsTableAnnotationComposer,
    $$SavedPlaylistsTableCreateCompanionBuilder,
    $$SavedPlaylistsTableUpdateCompanionBuilder,
    (
      SavedPlaylist,
      BaseReferences<_$AppDatabase, $SavedPlaylistsTable, SavedPlaylist>
    ),
    SavedPlaylist,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HistoryEntriesTableTableManager get historyEntries =>
      $$HistoryEntriesTableTableManager(_db, _db.historyEntries);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$LocalPlaylistsTableTableManager get localPlaylists =>
      $$LocalPlaylistsTableTableManager(_db, _db.localPlaylists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(_db, _db.playlistTracks);
  $$CachedTracksTableTableManager get cachedTracks =>
      $$CachedTracksTableTableManager(_db, _db.cachedTracks);
  $$PlayCountsTableTableManager get playCounts =>
      $$PlayCountsTableTableManager(_db, _db.playCounts);
  $$GenreFrequencyTableTableManager get genreFrequency =>
      $$GenreFrequencyTableTableManager(_db, _db.genreFrequency);
  $$ArtistFrequencyTableTableManager get artistFrequency =>
      $$ArtistFrequencyTableTableManager(_db, _db.artistFrequency);
  $$SavedAlbumsTableTableManager get savedAlbums =>
      $$SavedAlbumsTableTableManager(_db, _db.savedAlbums);
  $$SavedPlaylistsTableTableManager get savedPlaylists =>
      $$SavedPlaylistsTableTableManager(_db, _db.savedPlaylists);
}
