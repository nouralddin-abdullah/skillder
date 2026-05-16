// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChatsTable extends Chats with TableInfo<$ChatsTable, Chat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _otherUserIdMeta = const VerificationMeta(
    'otherUserId',
  );
  @override
  late final GeneratedColumn<String> otherUserId = GeneratedColumn<String>(
    'other_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _otherUserNameMeta = const VerificationMeta(
    'otherUserName',
  );
  @override
  late final GeneratedColumn<String> otherUserName = GeneratedColumn<String>(
    'other_user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _otherUserPhotoUrlMeta = const VerificationMeta(
    'otherUserPhotoUrl',
  );
  @override
  late final GeneratedColumn<String> otherUserPhotoUrl =
      GeneratedColumn<String>(
        'other_user_photo_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _otherUserLastReadAtMeta =
      const VerificationMeta('otherUserLastReadAt');
  @override
  late final GeneratedColumn<DateTime> otherUserLastReadAt =
      GeneratedColumn<DateTime>(
        'other_user_last_read_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _removedByMeMeta = const VerificationMeta(
    'removedByMe',
  );
  @override
  late final GeneratedColumn<bool> removedByMe = GeneratedColumn<bool>(
    'removed_by_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("removed_by_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastMessageIdMeta = const VerificationMeta(
    'lastMessageId',
  );
  @override
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
    'last_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageAt =
      GeneratedColumn<DateTime>(
        'last_message_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    chatId,
    matchId,
    otherUserId,
    otherUserName,
    otherUserPhotoUrl,
    unreadCount,
    lastReadAt,
    otherUserLastReadAt,
    removedByMe,
    lastMessageId,
    lastMessageAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('other_user_id')) {
      context.handle(
        _otherUserIdMeta,
        otherUserId.isAcceptableOrUnknown(
          data['other_user_id']!,
          _otherUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_otherUserIdMeta);
    }
    if (data.containsKey('other_user_name')) {
      context.handle(
        _otherUserNameMeta,
        otherUserName.isAcceptableOrUnknown(
          data['other_user_name']!,
          _otherUserNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_otherUserNameMeta);
    }
    if (data.containsKey('other_user_photo_url')) {
      context.handle(
        _otherUserPhotoUrlMeta,
        otherUserPhotoUrl.isAcceptableOrUnknown(
          data['other_user_photo_url']!,
          _otherUserPhotoUrlMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('other_user_last_read_at')) {
      context.handle(
        _otherUserLastReadAtMeta,
        otherUserLastReadAt.isAcceptableOrUnknown(
          data['other_user_last_read_at']!,
          _otherUserLastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('removed_by_me')) {
      context.handle(
        _removedByMeMeta,
        removedByMe.isAcceptableOrUnknown(
          data['removed_by_me']!,
          _removedByMeMeta,
        ),
      );
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
        _lastMessageIdMeta,
        lastMessageId.isAcceptableOrUnknown(
          data['last_message_id']!,
          _lastMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId};
  @override
  Chat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chat(
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      otherUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_id'],
      )!,
      otherUserName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_name'],
      )!,
      otherUserPhotoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_photo_url'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      ),
      otherUserLastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}other_user_last_read_at'],
      ),
      removedByMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}removed_by_me'],
      )!,
      lastMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_id'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class Chat extends DataClass implements Insertable<Chat> {
  final String chatId;
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final int unreadCount;
  final DateTime? lastReadAt;

  /// The other party's last-read timestamp, learned via `message.read`
  /// events. Drives the ✓ vs ✓✓ render on outgoing messages. Null until
  /// the first `message.read` event arrives for this chat from the peer.
  final DateTime? otherUserLastReadAt;
  final bool removedByMe;

  /// FK to [Messages.id] — denormalized for cheap chat-list ordering.
  final String? lastMessageId;
  final DateTime? lastMessageAt;

  /// When this row was last touched locally — used as the chat-list sort
  /// fallback for chats that have no messages yet.
  final DateTime updatedAt;
  const Chat({
    required this.chatId,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.unreadCount,
    this.lastReadAt,
    this.otherUserLastReadAt,
    required this.removedByMe,
    this.lastMessageId,
    this.lastMessageAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['match_id'] = Variable<String>(matchId);
    map['other_user_id'] = Variable<String>(otherUserId);
    map['other_user_name'] = Variable<String>(otherUserName);
    if (!nullToAbsent || otherUserPhotoUrl != null) {
      map['other_user_photo_url'] = Variable<String>(otherUserPhotoUrl);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt);
    }
    if (!nullToAbsent || otherUserLastReadAt != null) {
      map['other_user_last_read_at'] = Variable<DateTime>(otherUserLastReadAt);
    }
    map['removed_by_me'] = Variable<bool>(removedByMe);
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      chatId: Value(chatId),
      matchId: Value(matchId),
      otherUserId: Value(otherUserId),
      otherUserName: Value(otherUserName),
      otherUserPhotoUrl: otherUserPhotoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserPhotoUrl),
      unreadCount: Value(unreadCount),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      otherUserLastReadAt: otherUserLastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserLastReadAt),
      removedByMe: Value(removedByMe),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chat(
      chatId: serializer.fromJson<String>(json['chatId']),
      matchId: serializer.fromJson<String>(json['matchId']),
      otherUserId: serializer.fromJson<String>(json['otherUserId']),
      otherUserName: serializer.fromJson<String>(json['otherUserName']),
      otherUserPhotoUrl: serializer.fromJson<String?>(
        json['otherUserPhotoUrl'],
      ),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      lastReadAt: serializer.fromJson<DateTime?>(json['lastReadAt']),
      otherUserLastReadAt: serializer.fromJson<DateTime?>(
        json['otherUserLastReadAt'],
      ),
      removedByMe: serializer.fromJson<bool>(json['removedByMe']),
      lastMessageId: serializer.fromJson<String?>(json['lastMessageId']),
      lastMessageAt: serializer.fromJson<DateTime?>(json['lastMessageAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'matchId': serializer.toJson<String>(matchId),
      'otherUserId': serializer.toJson<String>(otherUserId),
      'otherUserName': serializer.toJson<String>(otherUserName),
      'otherUserPhotoUrl': serializer.toJson<String?>(otherUserPhotoUrl),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'lastReadAt': serializer.toJson<DateTime?>(lastReadAt),
      'otherUserLastReadAt': serializer.toJson<DateTime?>(otherUserLastReadAt),
      'removedByMe': serializer.toJson<bool>(removedByMe),
      'lastMessageId': serializer.toJson<String?>(lastMessageId),
      'lastMessageAt': serializer.toJson<DateTime?>(lastMessageAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chat copyWith({
    String? chatId,
    String? matchId,
    String? otherUserId,
    String? otherUserName,
    Value<String?> otherUserPhotoUrl = const Value.absent(),
    int? unreadCount,
    Value<DateTime?> lastReadAt = const Value.absent(),
    Value<DateTime?> otherUserLastReadAt = const Value.absent(),
    bool? removedByMe,
    Value<String?> lastMessageId = const Value.absent(),
    Value<DateTime?> lastMessageAt = const Value.absent(),
    DateTime? updatedAt,
  }) => Chat(
    chatId: chatId ?? this.chatId,
    matchId: matchId ?? this.matchId,
    otherUserId: otherUserId ?? this.otherUserId,
    otherUserName: otherUserName ?? this.otherUserName,
    otherUserPhotoUrl: otherUserPhotoUrl.present
        ? otherUserPhotoUrl.value
        : this.otherUserPhotoUrl,
    unreadCount: unreadCount ?? this.unreadCount,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    otherUserLastReadAt: otherUserLastReadAt.present
        ? otherUserLastReadAt.value
        : this.otherUserLastReadAt,
    removedByMe: removedByMe ?? this.removedByMe,
    lastMessageId: lastMessageId.present
        ? lastMessageId.value
        : this.lastMessageId,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Chat copyWithCompanion(ChatsCompanion data) {
    return Chat(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      otherUserId: data.otherUserId.present
          ? data.otherUserId.value
          : this.otherUserId,
      otherUserName: data.otherUserName.present
          ? data.otherUserName.value
          : this.otherUserName,
      otherUserPhotoUrl: data.otherUserPhotoUrl.present
          ? data.otherUserPhotoUrl.value
          : this.otherUserPhotoUrl,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      otherUserLastReadAt: data.otherUserLastReadAt.present
          ? data.otherUserLastReadAt.value
          : this.otherUserLastReadAt,
      removedByMe: data.removedByMe.present
          ? data.removedByMe.value
          : this.removedByMe,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chat(')
          ..write('chatId: $chatId, ')
          ..write('matchId: $matchId, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('otherUserName: $otherUserName, ')
          ..write('otherUserPhotoUrl: $otherUserPhotoUrl, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('otherUserLastReadAt: $otherUserLastReadAt, ')
          ..write('removedByMe: $removedByMe, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    chatId,
    matchId,
    otherUserId,
    otherUserName,
    otherUserPhotoUrl,
    unreadCount,
    lastReadAt,
    otherUserLastReadAt,
    removedByMe,
    lastMessageId,
    lastMessageAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chat &&
          other.chatId == this.chatId &&
          other.matchId == this.matchId &&
          other.otherUserId == this.otherUserId &&
          other.otherUserName == this.otherUserName &&
          other.otherUserPhotoUrl == this.otherUserPhotoUrl &&
          other.unreadCount == this.unreadCount &&
          other.lastReadAt == this.lastReadAt &&
          other.otherUserLastReadAt == this.otherUserLastReadAt &&
          other.removedByMe == this.removedByMe &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessageAt == this.lastMessageAt &&
          other.updatedAt == this.updatedAt);
}

class ChatsCompanion extends UpdateCompanion<Chat> {
  final Value<String> chatId;
  final Value<String> matchId;
  final Value<String> otherUserId;
  final Value<String> otherUserName;
  final Value<String?> otherUserPhotoUrl;
  final Value<int> unreadCount;
  final Value<DateTime?> lastReadAt;
  final Value<DateTime?> otherUserLastReadAt;
  final Value<bool> removedByMe;
  final Value<String?> lastMessageId;
  final Value<DateTime?> lastMessageAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChatsCompanion({
    this.chatId = const Value.absent(),
    this.matchId = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.otherUserName = const Value.absent(),
    this.otherUserPhotoUrl = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.otherUserLastReadAt = const Value.absent(),
    this.removedByMe = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatsCompanion.insert({
    required String chatId,
    required String matchId,
    required String otherUserId,
    required String otherUserName,
    this.otherUserPhotoUrl = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.otherUserLastReadAt = const Value.absent(),
    this.removedByMe = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : chatId = Value(chatId),
       matchId = Value(matchId),
       otherUserId = Value(otherUserId),
       otherUserName = Value(otherUserName),
       updatedAt = Value(updatedAt);
  static Insertable<Chat> custom({
    Expression<String>? chatId,
    Expression<String>? matchId,
    Expression<String>? otherUserId,
    Expression<String>? otherUserName,
    Expression<String>? otherUserPhotoUrl,
    Expression<int>? unreadCount,
    Expression<DateTime>? lastReadAt,
    Expression<DateTime>? otherUserLastReadAt,
    Expression<bool>? removedByMe,
    Expression<String>? lastMessageId,
    Expression<DateTime>? lastMessageAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (matchId != null) 'match_id': matchId,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (otherUserName != null) 'other_user_name': otherUserName,
      if (otherUserPhotoUrl != null) 'other_user_photo_url': otherUserPhotoUrl,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (otherUserLastReadAt != null)
        'other_user_last_read_at': otherUserLastReadAt,
      if (removedByMe != null) 'removed_by_me': removedByMe,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatsCompanion copyWith({
    Value<String>? chatId,
    Value<String>? matchId,
    Value<String>? otherUserId,
    Value<String>? otherUserName,
    Value<String?>? otherUserPhotoUrl,
    Value<int>? unreadCount,
    Value<DateTime?>? lastReadAt,
    Value<DateTime?>? otherUserLastReadAt,
    Value<bool>? removedByMe,
    Value<String?>? lastMessageId,
    Value<DateTime?>? lastMessageAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChatsCompanion(
      chatId: chatId ?? this.chatId,
      matchId: matchId ?? this.matchId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      otherUserLastReadAt: otherUserLastReadAt ?? this.otherUserLastReadAt,
      removedByMe: removedByMe ?? this.removedByMe,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (otherUserId.present) {
      map['other_user_id'] = Variable<String>(otherUserId.value);
    }
    if (otherUserName.present) {
      map['other_user_name'] = Variable<String>(otherUserName.value);
    }
    if (otherUserPhotoUrl.present) {
      map['other_user_photo_url'] = Variable<String>(otherUserPhotoUrl.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    if (otherUserLastReadAt.present) {
      map['other_user_last_read_at'] = Variable<DateTime>(
        otherUserLastReadAt.value,
      );
    }
    if (removedByMe.present) {
      map['removed_by_me'] = Variable<bool>(removedByMe.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<DateTime>(lastMessageAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('matchId: $matchId, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('otherUserName: $otherUserName, ')
          ..write('otherUserPhotoUrl: $otherUserPhotoUrl, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('otherUserLastReadAt: $otherUserLastReadAt, ')
          ..write('removedByMe: $removedByMe, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaThumbnailUrlMeta = const VerificationMeta(
    'mediaThumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> mediaThumbnailUrl =
      GeneratedColumn<String>(
        'media_thumbnail_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mediaCaptionMeta = const VerificationMeta(
    'mediaCaption',
  );
  @override
  late final GeneratedColumn<String> mediaCaption = GeneratedColumn<String>(
    'media_caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaWidthMeta = const VerificationMeta(
    'mediaWidth',
  );
  @override
  late final GeneratedColumn<int> mediaWidth = GeneratedColumn<int>(
    'media_width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaHeightMeta = const VerificationMeta(
    'mediaHeight',
  );
  @override
  late final GeneratedColumn<int> mediaHeight = GeneratedColumn<int>(
    'media_height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaDurationSecondsMeta =
      const VerificationMeta('mediaDurationSeconds');
  @override
  late final GeneratedColumn<int> mediaDurationSeconds = GeneratedColumn<int>(
    'media_duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToIdMeta = const VerificationMeta(
    'replyToId',
  );
  @override
  late final GeneratedColumn<String> replyToId = GeneratedColumn<String>(
    'reply_to_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sent'),
  );
  static const VerificationMeta _systemPayloadMeta = const VerificationMeta(
    'systemPayload',
  );
  @override
  late final GeneratedColumn<String> systemPayload = GeneratedColumn<String>(
    'system_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    id,
    clientId,
    chatId,
    senderId,
    kind,
    body,
    mediaUrl,
    mediaThumbnailUrl,
    mediaCaption,
    mediaWidth,
    mediaHeight,
    mediaDurationSeconds,
    replyToId,
    editedAt,
    deletedAt,
    createdAt,
    status,
    systemPayload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    }
    if (data.containsKey('media_thumbnail_url')) {
      context.handle(
        _mediaThumbnailUrlMeta,
        mediaThumbnailUrl.isAcceptableOrUnknown(
          data['media_thumbnail_url']!,
          _mediaThumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('media_caption')) {
      context.handle(
        _mediaCaptionMeta,
        mediaCaption.isAcceptableOrUnknown(
          data['media_caption']!,
          _mediaCaptionMeta,
        ),
      );
    }
    if (data.containsKey('media_width')) {
      context.handle(
        _mediaWidthMeta,
        mediaWidth.isAcceptableOrUnknown(data['media_width']!, _mediaWidthMeta),
      );
    }
    if (data.containsKey('media_height')) {
      context.handle(
        _mediaHeightMeta,
        mediaHeight.isAcceptableOrUnknown(
          data['media_height']!,
          _mediaHeightMeta,
        ),
      );
    }
    if (data.containsKey('media_duration_seconds')) {
      context.handle(
        _mediaDurationSecondsMeta,
        mediaDurationSeconds.isAcceptableOrUnknown(
          data['media_duration_seconds']!,
          _mediaDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_id')) {
      context.handle(
        _replyToIdMeta,
        replyToId.isAcceptableOrUnknown(data['reply_to_id']!, _replyToIdMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('system_payload')) {
      context.handle(
        _systemPayloadMeta,
        systemPayload.isAcceptableOrUnknown(
          data['system_payload']!,
          _systemPayloadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      ),
      mediaThumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_thumbnail_url'],
      ),
      mediaCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_caption'],
      ),
      mediaWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_width'],
      ),
      mediaHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_height'],
      ),
      mediaDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_duration_seconds'],
      ),
      replyToId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_id'],
      ),
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}edited_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      systemPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_payload'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int rowId;

  /// Server-assigned UUID. Null while a send is in flight.
  final String? id;

  /// Client-generated UUID. Always set, unique across the table — backend
  /// enforces the same uniqueness for idempotent retries.
  final String clientId;
  final String chatId;

  /// Null for system messages.
  final String? senderId;

  /// 'text' | 'image' | 'system'
  final String kind;
  final String? body;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaCaption;
  final int? mediaWidth;
  final int? mediaHeight;
  final int? mediaDurationSeconds;
  final String? replyToId;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;

  /// 'sending' | 'sent' | 'failed' — local UI lifecycle.
  final String status;

  /// JSON-encoded `system_payload` from the backend (only set on system-kind
  /// messages — call records, future system events). Stored as TEXT because
  /// SQLite has no native JSONB type; consumers parse on read. Body remains
  /// the human-readable fallback for old rows + downlevel renderers.
  final String? systemPayload;
  const Message({
    required this.rowId,
    this.id,
    required this.clientId,
    required this.chatId,
    this.senderId,
    required this.kind,
    this.body,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaCaption,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaDurationSeconds,
    this.replyToId,
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
    required this.status,
    this.systemPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['client_id'] = Variable<String>(clientId);
    map['chat_id'] = Variable<String>(chatId);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<String>(senderId);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || mediaThumbnailUrl != null) {
      map['media_thumbnail_url'] = Variable<String>(mediaThumbnailUrl);
    }
    if (!nullToAbsent || mediaCaption != null) {
      map['media_caption'] = Variable<String>(mediaCaption);
    }
    if (!nullToAbsent || mediaWidth != null) {
      map['media_width'] = Variable<int>(mediaWidth);
    }
    if (!nullToAbsent || mediaHeight != null) {
      map['media_height'] = Variable<int>(mediaHeight);
    }
    if (!nullToAbsent || mediaDurationSeconds != null) {
      map['media_duration_seconds'] = Variable<int>(mediaDurationSeconds);
    }
    if (!nullToAbsent || replyToId != null) {
      map['reply_to_id'] = Variable<String>(replyToId);
    }
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || systemPayload != null) {
      map['system_payload'] = Variable<String>(systemPayload);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      rowId: Value(rowId),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      clientId: Value(clientId),
      chatId: Value(chatId),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      kind: Value(kind),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      mediaThumbnailUrl: mediaThumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaThumbnailUrl),
      mediaCaption: mediaCaption == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaCaption),
      mediaWidth: mediaWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaWidth),
      mediaHeight: mediaHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaHeight),
      mediaDurationSeconds: mediaDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaDurationSeconds),
      replyToId: replyToId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToId),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      status: Value(status),
      systemPayload: systemPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(systemPayload),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      rowId: serializer.fromJson<int>(json['rowId']),
      id: serializer.fromJson<String?>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      chatId: serializer.fromJson<String>(json['chatId']),
      senderId: serializer.fromJson<String?>(json['senderId']),
      kind: serializer.fromJson<String>(json['kind']),
      body: serializer.fromJson<String?>(json['body']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      mediaThumbnailUrl: serializer.fromJson<String?>(
        json['mediaThumbnailUrl'],
      ),
      mediaCaption: serializer.fromJson<String?>(json['mediaCaption']),
      mediaWidth: serializer.fromJson<int?>(json['mediaWidth']),
      mediaHeight: serializer.fromJson<int?>(json['mediaHeight']),
      mediaDurationSeconds: serializer.fromJson<int?>(
        json['mediaDurationSeconds'],
      ),
      replyToId: serializer.fromJson<String?>(json['replyToId']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      systemPayload: serializer.fromJson<String?>(json['systemPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'id': serializer.toJson<String?>(id),
      'clientId': serializer.toJson<String>(clientId),
      'chatId': serializer.toJson<String>(chatId),
      'senderId': serializer.toJson<String?>(senderId),
      'kind': serializer.toJson<String>(kind),
      'body': serializer.toJson<String?>(body),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'mediaThumbnailUrl': serializer.toJson<String?>(mediaThumbnailUrl),
      'mediaCaption': serializer.toJson<String?>(mediaCaption),
      'mediaWidth': serializer.toJson<int?>(mediaWidth),
      'mediaHeight': serializer.toJson<int?>(mediaHeight),
      'mediaDurationSeconds': serializer.toJson<int?>(mediaDurationSeconds),
      'replyToId': serializer.toJson<String?>(replyToId),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'systemPayload': serializer.toJson<String?>(systemPayload),
    };
  }

  Message copyWith({
    int? rowId,
    Value<String?> id = const Value.absent(),
    String? clientId,
    String? chatId,
    Value<String?> senderId = const Value.absent(),
    String? kind,
    Value<String?> body = const Value.absent(),
    Value<String?> mediaUrl = const Value.absent(),
    Value<String?> mediaThumbnailUrl = const Value.absent(),
    Value<String?> mediaCaption = const Value.absent(),
    Value<int?> mediaWidth = const Value.absent(),
    Value<int?> mediaHeight = const Value.absent(),
    Value<int?> mediaDurationSeconds = const Value.absent(),
    Value<String?> replyToId = const Value.absent(),
    Value<DateTime?> editedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    String? status,
    Value<String?> systemPayload = const Value.absent(),
  }) => Message(
    rowId: rowId ?? this.rowId,
    id: id.present ? id.value : this.id,
    clientId: clientId ?? this.clientId,
    chatId: chatId ?? this.chatId,
    senderId: senderId.present ? senderId.value : this.senderId,
    kind: kind ?? this.kind,
    body: body.present ? body.value : this.body,
    mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
    mediaThumbnailUrl: mediaThumbnailUrl.present
        ? mediaThumbnailUrl.value
        : this.mediaThumbnailUrl,
    mediaCaption: mediaCaption.present ? mediaCaption.value : this.mediaCaption,
    mediaWidth: mediaWidth.present ? mediaWidth.value : this.mediaWidth,
    mediaHeight: mediaHeight.present ? mediaHeight.value : this.mediaHeight,
    mediaDurationSeconds: mediaDurationSeconds.present
        ? mediaDurationSeconds.value
        : this.mediaDurationSeconds,
    replyToId: replyToId.present ? replyToId.value : this.replyToId,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    systemPayload: systemPayload.present
        ? systemPayload.value
        : this.systemPayload,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      kind: data.kind.present ? data.kind.value : this.kind,
      body: data.body.present ? data.body.value : this.body,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      mediaThumbnailUrl: data.mediaThumbnailUrl.present
          ? data.mediaThumbnailUrl.value
          : this.mediaThumbnailUrl,
      mediaCaption: data.mediaCaption.present
          ? data.mediaCaption.value
          : this.mediaCaption,
      mediaWidth: data.mediaWidth.present
          ? data.mediaWidth.value
          : this.mediaWidth,
      mediaHeight: data.mediaHeight.present
          ? data.mediaHeight.value
          : this.mediaHeight,
      mediaDurationSeconds: data.mediaDurationSeconds.present
          ? data.mediaDurationSeconds.value
          : this.mediaDurationSeconds,
      replyToId: data.replyToId.present ? data.replyToId.value : this.replyToId,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      systemPayload: data.systemPayload.present
          ? data.systemPayload.value
          : this.systemPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('rowId: $rowId, ')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaThumbnailUrl: $mediaThumbnailUrl, ')
          ..write('mediaCaption: $mediaCaption, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaDurationSeconds: $mediaDurationSeconds, ')
          ..write('replyToId: $replyToId, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('systemPayload: $systemPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    id,
    clientId,
    chatId,
    senderId,
    kind,
    body,
    mediaUrl,
    mediaThumbnailUrl,
    mediaCaption,
    mediaWidth,
    mediaHeight,
    mediaDurationSeconds,
    replyToId,
    editedAt,
    deletedAt,
    createdAt,
    status,
    systemPayload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.rowId == this.rowId &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.chatId == this.chatId &&
          other.senderId == this.senderId &&
          other.kind == this.kind &&
          other.body == this.body &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaThumbnailUrl == this.mediaThumbnailUrl &&
          other.mediaCaption == this.mediaCaption &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.mediaDurationSeconds == this.mediaDurationSeconds &&
          other.replyToId == this.replyToId &&
          other.editedAt == this.editedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.systemPayload == this.systemPayload);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> rowId;
  final Value<String?> id;
  final Value<String> clientId;
  final Value<String> chatId;
  final Value<String?> senderId;
  final Value<String> kind;
  final Value<String?> body;
  final Value<String?> mediaUrl;
  final Value<String?> mediaThumbnailUrl;
  final Value<String?> mediaCaption;
  final Value<int?> mediaWidth;
  final Value<int?> mediaHeight;
  final Value<int?> mediaDurationSeconds;
  final Value<String?> replyToId;
  final Value<DateTime?> editedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<String?> systemPayload;
  const MessagesCompanion({
    this.rowId = const Value.absent(),
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.kind = const Value.absent(),
    this.body = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaThumbnailUrl = const Value.absent(),
    this.mediaCaption = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaDurationSeconds = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.systemPayload = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.rowId = const Value.absent(),
    this.id = const Value.absent(),
    required String clientId,
    required String chatId,
    this.senderId = const Value.absent(),
    required String kind,
    this.body = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaThumbnailUrl = const Value.absent(),
    this.mediaCaption = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaDurationSeconds = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required DateTime createdAt,
    this.status = const Value.absent(),
    this.systemPayload = const Value.absent(),
  }) : clientId = Value(clientId),
       chatId = Value(chatId),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<int>? rowId,
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<String>? chatId,
    Expression<String>? senderId,
    Expression<String>? kind,
    Expression<String>? body,
    Expression<String>? mediaUrl,
    Expression<String>? mediaThumbnailUrl,
    Expression<String>? mediaCaption,
    Expression<int>? mediaWidth,
    Expression<int>? mediaHeight,
    Expression<int>? mediaDurationSeconds,
    Expression<String>? replyToId,
    Expression<DateTime>? editedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<String>? systemPayload,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (chatId != null) 'chat_id': chatId,
      if (senderId != null) 'sender_id': senderId,
      if (kind != null) 'kind': kind,
      if (body != null) 'body': body,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaThumbnailUrl != null) 'media_thumbnail_url': mediaThumbnailUrl,
      if (mediaCaption != null) 'media_caption': mediaCaption,
      if (mediaWidth != null) 'media_width': mediaWidth,
      if (mediaHeight != null) 'media_height': mediaHeight,
      if (mediaDurationSeconds != null)
        'media_duration_seconds': mediaDurationSeconds,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (editedAt != null) 'edited_at': editedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (systemPayload != null) 'system_payload': systemPayload,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? rowId,
    Value<String?>? id,
    Value<String>? clientId,
    Value<String>? chatId,
    Value<String?>? senderId,
    Value<String>? kind,
    Value<String?>? body,
    Value<String?>? mediaUrl,
    Value<String?>? mediaThumbnailUrl,
    Value<String?>? mediaCaption,
    Value<int?>? mediaWidth,
    Value<int?>? mediaHeight,
    Value<int?>? mediaDurationSeconds,
    Value<String?>? replyToId,
    Value<DateTime?>? editedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<String?>? systemPayload,
  }) {
    return MessagesCompanion(
      rowId: rowId ?? this.rowId,
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaCaption: mediaCaption ?? this.mediaCaption,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      mediaDurationSeconds: mediaDurationSeconds ?? this.mediaDurationSeconds,
      replyToId: replyToId ?? this.replyToId,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      systemPayload: systemPayload ?? this.systemPayload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaThumbnailUrl.present) {
      map['media_thumbnail_url'] = Variable<String>(mediaThumbnailUrl.value);
    }
    if (mediaCaption.present) {
      map['media_caption'] = Variable<String>(mediaCaption.value);
    }
    if (mediaWidth.present) {
      map['media_width'] = Variable<int>(mediaWidth.value);
    }
    if (mediaHeight.present) {
      map['media_height'] = Variable<int>(mediaHeight.value);
    }
    if (mediaDurationSeconds.present) {
      map['media_duration_seconds'] = Variable<int>(mediaDurationSeconds.value);
    }
    if (replyToId.present) {
      map['reply_to_id'] = Variable<String>(replyToId.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (systemPayload.present) {
      map['system_payload'] = Variable<String>(systemPayload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('rowId: $rowId, ')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('chatId: $chatId, ')
          ..write('senderId: $senderId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaThumbnailUrl: $mediaThumbnailUrl, ')
          ..write('mediaCaption: $mediaCaption, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaDurationSeconds: $mediaDurationSeconds, ')
          ..write('replyToId: $replyToId, ')
          ..write('editedAt: $editedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('systemPayload: $systemPayload')
          ..write(')'))
        .toString();
  }
}

class $SyncStateRowsTable extends SyncStateRows
    with TableInfo<$SyncStateRowsTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, cursor, lastSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $SyncStateRowsTable createAlias(String alias) {
    return $SyncStateRowsTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String key;
  final String? cursor;
  final DateTime? lastSyncAt;
  const SyncStateRow({required this.key, this.cursor, this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  SyncStateRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncStateRowsCompanion(
      key: Value(key),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      key: serializer.fromJson<String>(json['key']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'cursor': serializer.toJson<String?>(cursor),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  SyncStateRow copyWith({
    String? key,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => SyncStateRow(
    key: key ?? this.key,
    cursor: cursor.present ? cursor.value : this.cursor,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  SyncStateRow copyWithCompanion(SyncStateRowsCompanion data) {
    return SyncStateRow(
      key: data.key.present ? data.key.value : this.key,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('key: $key, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, cursor, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.key == this.key &&
          other.cursor == this.cursor &&
          other.lastSyncAt == this.lastSyncAt);
}

class SyncStateRowsCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> key;
  final Value<String?> cursor;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const SyncStateRowsCompanion({
    this.key = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateRowsCompanion.insert({
    required String key,
    this.cursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SyncStateRow> custom({
    Expression<String>? key,
    Expression<String>? cursor,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (cursor != null) 'cursor': cursor,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateRowsCompanion copyWith({
    Value<String>? key,
    Value<String?>? cursor,
    Value<DateTime?>? lastSyncAt,
    Value<int>? rowid,
  }) {
    return SyncStateRowsCompanion(
      key: key ?? this.key,
      cursor: cursor ?? this.cursor,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRowsCompanion(')
          ..write('key: $key, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxRowsTable extends OutboxRows
    with TableInfo<$OutboxRowsTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaThumbnailUrlMeta = const VerificationMeta(
    'mediaThumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> mediaThumbnailUrl =
      GeneratedColumn<String>(
        'media_thumbnail_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mediaCaptionMeta = const VerificationMeta(
    'mediaCaption',
  );
  @override
  late final GeneratedColumn<String> mediaCaption = GeneratedColumn<String>(
    'media_caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaLocalPathMeta = const VerificationMeta(
    'mediaLocalPath',
  );
  @override
  late final GeneratedColumn<String> mediaLocalPath = GeneratedColumn<String>(
    'media_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaLocalBytesMeta = const VerificationMeta(
    'mediaLocalBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> mediaLocalBytes =
      GeneratedColumn<Uint8List>(
        'media_local_bytes',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mediaThumbnailLocalBytesMeta =
      const VerificationMeta('mediaThumbnailLocalBytes');
  @override
  late final GeneratedColumn<Uint8List> mediaThumbnailLocalBytes =
      GeneratedColumn<Uint8List>(
        'media_thumbnail_local_bytes',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _mediaFilenameMeta = const VerificationMeta(
    'mediaFilename',
  );
  @override
  late final GeneratedColumn<String> mediaFilename = GeneratedColumn<String>(
    'media_filename',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaContentTypeMeta = const VerificationMeta(
    'mediaContentType',
  );
  @override
  late final GeneratedColumn<String> mediaContentType = GeneratedColumn<String>(
    'media_content_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaWidthMeta = const VerificationMeta(
    'mediaWidth',
  );
  @override
  late final GeneratedColumn<int> mediaWidth = GeneratedColumn<int>(
    'media_width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaHeightMeta = const VerificationMeta(
    'mediaHeight',
  );
  @override
  late final GeneratedColumn<int> mediaHeight = GeneratedColumn<int>(
    'media_height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaDurationSecondsMeta =
      const VerificationMeta('mediaDurationSeconds');
  @override
  late final GeneratedColumn<int> mediaDurationSeconds = GeneratedColumn<int>(
    'media_duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToIdMeta = const VerificationMeta(
    'replyToId',
  );
  @override
  late final GeneratedColumn<String> replyToId = GeneratedColumn<String>(
    'reply_to_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    clientId,
    chatId,
    kind,
    body,
    mediaUrl,
    mediaThumbnailUrl,
    mediaCaption,
    mediaLocalPath,
    mediaLocalBytes,
    mediaThumbnailLocalBytes,
    mediaFilename,
    mediaContentType,
    mediaWidth,
    mediaHeight,
    mediaDurationSeconds,
    replyToId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    }
    if (data.containsKey('media_thumbnail_url')) {
      context.handle(
        _mediaThumbnailUrlMeta,
        mediaThumbnailUrl.isAcceptableOrUnknown(
          data['media_thumbnail_url']!,
          _mediaThumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('media_caption')) {
      context.handle(
        _mediaCaptionMeta,
        mediaCaption.isAcceptableOrUnknown(
          data['media_caption']!,
          _mediaCaptionMeta,
        ),
      );
    }
    if (data.containsKey('media_local_path')) {
      context.handle(
        _mediaLocalPathMeta,
        mediaLocalPath.isAcceptableOrUnknown(
          data['media_local_path']!,
          _mediaLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('media_local_bytes')) {
      context.handle(
        _mediaLocalBytesMeta,
        mediaLocalBytes.isAcceptableOrUnknown(
          data['media_local_bytes']!,
          _mediaLocalBytesMeta,
        ),
      );
    }
    if (data.containsKey('media_thumbnail_local_bytes')) {
      context.handle(
        _mediaThumbnailLocalBytesMeta,
        mediaThumbnailLocalBytes.isAcceptableOrUnknown(
          data['media_thumbnail_local_bytes']!,
          _mediaThumbnailLocalBytesMeta,
        ),
      );
    }
    if (data.containsKey('media_filename')) {
      context.handle(
        _mediaFilenameMeta,
        mediaFilename.isAcceptableOrUnknown(
          data['media_filename']!,
          _mediaFilenameMeta,
        ),
      );
    }
    if (data.containsKey('media_content_type')) {
      context.handle(
        _mediaContentTypeMeta,
        mediaContentType.isAcceptableOrUnknown(
          data['media_content_type']!,
          _mediaContentTypeMeta,
        ),
      );
    }
    if (data.containsKey('media_width')) {
      context.handle(
        _mediaWidthMeta,
        mediaWidth.isAcceptableOrUnknown(data['media_width']!, _mediaWidthMeta),
      );
    }
    if (data.containsKey('media_height')) {
      context.handle(
        _mediaHeightMeta,
        mediaHeight.isAcceptableOrUnknown(
          data['media_height']!,
          _mediaHeightMeta,
        ),
      );
    }
    if (data.containsKey('media_duration_seconds')) {
      context.handle(
        _mediaDurationSecondsMeta,
        mediaDurationSeconds.isAcceptableOrUnknown(
          data['media_duration_seconds']!,
          _mediaDurationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_id')) {
      context.handle(
        _replyToIdMeta,
        replyToId.isAcceptableOrUnknown(data['reply_to_id']!, _replyToIdMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      ),
      mediaThumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_thumbnail_url'],
      ),
      mediaCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_caption'],
      ),
      mediaLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_local_path'],
      ),
      mediaLocalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}media_local_bytes'],
      ),
      mediaThumbnailLocalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}media_thumbnail_local_bytes'],
      ),
      mediaFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_filename'],
      ),
      mediaContentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_content_type'],
      ),
      mediaWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_width'],
      ),
      mediaHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_height'],
      ),
      mediaDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_duration_seconds'],
      ),
      replyToId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_id'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxRowsTable createAlias(String alias) {
    return $OutboxRowsTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int rowId;
  final String clientId;
  final String chatId;
  final String kind;
  final String? body;

  /// Set after the media upload step succeeds; while null + bytes/path are
  /// set, the upload still needs to happen.
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaCaption;
  final String? mediaLocalPath;
  final Uint8List? mediaLocalBytes;
  final Uint8List? mediaThumbnailLocalBytes;
  final String? mediaFilename;
  final String? mediaContentType;
  final int? mediaWidth;
  final int? mediaHeight;
  final int? mediaDurationSeconds;
  final String? replyToId;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  const OutboxRow({
    required this.rowId,
    required this.clientId,
    required this.chatId,
    required this.kind,
    this.body,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaCaption,
    this.mediaLocalPath,
    this.mediaLocalBytes,
    this.mediaThumbnailLocalBytes,
    this.mediaFilename,
    this.mediaContentType,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaDurationSeconds,
    this.replyToId,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['client_id'] = Variable<String>(clientId);
    map['chat_id'] = Variable<String>(chatId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    if (!nullToAbsent || mediaThumbnailUrl != null) {
      map['media_thumbnail_url'] = Variable<String>(mediaThumbnailUrl);
    }
    if (!nullToAbsent || mediaCaption != null) {
      map['media_caption'] = Variable<String>(mediaCaption);
    }
    if (!nullToAbsent || mediaLocalPath != null) {
      map['media_local_path'] = Variable<String>(mediaLocalPath);
    }
    if (!nullToAbsent || mediaLocalBytes != null) {
      map['media_local_bytes'] = Variable<Uint8List>(mediaLocalBytes);
    }
    if (!nullToAbsent || mediaThumbnailLocalBytes != null) {
      map['media_thumbnail_local_bytes'] = Variable<Uint8List>(
        mediaThumbnailLocalBytes,
      );
    }
    if (!nullToAbsent || mediaFilename != null) {
      map['media_filename'] = Variable<String>(mediaFilename);
    }
    if (!nullToAbsent || mediaContentType != null) {
      map['media_content_type'] = Variable<String>(mediaContentType);
    }
    if (!nullToAbsent || mediaWidth != null) {
      map['media_width'] = Variable<int>(mediaWidth);
    }
    if (!nullToAbsent || mediaHeight != null) {
      map['media_height'] = Variable<int>(mediaHeight);
    }
    if (!nullToAbsent || mediaDurationSeconds != null) {
      map['media_duration_seconds'] = Variable<int>(mediaDurationSeconds);
    }
    if (!nullToAbsent || replyToId != null) {
      map['reply_to_id'] = Variable<String>(replyToId);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxRowsCompanion toCompanion(bool nullToAbsent) {
    return OutboxRowsCompanion(
      rowId: Value(rowId),
      clientId: Value(clientId),
      chatId: Value(chatId),
      kind: Value(kind),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      mediaUrl: mediaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUrl),
      mediaThumbnailUrl: mediaThumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaThumbnailUrl),
      mediaCaption: mediaCaption == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaCaption),
      mediaLocalPath: mediaLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaLocalPath),
      mediaLocalBytes: mediaLocalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaLocalBytes),
      mediaThumbnailLocalBytes: mediaThumbnailLocalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaThumbnailLocalBytes),
      mediaFilename: mediaFilename == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaFilename),
      mediaContentType: mediaContentType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaContentType),
      mediaWidth: mediaWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaWidth),
      mediaHeight: mediaHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaHeight),
      mediaDurationSeconds: mediaDurationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaDurationSeconds),
      replyToId: replyToId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToId),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      rowId: serializer.fromJson<int>(json['rowId']),
      clientId: serializer.fromJson<String>(json['clientId']),
      chatId: serializer.fromJson<String>(json['chatId']),
      kind: serializer.fromJson<String>(json['kind']),
      body: serializer.fromJson<String?>(json['body']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      mediaThumbnailUrl: serializer.fromJson<String?>(
        json['mediaThumbnailUrl'],
      ),
      mediaCaption: serializer.fromJson<String?>(json['mediaCaption']),
      mediaLocalPath: serializer.fromJson<String?>(json['mediaLocalPath']),
      mediaLocalBytes: serializer.fromJson<Uint8List?>(json['mediaLocalBytes']),
      mediaThumbnailLocalBytes: serializer.fromJson<Uint8List?>(
        json['mediaThumbnailLocalBytes'],
      ),
      mediaFilename: serializer.fromJson<String?>(json['mediaFilename']),
      mediaContentType: serializer.fromJson<String?>(json['mediaContentType']),
      mediaWidth: serializer.fromJson<int?>(json['mediaWidth']),
      mediaHeight: serializer.fromJson<int?>(json['mediaHeight']),
      mediaDurationSeconds: serializer.fromJson<int?>(
        json['mediaDurationSeconds'],
      ),
      replyToId: serializer.fromJson<String?>(json['replyToId']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'clientId': serializer.toJson<String>(clientId),
      'chatId': serializer.toJson<String>(chatId),
      'kind': serializer.toJson<String>(kind),
      'body': serializer.toJson<String?>(body),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'mediaThumbnailUrl': serializer.toJson<String?>(mediaThumbnailUrl),
      'mediaCaption': serializer.toJson<String?>(mediaCaption),
      'mediaLocalPath': serializer.toJson<String?>(mediaLocalPath),
      'mediaLocalBytes': serializer.toJson<Uint8List?>(mediaLocalBytes),
      'mediaThumbnailLocalBytes': serializer.toJson<Uint8List?>(
        mediaThumbnailLocalBytes,
      ),
      'mediaFilename': serializer.toJson<String?>(mediaFilename),
      'mediaContentType': serializer.toJson<String?>(mediaContentType),
      'mediaWidth': serializer.toJson<int?>(mediaWidth),
      'mediaHeight': serializer.toJson<int?>(mediaHeight),
      'mediaDurationSeconds': serializer.toJson<int?>(mediaDurationSeconds),
      'replyToId': serializer.toJson<String?>(replyToId),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? rowId,
    String? clientId,
    String? chatId,
    String? kind,
    Value<String?> body = const Value.absent(),
    Value<String?> mediaUrl = const Value.absent(),
    Value<String?> mediaThumbnailUrl = const Value.absent(),
    Value<String?> mediaCaption = const Value.absent(),
    Value<String?> mediaLocalPath = const Value.absent(),
    Value<Uint8List?> mediaLocalBytes = const Value.absent(),
    Value<Uint8List?> mediaThumbnailLocalBytes = const Value.absent(),
    Value<String?> mediaFilename = const Value.absent(),
    Value<String?> mediaContentType = const Value.absent(),
    Value<int?> mediaWidth = const Value.absent(),
    Value<int?> mediaHeight = const Value.absent(),
    Value<int?> mediaDurationSeconds = const Value.absent(),
    Value<String?> replyToId = const Value.absent(),
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxRow(
    rowId: rowId ?? this.rowId,
    clientId: clientId ?? this.clientId,
    chatId: chatId ?? this.chatId,
    kind: kind ?? this.kind,
    body: body.present ? body.value : this.body,
    mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
    mediaThumbnailUrl: mediaThumbnailUrl.present
        ? mediaThumbnailUrl.value
        : this.mediaThumbnailUrl,
    mediaCaption: mediaCaption.present ? mediaCaption.value : this.mediaCaption,
    mediaLocalPath: mediaLocalPath.present
        ? mediaLocalPath.value
        : this.mediaLocalPath,
    mediaLocalBytes: mediaLocalBytes.present
        ? mediaLocalBytes.value
        : this.mediaLocalBytes,
    mediaThumbnailLocalBytes: mediaThumbnailLocalBytes.present
        ? mediaThumbnailLocalBytes.value
        : this.mediaThumbnailLocalBytes,
    mediaFilename: mediaFilename.present
        ? mediaFilename.value
        : this.mediaFilename,
    mediaContentType: mediaContentType.present
        ? mediaContentType.value
        : this.mediaContentType,
    mediaWidth: mediaWidth.present ? mediaWidth.value : this.mediaWidth,
    mediaHeight: mediaHeight.present ? mediaHeight.value : this.mediaHeight,
    mediaDurationSeconds: mediaDurationSeconds.present
        ? mediaDurationSeconds.value
        : this.mediaDurationSeconds,
    replyToId: replyToId.present ? replyToId.value : this.replyToId,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxRowsCompanion data) {
    return OutboxRow(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      kind: data.kind.present ? data.kind.value : this.kind,
      body: data.body.present ? data.body.value : this.body,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      mediaThumbnailUrl: data.mediaThumbnailUrl.present
          ? data.mediaThumbnailUrl.value
          : this.mediaThumbnailUrl,
      mediaCaption: data.mediaCaption.present
          ? data.mediaCaption.value
          : this.mediaCaption,
      mediaLocalPath: data.mediaLocalPath.present
          ? data.mediaLocalPath.value
          : this.mediaLocalPath,
      mediaLocalBytes: data.mediaLocalBytes.present
          ? data.mediaLocalBytes.value
          : this.mediaLocalBytes,
      mediaThumbnailLocalBytes: data.mediaThumbnailLocalBytes.present
          ? data.mediaThumbnailLocalBytes.value
          : this.mediaThumbnailLocalBytes,
      mediaFilename: data.mediaFilename.present
          ? data.mediaFilename.value
          : this.mediaFilename,
      mediaContentType: data.mediaContentType.present
          ? data.mediaContentType.value
          : this.mediaContentType,
      mediaWidth: data.mediaWidth.present
          ? data.mediaWidth.value
          : this.mediaWidth,
      mediaHeight: data.mediaHeight.present
          ? data.mediaHeight.value
          : this.mediaHeight,
      mediaDurationSeconds: data.mediaDurationSeconds.present
          ? data.mediaDurationSeconds.value
          : this.mediaDurationSeconds,
      replyToId: data.replyToId.present ? data.replyToId.value : this.replyToId,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('rowId: $rowId, ')
          ..write('clientId: $clientId, ')
          ..write('chatId: $chatId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaThumbnailUrl: $mediaThumbnailUrl, ')
          ..write('mediaCaption: $mediaCaption, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('mediaLocalBytes: $mediaLocalBytes, ')
          ..write('mediaThumbnailLocalBytes: $mediaThumbnailLocalBytes, ')
          ..write('mediaFilename: $mediaFilename, ')
          ..write('mediaContentType: $mediaContentType, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaDurationSeconds: $mediaDurationSeconds, ')
          ..write('replyToId: $replyToId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    rowId,
    clientId,
    chatId,
    kind,
    body,
    mediaUrl,
    mediaThumbnailUrl,
    mediaCaption,
    mediaLocalPath,
    $driftBlobEquality.hash(mediaLocalBytes),
    $driftBlobEquality.hash(mediaThumbnailLocalBytes),
    mediaFilename,
    mediaContentType,
    mediaWidth,
    mediaHeight,
    mediaDurationSeconds,
    replyToId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.rowId == this.rowId &&
          other.clientId == this.clientId &&
          other.chatId == this.chatId &&
          other.kind == this.kind &&
          other.body == this.body &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaThumbnailUrl == this.mediaThumbnailUrl &&
          other.mediaCaption == this.mediaCaption &&
          other.mediaLocalPath == this.mediaLocalPath &&
          $driftBlobEquality.equals(
            other.mediaLocalBytes,
            this.mediaLocalBytes,
          ) &&
          $driftBlobEquality.equals(
            other.mediaThumbnailLocalBytes,
            this.mediaThumbnailLocalBytes,
          ) &&
          other.mediaFilename == this.mediaFilename &&
          other.mediaContentType == this.mediaContentType &&
          other.mediaWidth == this.mediaWidth &&
          other.mediaHeight == this.mediaHeight &&
          other.mediaDurationSeconds == this.mediaDurationSeconds &&
          other.replyToId == this.replyToId &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class OutboxRowsCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> rowId;
  final Value<String> clientId;
  final Value<String> chatId;
  final Value<String> kind;
  final Value<String?> body;
  final Value<String?> mediaUrl;
  final Value<String?> mediaThumbnailUrl;
  final Value<String?> mediaCaption;
  final Value<String?> mediaLocalPath;
  final Value<Uint8List?> mediaLocalBytes;
  final Value<Uint8List?> mediaThumbnailLocalBytes;
  final Value<String?> mediaFilename;
  final Value<String?> mediaContentType;
  final Value<int?> mediaWidth;
  final Value<int?> mediaHeight;
  final Value<int?> mediaDurationSeconds;
  final Value<String?> replyToId;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const OutboxRowsCompanion({
    this.rowId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.chatId = const Value.absent(),
    this.kind = const Value.absent(),
    this.body = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaThumbnailUrl = const Value.absent(),
    this.mediaCaption = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.mediaLocalBytes = const Value.absent(),
    this.mediaThumbnailLocalBytes = const Value.absent(),
    this.mediaFilename = const Value.absent(),
    this.mediaContentType = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaDurationSeconds = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxRowsCompanion.insert({
    this.rowId = const Value.absent(),
    required String clientId,
    required String chatId,
    required String kind,
    this.body = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaThumbnailUrl = const Value.absent(),
    this.mediaCaption = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.mediaLocalBytes = const Value.absent(),
    this.mediaThumbnailLocalBytes = const Value.absent(),
    this.mediaFilename = const Value.absent(),
    this.mediaContentType = const Value.absent(),
    this.mediaWidth = const Value.absent(),
    this.mediaHeight = const Value.absent(),
    this.mediaDurationSeconds = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : clientId = Value(clientId),
       chatId = Value(chatId),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? rowId,
    Expression<String>? clientId,
    Expression<String>? chatId,
    Expression<String>? kind,
    Expression<String>? body,
    Expression<String>? mediaUrl,
    Expression<String>? mediaThumbnailUrl,
    Expression<String>? mediaCaption,
    Expression<String>? mediaLocalPath,
    Expression<Uint8List>? mediaLocalBytes,
    Expression<Uint8List>? mediaThumbnailLocalBytes,
    Expression<String>? mediaFilename,
    Expression<String>? mediaContentType,
    Expression<int>? mediaWidth,
    Expression<int>? mediaHeight,
    Expression<int>? mediaDurationSeconds,
    Expression<String>? replyToId,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (clientId != null) 'client_id': clientId,
      if (chatId != null) 'chat_id': chatId,
      if (kind != null) 'kind': kind,
      if (body != null) 'body': body,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaThumbnailUrl != null) 'media_thumbnail_url': mediaThumbnailUrl,
      if (mediaCaption != null) 'media_caption': mediaCaption,
      if (mediaLocalPath != null) 'media_local_path': mediaLocalPath,
      if (mediaLocalBytes != null) 'media_local_bytes': mediaLocalBytes,
      if (mediaThumbnailLocalBytes != null)
        'media_thumbnail_local_bytes': mediaThumbnailLocalBytes,
      if (mediaFilename != null) 'media_filename': mediaFilename,
      if (mediaContentType != null) 'media_content_type': mediaContentType,
      if (mediaWidth != null) 'media_width': mediaWidth,
      if (mediaHeight != null) 'media_height': mediaHeight,
      if (mediaDurationSeconds != null)
        'media_duration_seconds': mediaDurationSeconds,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxRowsCompanion copyWith({
    Value<int>? rowId,
    Value<String>? clientId,
    Value<String>? chatId,
    Value<String>? kind,
    Value<String?>? body,
    Value<String?>? mediaUrl,
    Value<String?>? mediaThumbnailUrl,
    Value<String?>? mediaCaption,
    Value<String?>? mediaLocalPath,
    Value<Uint8List?>? mediaLocalBytes,
    Value<Uint8List?>? mediaThumbnailLocalBytes,
    Value<String?>? mediaFilename,
    Value<String?>? mediaContentType,
    Value<int?>? mediaWidth,
    Value<int?>? mediaHeight,
    Value<int?>? mediaDurationSeconds,
    Value<String?>? replyToId,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return OutboxRowsCompanion(
      rowId: rowId ?? this.rowId,
      clientId: clientId ?? this.clientId,
      chatId: chatId ?? this.chatId,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaCaption: mediaCaption ?? this.mediaCaption,
      mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
      mediaLocalBytes: mediaLocalBytes ?? this.mediaLocalBytes,
      mediaThumbnailLocalBytes:
          mediaThumbnailLocalBytes ?? this.mediaThumbnailLocalBytes,
      mediaFilename: mediaFilename ?? this.mediaFilename,
      mediaContentType: mediaContentType ?? this.mediaContentType,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      mediaDurationSeconds: mediaDurationSeconds ?? this.mediaDurationSeconds,
      replyToId: replyToId ?? this.replyToId,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaThumbnailUrl.present) {
      map['media_thumbnail_url'] = Variable<String>(mediaThumbnailUrl.value);
    }
    if (mediaCaption.present) {
      map['media_caption'] = Variable<String>(mediaCaption.value);
    }
    if (mediaLocalPath.present) {
      map['media_local_path'] = Variable<String>(mediaLocalPath.value);
    }
    if (mediaLocalBytes.present) {
      map['media_local_bytes'] = Variable<Uint8List>(mediaLocalBytes.value);
    }
    if (mediaThumbnailLocalBytes.present) {
      map['media_thumbnail_local_bytes'] = Variable<Uint8List>(
        mediaThumbnailLocalBytes.value,
      );
    }
    if (mediaFilename.present) {
      map['media_filename'] = Variable<String>(mediaFilename.value);
    }
    if (mediaContentType.present) {
      map['media_content_type'] = Variable<String>(mediaContentType.value);
    }
    if (mediaWidth.present) {
      map['media_width'] = Variable<int>(mediaWidth.value);
    }
    if (mediaHeight.present) {
      map['media_height'] = Variable<int>(mediaHeight.value);
    }
    if (mediaDurationSeconds.present) {
      map['media_duration_seconds'] = Variable<int>(mediaDurationSeconds.value);
    }
    if (replyToId.present) {
      map['reply_to_id'] = Variable<String>(replyToId.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRowsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('clientId: $clientId, ')
          ..write('chatId: $chatId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaThumbnailUrl: $mediaThumbnailUrl, ')
          ..write('mediaCaption: $mediaCaption, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('mediaLocalBytes: $mediaLocalBytes, ')
          ..write('mediaThumbnailLocalBytes: $mediaThumbnailLocalBytes, ')
          ..write('mediaFilename: $mediaFilename, ')
          ..write('mediaContentType: $mediaContentType, ')
          ..write('mediaWidth: $mediaWidth, ')
          ..write('mediaHeight: $mediaHeight, ')
          ..write('mediaDurationSeconds: $mediaDurationSeconds, ')
          ..write('replyToId: $replyToId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $SyncStateRowsTable syncStateRows = $SyncStateRowsTable(this);
  late final $OutboxRowsTable outboxRows = $OutboxRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chats,
    messages,
    syncStateRows,
    outboxRows,
  ];
}

typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({
      required String chatId,
      required String matchId,
      required String otherUserId,
      required String otherUserName,
      Value<String?> otherUserPhotoUrl,
      Value<int> unreadCount,
      Value<DateTime?> lastReadAt,
      Value<DateTime?> otherUserLastReadAt,
      Value<bool> removedByMe,
      Value<String?> lastMessageId,
      Value<DateTime?> lastMessageAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({
      Value<String> chatId,
      Value<String> matchId,
      Value<String> otherUserId,
      Value<String> otherUserName,
      Value<String?> otherUserPhotoUrl,
      Value<int> unreadCount,
      Value<DateTime?> lastReadAt,
      Value<DateTime?> otherUserLastReadAt,
      Value<bool> removedByMe,
      Value<String?> lastMessageId,
      Value<DateTime?> lastMessageAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ChatsTableFilterComposer extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserName => $composableBuilder(
    column: $table.otherUserName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserPhotoUrl => $composableBuilder(
    column: $table.otherUserPhotoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get otherUserLastReadAt => $composableBuilder(
    column: $table.otherUserLastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get removedByMe => $composableBuilder(
    column: $table.removedByMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserName => $composableBuilder(
    column: $table.otherUserName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserPhotoUrl => $composableBuilder(
    column: $table.otherUserPhotoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get otherUserLastReadAt => $composableBuilder(
    column: $table.otherUserLastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get removedByMe => $composableBuilder(
    column: $table.removedByMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherUserName => $composableBuilder(
    column: $table.otherUserName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherUserPhotoUrl => $composableBuilder(
    column: $table.otherUserPhotoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get otherUserLastReadAt => $composableBuilder(
    column: $table.otherUserLastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get removedByMe => $composableBuilder(
    column: $table.removedByMe,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTable,
          Chat,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
          Chat,
          PrefetchHooks Function()
        > {
  $$ChatsTableTableManager(_$AppDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> chatId = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> otherUserId = const Value.absent(),
                Value<String> otherUserName = const Value.absent(),
                Value<String?> otherUserPhotoUrl = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<DateTime?> otherUserLastReadAt = const Value.absent(),
                Value<bool> removedByMe = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion(
                chatId: chatId,
                matchId: matchId,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                otherUserPhotoUrl: otherUserPhotoUrl,
                unreadCount: unreadCount,
                lastReadAt: lastReadAt,
                otherUserLastReadAt: otherUserLastReadAt,
                removedByMe: removedByMe,
                lastMessageId: lastMessageId,
                lastMessageAt: lastMessageAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chatId,
                required String matchId,
                required String otherUserId,
                required String otherUserName,
                Value<String?> otherUserPhotoUrl = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
                Value<DateTime?> otherUserLastReadAt = const Value.absent(),
                Value<bool> removedByMe = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<DateTime?> lastMessageAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatsCompanion.insert(
                chatId: chatId,
                matchId: matchId,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
                otherUserPhotoUrl: otherUserPhotoUrl,
                unreadCount: unreadCount,
                lastReadAt: lastReadAt,
                otherUserLastReadAt: otherUserLastReadAt,
                removedByMe: removedByMe,
                lastMessageId: lastMessageId,
                lastMessageAt: lastMessageAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTable,
      Chat,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
      Chat,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> rowId,
      Value<String?> id,
      required String clientId,
      required String chatId,
      Value<String?> senderId,
      required String kind,
      Value<String?> body,
      Value<String?> mediaUrl,
      Value<String?> mediaThumbnailUrl,
      Value<String?> mediaCaption,
      Value<int?> mediaWidth,
      Value<int?> mediaHeight,
      Value<int?> mediaDurationSeconds,
      Value<String?> replyToId,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      required DateTime createdAt,
      Value<String> status,
      Value<String?> systemPayload,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> rowId,
      Value<String?> id,
      Value<String> clientId,
      Value<String> chatId,
      Value<String?> senderId,
      Value<String> kind,
      Value<String?> body,
      Value<String?> mediaUrl,
      Value<String?> mediaThumbnailUrl,
      Value<String?> mediaCaption,
      Value<int?> mediaWidth,
      Value<int?> mediaHeight,
      Value<int?> mediaDurationSeconds,
      Value<String?> replyToId,
      Value<DateTime?> editedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<String?> systemPayload,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaThumbnailUrl => $composableBuilder(
    column: $table.mediaThumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaCaption => $composableBuilder(
    column: $table.mediaCaption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaWidth => $composableBuilder(
    column: $table.mediaWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaHeight => $composableBuilder(
    column: $table.mediaHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaDurationSeconds => $composableBuilder(
    column: $table.mediaDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemPayload => $composableBuilder(
    column: $table.systemPayload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaThumbnailUrl => $composableBuilder(
    column: $table.mediaThumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaCaption => $composableBuilder(
    column: $table.mediaCaption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaWidth => $composableBuilder(
    column: $table.mediaWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaHeight => $composableBuilder(
    column: $table.mediaHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaDurationSeconds => $composableBuilder(
    column: $table.mediaDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemPayload => $composableBuilder(
    column: $table.systemPayload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get mediaThumbnailUrl => $composableBuilder(
    column: $table.mediaThumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaCaption => $composableBuilder(
    column: $table.mediaCaption,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaWidth => $composableBuilder(
    column: $table.mediaWidth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaHeight => $composableBuilder(
    column: $table.mediaHeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaDurationSeconds => $composableBuilder(
    column: $table.mediaDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToId =>
      $composableBuilder(column: $table.replyToId, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get systemPayload => $composableBuilder(
    column: $table.systemPayload,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String?> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<String?> senderId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> mediaThumbnailUrl = const Value.absent(),
                Value<String?> mediaCaption = const Value.absent(),
                Value<int?> mediaWidth = const Value.absent(),
                Value<int?> mediaHeight = const Value.absent(),
                Value<int?> mediaDurationSeconds = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> systemPayload = const Value.absent(),
              }) => MessagesCompanion(
                rowId: rowId,
                id: id,
                clientId: clientId,
                chatId: chatId,
                senderId: senderId,
                kind: kind,
                body: body,
                mediaUrl: mediaUrl,
                mediaThumbnailUrl: mediaThumbnailUrl,
                mediaCaption: mediaCaption,
                mediaWidth: mediaWidth,
                mediaHeight: mediaHeight,
                mediaDurationSeconds: mediaDurationSeconds,
                replyToId: replyToId,
                editedAt: editedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                status: status,
                systemPayload: systemPayload,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String?> id = const Value.absent(),
                required String clientId,
                required String chatId,
                Value<String?> senderId = const Value.absent(),
                required String kind,
                Value<String?> body = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> mediaThumbnailUrl = const Value.absent(),
                Value<String?> mediaCaption = const Value.absent(),
                Value<int?> mediaWidth = const Value.absent(),
                Value<int?> mediaHeight = const Value.absent(),
                Value<int?> mediaDurationSeconds = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime createdAt,
                Value<String> status = const Value.absent(),
                Value<String?> systemPayload = const Value.absent(),
              }) => MessagesCompanion.insert(
                rowId: rowId,
                id: id,
                clientId: clientId,
                chatId: chatId,
                senderId: senderId,
                kind: kind,
                body: body,
                mediaUrl: mediaUrl,
                mediaThumbnailUrl: mediaThumbnailUrl,
                mediaCaption: mediaCaption,
                mediaWidth: mediaWidth,
                mediaHeight: mediaHeight,
                mediaDurationSeconds: mediaDurationSeconds,
                replyToId: replyToId,
                editedAt: editedAt,
                deletedAt: deletedAt,
                createdAt: createdAt,
                status: status,
                systemPayload: systemPayload,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$SyncStateRowsTableCreateCompanionBuilder =
    SyncStateRowsCompanion Function({
      required String key,
      Value<String?> cursor,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });
typedef $$SyncStateRowsTableUpdateCompanionBuilder =
    SyncStateRowsCompanion Function({
      Value<String> key,
      Value<String?> cursor,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });

class $$SyncStateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateRowsTable> {
  $$SyncStateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$SyncStateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateRowsTable,
          SyncStateRow,
          $$SyncStateRowsTableFilterComposer,
          $$SyncStateRowsTableOrderingComposer,
          $$SyncStateRowsTableAnnotationComposer,
          $$SyncStateRowsTableCreateCompanionBuilder,
          $$SyncStateRowsTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateRowsTableTableManager(_$AppDatabase db, $SyncStateRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion(
                key: key,
                cursor: cursor,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateRowsCompanion.insert(
                key: key,
                cursor: cursor,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateRowsTable,
      SyncStateRow,
      $$SyncStateRowsTableFilterComposer,
      $$SyncStateRowsTableOrderingComposer,
      $$SyncStateRowsTableAnnotationComposer,
      $$SyncStateRowsTableCreateCompanionBuilder,
      $$SyncStateRowsTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateRowsTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxRowsTableCreateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> rowId,
      required String clientId,
      required String chatId,
      required String kind,
      Value<String?> body,
      Value<String?> mediaUrl,
      Value<String?> mediaThumbnailUrl,
      Value<String?> mediaCaption,
      Value<String?> mediaLocalPath,
      Value<Uint8List?> mediaLocalBytes,
      Value<Uint8List?> mediaThumbnailLocalBytes,
      Value<String?> mediaFilename,
      Value<String?> mediaContentType,
      Value<int?> mediaWidth,
      Value<int?> mediaHeight,
      Value<int?> mediaDurationSeconds,
      Value<String?> replyToId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      required DateTime createdAt,
    });
typedef $$OutboxRowsTableUpdateCompanionBuilder =
    OutboxRowsCompanion Function({
      Value<int> rowId,
      Value<String> clientId,
      Value<String> chatId,
      Value<String> kind,
      Value<String?> body,
      Value<String?> mediaUrl,
      Value<String?> mediaThumbnailUrl,
      Value<String?> mediaCaption,
      Value<String?> mediaLocalPath,
      Value<Uint8List?> mediaLocalBytes,
      Value<Uint8List?> mediaThumbnailLocalBytes,
      Value<String?> mediaFilename,
      Value<String?> mediaContentType,
      Value<int?> mediaWidth,
      Value<int?> mediaHeight,
      Value<int?> mediaDurationSeconds,
      Value<String?> replyToId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$OutboxRowsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaThumbnailUrl => $composableBuilder(
    column: $table.mediaThumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaCaption => $composableBuilder(
    column: $table.mediaCaption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get mediaLocalBytes => $composableBuilder(
    column: $table.mediaLocalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get mediaThumbnailLocalBytes => $composableBuilder(
    column: $table.mediaThumbnailLocalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaFilename => $composableBuilder(
    column: $table.mediaFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaContentType => $composableBuilder(
    column: $table.mediaContentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaWidth => $composableBuilder(
    column: $table.mediaWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaHeight => $composableBuilder(
    column: $table.mediaHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaDurationSeconds => $composableBuilder(
    column: $table.mediaDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaThumbnailUrl => $composableBuilder(
    column: $table.mediaThumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaCaption => $composableBuilder(
    column: $table.mediaCaption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get mediaLocalBytes => $composableBuilder(
    column: $table.mediaLocalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get mediaThumbnailLocalBytes => $composableBuilder(
    column: $table.mediaThumbnailLocalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaFilename => $composableBuilder(
    column: $table.mediaFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaContentType => $composableBuilder(
    column: $table.mediaContentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaWidth => $composableBuilder(
    column: $table.mediaWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaHeight => $composableBuilder(
    column: $table.mediaHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaDurationSeconds => $composableBuilder(
    column: $table.mediaDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxRowsTable> {
  $$OutboxRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get mediaThumbnailUrl => $composableBuilder(
    column: $table.mediaThumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaCaption => $composableBuilder(
    column: $table.mediaCaption,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get mediaLocalBytes => $composableBuilder(
    column: $table.mediaLocalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get mediaThumbnailLocalBytes => $composableBuilder(
    column: $table.mediaThumbnailLocalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaFilename => $composableBuilder(
    column: $table.mediaFilename,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaContentType => $composableBuilder(
    column: $table.mediaContentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaWidth => $composableBuilder(
    column: $table.mediaWidth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaHeight => $composableBuilder(
    column: $table.mediaHeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mediaDurationSeconds => $composableBuilder(
    column: $table.mediaDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replyToId =>
      $composableBuilder(column: $table.replyToId, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxRowsTable,
          OutboxRow,
          $$OutboxRowsTableFilterComposer,
          $$OutboxRowsTableOrderingComposer,
          $$OutboxRowsTableAnnotationComposer,
          $$OutboxRowsTableCreateCompanionBuilder,
          $$OutboxRowsTableUpdateCompanionBuilder,
          (
            OutboxRow,
            BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>,
          ),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxRowsTableTableManager(_$AppDatabase db, $OutboxRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String> chatId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> mediaThumbnailUrl = const Value.absent(),
                Value<String?> mediaCaption = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<Uint8List?> mediaLocalBytes = const Value.absent(),
                Value<Uint8List?> mediaThumbnailLocalBytes =
                    const Value.absent(),
                Value<String?> mediaFilename = const Value.absent(),
                Value<String?> mediaContentType = const Value.absent(),
                Value<int?> mediaWidth = const Value.absent(),
                Value<int?> mediaHeight = const Value.absent(),
                Value<int?> mediaDurationSeconds = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxRowsCompanion(
                rowId: rowId,
                clientId: clientId,
                chatId: chatId,
                kind: kind,
                body: body,
                mediaUrl: mediaUrl,
                mediaThumbnailUrl: mediaThumbnailUrl,
                mediaCaption: mediaCaption,
                mediaLocalPath: mediaLocalPath,
                mediaLocalBytes: mediaLocalBytes,
                mediaThumbnailLocalBytes: mediaThumbnailLocalBytes,
                mediaFilename: mediaFilename,
                mediaContentType: mediaContentType,
                mediaWidth: mediaWidth,
                mediaHeight: mediaHeight,
                mediaDurationSeconds: mediaDurationSeconds,
                replyToId: replyToId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String clientId,
                required String chatId,
                required String kind,
                Value<String?> body = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String?> mediaThumbnailUrl = const Value.absent(),
                Value<String?> mediaCaption = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<Uint8List?> mediaLocalBytes = const Value.absent(),
                Value<Uint8List?> mediaThumbnailLocalBytes =
                    const Value.absent(),
                Value<String?> mediaFilename = const Value.absent(),
                Value<String?> mediaContentType = const Value.absent(),
                Value<int?> mediaWidth = const Value.absent(),
                Value<int?> mediaHeight = const Value.absent(),
                Value<int?> mediaDurationSeconds = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxRowsCompanion.insert(
                rowId: rowId,
                clientId: clientId,
                chatId: chatId,
                kind: kind,
                body: body,
                mediaUrl: mediaUrl,
                mediaThumbnailUrl: mediaThumbnailUrl,
                mediaCaption: mediaCaption,
                mediaLocalPath: mediaLocalPath,
                mediaLocalBytes: mediaLocalBytes,
                mediaThumbnailLocalBytes: mediaThumbnailLocalBytes,
                mediaFilename: mediaFilename,
                mediaContentType: mediaContentType,
                mediaWidth: mediaWidth,
                mediaHeight: mediaHeight,
                mediaDurationSeconds: mediaDurationSeconds,
                replyToId: replyToId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxRowsTable,
      OutboxRow,
      $$OutboxRowsTableFilterComposer,
      $$OutboxRowsTableOrderingComposer,
      $$OutboxRowsTableAnnotationComposer,
      $$OutboxRowsTableCreateCompanionBuilder,
      $$OutboxRowsTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxRowsTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$SyncStateRowsTableTableManager get syncStateRows =>
      $$SyncStateRowsTableTableManager(_db, _db.syncStateRows);
  $$OutboxRowsTableTableManager get outboxRows =>
      $$OutboxRowsTableTableManager(_db, _db.outboxRows);
}
