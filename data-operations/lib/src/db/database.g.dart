// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocationsTable extends Locations
    with TableInfo<$LocationsTable, LocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($LocationsTable.$convertersyncState);
  @override
  late final GeneratedColumnWithTypeConverter<LocationType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocationType>($LocationsTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES locations (id)',
    ),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    type,
    name,
    parentId,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $LocationsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      type: $LocationsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $LocationsTable createAlias(String alias) {
    return $LocationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<LocationType, String, String> $convertertype =
      const EnumNameConverter<LocationType>(LocationType.values);
}

class LocationRow extends DataClass implements Insertable<LocationRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final LocationType type;
  final String name;
  final String? parentId;

  /// Soft delete (v2). Hidden from lists, kept for history.
  final DateTime? archivedAt;
  const LocationRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.type,
    required this.name,
    this.parentId,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $LocationsTable.$convertersyncState.toSql(syncState),
      );
    }
    {
      map['type'] = Variable<String>(
        $LocationsTable.$convertertype.toSql(type),
      );
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  LocationsCompanion toCompanion(bool nullToAbsent) {
    return LocationsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      type: Value(type),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory LocationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $LocationsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      type: $LocationsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $LocationsTable.$convertersyncState.toJson(syncState),
      ),
      'type': serializer.toJson<String>(
        $LocationsTable.$convertertype.toJson(type),
      ),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  LocationRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    LocationType? type,
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => LocationRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    type: type ?? this.type,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  LocationRow copyWithCompanion(LocationsCompanion data) {
    return LocationRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    type,
    name,
    parentId,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.type == this.type &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.archivedAt == this.archivedAt);
}

class LocationsCompanion extends UpdateCompanion<LocationRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<LocationType> type;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const LocationsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocationsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required LocationType type,
    required String name,
    this.parentId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       type = Value(type),
       name = Value(name);
  static Insertable<LocationRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocationsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<LocationType>? type,
    Value<String>? name,
    Value<String?>? parentId,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return LocationsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      type: type ?? this.type,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $LocationsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $LocationsTable.$convertertype.toSql(type.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LotsTable extends Lots with TableInfo<$LotsTable, LotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($LotsTable.$convertersyncState);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierNameMeta = const VerificationMeta(
    'supplierName',
  );
  @override
  late final GeneratedColumn<String> supplierName = GeneratedColumn<String>(
    'supplier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grainTypeMeta = const VerificationMeta(
    'grainType',
  );
  @override
  late final GeneratedColumn<String> grainType = GeneratedColumn<String>(
    'grain_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _declaredQuantityMeta = const VerificationMeta(
    'declaredQuantity',
  );
  @override
  late final GeneratedColumn<double> declaredQuantity = GeneratedColumn<double>(
    'declared_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityUnitMeta = const VerificationMeta(
    'quantityUnit',
  );
  @override
  late final GeneratedColumn<String> quantityUnit = GeneratedColumn<String>(
    'quantity_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScreeningStatus, String>
  screeningStatus = GeneratedColumn<String>(
    'screening_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(ScreeningStatus.pending.name),
  ).withConverter<ScreeningStatus>($LotsTable.$converterscreeningStatus);
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    code,
    supplierId,
    supplierName,
    grainType,
    declaredQuantity,
    quantityUnit,
    receivedAt,
    screeningStatus,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lots';
  @override
  VerificationContext validateIntegrity(
    Insertable<LotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('supplier_name')) {
      context.handle(
        _supplierNameMeta,
        supplierName.isAcceptableOrUnknown(
          data['supplier_name']!,
          _supplierNameMeta,
        ),
      );
    }
    if (data.containsKey('grain_type')) {
      context.handle(
        _grainTypeMeta,
        grainType.isAcceptableOrUnknown(data['grain_type']!, _grainTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_grainTypeMeta);
    }
    if (data.containsKey('declared_quantity')) {
      context.handle(
        _declaredQuantityMeta,
        declaredQuantity.isAcceptableOrUnknown(
          data['declared_quantity']!,
          _declaredQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_declaredQuantityMeta);
    }
    if (data.containsKey('quantity_unit')) {
      context.handle(
        _quantityUnitMeta,
        quantityUnit.isAcceptableOrUnknown(
          data['quantity_unit']!,
          _quantityUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityUnitMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $LotsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      supplierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_name'],
      ),
      grainType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grain_type'],
      )!,
      declaredQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}declared_quantity'],
      )!,
      quantityUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_unit'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      screeningStatus: $LotsTable.$converterscreeningStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}screening_status'],
        )!,
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $LotsTable createAlias(String alias) {
    return $LotsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<ScreeningStatus, String, String>
  $converterscreeningStatus = const EnumNameConverter<ScreeningStatus>(
    ScreeningStatus.values,
  );
}

class LotRow extends DataClass implements Insertable<LotRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String code;
  final String? supplierId;
  final String? supplierName;
  final String grainType;
  final double declaredQuantity;
  final String quantityUnit;
  final DateTime receivedAt;
  final ScreeningStatus screeningStatus;

  /// Soft delete (v2).
  final DateTime? archivedAt;
  const LotRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.code,
    this.supplierId,
    this.supplierName,
    required this.grainType,
    required this.declaredQuantity,
    required this.quantityUnit,
    required this.receivedAt,
    required this.screeningStatus,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $LotsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    if (!nullToAbsent || supplierName != null) {
      map['supplier_name'] = Variable<String>(supplierName);
    }
    map['grain_type'] = Variable<String>(grainType);
    map['declared_quantity'] = Variable<double>(declaredQuantity);
    map['quantity_unit'] = Variable<String>(quantityUnit);
    map['received_at'] = Variable<DateTime>(receivedAt);
    {
      map['screening_status'] = Variable<String>(
        $LotsTable.$converterscreeningStatus.toSql(screeningStatus),
      );
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  LotsCompanion toCompanion(bool nullToAbsent) {
    return LotsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      code: Value(code),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      supplierName: supplierName == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierName),
      grainType: Value(grainType),
      declaredQuantity: Value(declaredQuantity),
      quantityUnit: Value(quantityUnit),
      receivedAt: Value(receivedAt),
      screeningStatus: Value(screeningStatus),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory LotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LotRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $LotsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      code: serializer.fromJson<String>(json['code']),
      supplierId: serializer.fromJson<String?>(json['supplierId']),
      supplierName: serializer.fromJson<String?>(json['supplierName']),
      grainType: serializer.fromJson<String>(json['grainType']),
      declaredQuantity: serializer.fromJson<double>(json['declaredQuantity']),
      quantityUnit: serializer.fromJson<String>(json['quantityUnit']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      screeningStatus: $LotsTable.$converterscreeningStatus.fromJson(
        serializer.fromJson<String>(json['screeningStatus']),
      ),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $LotsTable.$convertersyncState.toJson(syncState),
      ),
      'code': serializer.toJson<String>(code),
      'supplierId': serializer.toJson<String?>(supplierId),
      'supplierName': serializer.toJson<String?>(supplierName),
      'grainType': serializer.toJson<String>(grainType),
      'declaredQuantity': serializer.toJson<double>(declaredQuantity),
      'quantityUnit': serializer.toJson<String>(quantityUnit),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'screeningStatus': serializer.toJson<String>(
        $LotsTable.$converterscreeningStatus.toJson(screeningStatus),
      ),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  LotRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? code,
    Value<String?> supplierId = const Value.absent(),
    Value<String?> supplierName = const Value.absent(),
    String? grainType,
    double? declaredQuantity,
    String? quantityUnit,
    DateTime? receivedAt,
    ScreeningStatus? screeningStatus,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => LotRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    code: code ?? this.code,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    supplierName: supplierName.present ? supplierName.value : this.supplierName,
    grainType: grainType ?? this.grainType,
    declaredQuantity: declaredQuantity ?? this.declaredQuantity,
    quantityUnit: quantityUnit ?? this.quantityUnit,
    receivedAt: receivedAt ?? this.receivedAt,
    screeningStatus: screeningStatus ?? this.screeningStatus,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  LotRow copyWithCompanion(LotsCompanion data) {
    return LotRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      code: data.code.present ? data.code.value : this.code,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      supplierName: data.supplierName.present
          ? data.supplierName.value
          : this.supplierName,
      grainType: data.grainType.present ? data.grainType.value : this.grainType,
      declaredQuantity: data.declaredQuantity.present
          ? data.declaredQuantity.value
          : this.declaredQuantity,
      quantityUnit: data.quantityUnit.present
          ? data.quantityUnit.value
          : this.quantityUnit,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      screeningStatus: data.screeningStatus.present
          ? data.screeningStatus.value
          : this.screeningStatus,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LotRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('code: $code, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('grainType: $grainType, ')
          ..write('declaredQuantity: $declaredQuantity, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('screeningStatus: $screeningStatus, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    code,
    supplierId,
    supplierName,
    grainType,
    declaredQuantity,
    quantityUnit,
    receivedAt,
    screeningStatus,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LotRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.code == this.code &&
          other.supplierId == this.supplierId &&
          other.supplierName == this.supplierName &&
          other.grainType == this.grainType &&
          other.declaredQuantity == this.declaredQuantity &&
          other.quantityUnit == this.quantityUnit &&
          other.receivedAt == this.receivedAt &&
          other.screeningStatus == this.screeningStatus &&
          other.archivedAt == this.archivedAt);
}

class LotsCompanion extends UpdateCompanion<LotRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> code;
  final Value<String?> supplierId;
  final Value<String?> supplierName;
  final Value<String> grainType;
  final Value<double> declaredQuantity;
  final Value<String> quantityUnit;
  final Value<DateTime> receivedAt;
  final Value<ScreeningStatus> screeningStatus;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const LotsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.code = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.grainType = const Value.absent(),
    this.declaredQuantity = const Value.absent(),
    this.quantityUnit = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.screeningStatus = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LotsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String code,
    this.supplierId = const Value.absent(),
    this.supplierName = const Value.absent(),
    required String grainType,
    required double declaredQuantity,
    required String quantityUnit,
    required DateTime receivedAt,
    this.screeningStatus = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       code = Value(code),
       grainType = Value(grainType),
       declaredQuantity = Value(declaredQuantity),
       quantityUnit = Value(quantityUnit),
       receivedAt = Value(receivedAt);
  static Insertable<LotRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? code,
    Expression<String>? supplierId,
    Expression<String>? supplierName,
    Expression<String>? grainType,
    Expression<double>? declaredQuantity,
    Expression<String>? quantityUnit,
    Expression<DateTime>? receivedAt,
    Expression<String>? screeningStatus,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (code != null) 'code': code,
      if (supplierId != null) 'supplier_id': supplierId,
      if (supplierName != null) 'supplier_name': supplierName,
      if (grainType != null) 'grain_type': grainType,
      if (declaredQuantity != null) 'declared_quantity': declaredQuantity,
      if (quantityUnit != null) 'quantity_unit': quantityUnit,
      if (receivedAt != null) 'received_at': receivedAt,
      if (screeningStatus != null) 'screening_status': screeningStatus,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LotsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? code,
    Value<String?>? supplierId,
    Value<String?>? supplierName,
    Value<String>? grainType,
    Value<double>? declaredQuantity,
    Value<String>? quantityUnit,
    Value<DateTime>? receivedAt,
    Value<ScreeningStatus>? screeningStatus,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return LotsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      code: code ?? this.code,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      grainType: grainType ?? this.grainType,
      declaredQuantity: declaredQuantity ?? this.declaredQuantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      receivedAt: receivedAt ?? this.receivedAt,
      screeningStatus: screeningStatus ?? this.screeningStatus,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $LotsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (supplierName.present) {
      map['supplier_name'] = Variable<String>(supplierName.value);
    }
    if (grainType.present) {
      map['grain_type'] = Variable<String>(grainType.value);
    }
    if (declaredQuantity.present) {
      map['declared_quantity'] = Variable<double>(declaredQuantity.value);
    }
    if (quantityUnit.present) {
      map['quantity_unit'] = Variable<String>(quantityUnit.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (screeningStatus.present) {
      map['screening_status'] = Variable<String>(
        $LotsTable.$converterscreeningStatus.toSql(screeningStatus.value),
      );
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LotsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('code: $code, ')
          ..write('supplierId: $supplierId, ')
          ..write('supplierName: $supplierName, ')
          ..write('grainType: $grainType, ')
          ..write('declaredQuantity: $declaredQuantity, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('screeningStatus: $screeningStatus, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HarvestsTable extends Harvests
    with TableInfo<$HarvestsTable, HarvestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HarvestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($HarvestsTable.$convertersyncState);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grainTypeMeta = const VerificationMeta(
    'grainType',
  );
  @override
  late final GeneratedColumn<String> grainType = GeneratedColumn<String>(
    'grain_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _harvestedAtMeta = const VerificationMeta(
    'harvestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> harvestedAt = GeneratedColumn<DateTime>(
    'harvested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    name,
    grainType,
    harvestedAt,
    notes,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'harvests';
  @override
  VerificationContext validateIntegrity(
    Insertable<HarvestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grain_type')) {
      context.handle(
        _grainTypeMeta,
        grainType.isAcceptableOrUnknown(data['grain_type']!, _grainTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_grainTypeMeta);
    }
    if (data.containsKey('harvested_at')) {
      context.handle(
        _harvestedAtMeta,
        harvestedAt.isAcceptableOrUnknown(
          data['harvested_at']!,
          _harvestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_harvestedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HarvestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HarvestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $HarvestsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grainType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grain_type'],
      )!,
      harvestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}harvested_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $HarvestsTable createAlias(String alias) {
    return $HarvestsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class HarvestRow extends DataClass implements Insertable<HarvestRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String name;
  final String grainType;
  final DateTime harvestedAt;
  final String? notes;

  /// Soft delete.
  final DateTime? archivedAt;
  const HarvestRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.name,
    required this.grainType,
    required this.harvestedAt,
    this.notes,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $HarvestsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['name'] = Variable<String>(name);
    map['grain_type'] = Variable<String>(grainType);
    map['harvested_at'] = Variable<DateTime>(harvestedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  HarvestsCompanion toCompanion(bool nullToAbsent) {
    return HarvestsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      name: Value(name),
      grainType: Value(grainType),
      harvestedAt: Value(harvestedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory HarvestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HarvestRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $HarvestsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      name: serializer.fromJson<String>(json['name']),
      grainType: serializer.fromJson<String>(json['grainType']),
      harvestedAt: serializer.fromJson<DateTime>(json['harvestedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $HarvestsTable.$convertersyncState.toJson(syncState),
      ),
      'name': serializer.toJson<String>(name),
      'grainType': serializer.toJson<String>(grainType),
      'harvestedAt': serializer.toJson<DateTime>(harvestedAt),
      'notes': serializer.toJson<String?>(notes),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  HarvestRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? name,
    String? grainType,
    DateTime? harvestedAt,
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => HarvestRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    name: name ?? this.name,
    grainType: grainType ?? this.grainType,
    harvestedAt: harvestedAt ?? this.harvestedAt,
    notes: notes.present ? notes.value : this.notes,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  HarvestRow copyWithCompanion(HarvestsCompanion data) {
    return HarvestRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      name: data.name.present ? data.name.value : this.name,
      grainType: data.grainType.present ? data.grainType.value : this.grainType,
      harvestedAt: data.harvestedAt.present
          ? data.harvestedAt.value
          : this.harvestedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HarvestRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('name: $name, ')
          ..write('grainType: $grainType, ')
          ..write('harvestedAt: $harvestedAt, ')
          ..write('notes: $notes, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    name,
    grainType,
    harvestedAt,
    notes,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HarvestRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.name == this.name &&
          other.grainType == this.grainType &&
          other.harvestedAt == this.harvestedAt &&
          other.notes == this.notes &&
          other.archivedAt == this.archivedAt);
}

class HarvestsCompanion extends UpdateCompanion<HarvestRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> name;
  final Value<String> grainType;
  final Value<DateTime> harvestedAt;
  final Value<String?> notes;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const HarvestsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.name = const Value.absent(),
    this.grainType = const Value.absent(),
    this.harvestedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HarvestsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String name,
    required String grainType,
    required DateTime harvestedAt,
    this.notes = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       grainType = Value(grainType),
       harvestedAt = Value(harvestedAt);
  static Insertable<HarvestRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? name,
    Expression<String>? grainType,
    Expression<DateTime>? harvestedAt,
    Expression<String>? notes,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (name != null) 'name': name,
      if (grainType != null) 'grain_type': grainType,
      if (harvestedAt != null) 'harvested_at': harvestedAt,
      if (notes != null) 'notes': notes,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HarvestsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? name,
    Value<String>? grainType,
    Value<DateTime>? harvestedAt,
    Value<String?>? notes,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return HarvestsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      name: name ?? this.name,
      grainType: grainType ?? this.grainType,
      harvestedAt: harvestedAt ?? this.harvestedAt,
      notes: notes ?? this.notes,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $HarvestsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grainType.present) {
      map['grain_type'] = Variable<String>(grainType.value);
    }
    if (harvestedAt.present) {
      map['harvested_at'] = Variable<DateTime>(harvestedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HarvestsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('name: $name, ')
          ..write('grainType: $grainType, ')
          ..write('harvestedAt: $harvestedAt, ')
          ..write('notes: $notes, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($ItemsTable.$convertersyncState);
  @override
  late final GeneratedColumnWithTypeConverter<Role, String> ownerRole =
      GeneratedColumn<String>(
        'owner_role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Role>($ItemsTable.$converterownerRole);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grainTypeMeta = const VerificationMeta(
    'grainType',
  );
  @override
  late final GeneratedColumn<String> grainType = GeneratedColumn<String>(
    'grain_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityUnitMeta = const VerificationMeta(
    'quantityUnit',
  );
  @override
  late final GeneratedColumn<String> quantityUnit = GeneratedColumn<String>(
    'quantity_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageDateMeta = const VerificationMeta(
    'storageDate',
  );
  @override
  late final GeneratedColumn<DateTime> storageDate = GeneratedColumn<DateTime>(
    'storage_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES locations (id)',
    ),
  );
  static const VerificationMeta _lotIdMeta = const VerificationMeta('lotId');
  @override
  late final GeneratedColumn<String> lotId = GeneratedColumn<String>(
    'lot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lots (id)',
    ),
  );
  static const VerificationMeta _harvestIdMeta = const VerificationMeta(
    'harvestId',
  );
  @override
  late final GeneratedColumn<String> harvestId = GeneratedColumn<String>(
    'harvest_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES harvests (id)',
    ),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    ownerRole,
    label,
    grainType,
    quantity,
    quantityUnit,
    storageDate,
    locationId,
    lotId,
    harvestId,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('grain_type')) {
      context.handle(
        _grainTypeMeta,
        grainType.isAcceptableOrUnknown(data['grain_type']!, _grainTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_grainTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('quantity_unit')) {
      context.handle(
        _quantityUnitMeta,
        quantityUnit.isAcceptableOrUnknown(
          data['quantity_unit']!,
          _quantityUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityUnitMeta);
    }
    if (data.containsKey('storage_date')) {
      context.handle(
        _storageDateMeta,
        storageDate.isAcceptableOrUnknown(
          data['storage_date']!,
          _storageDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageDateMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('lot_id')) {
      context.handle(
        _lotIdMeta,
        lotId.isAcceptableOrUnknown(data['lot_id']!, _lotIdMeta),
      );
    }
    if (data.containsKey('harvest_id')) {
      context.handle(
        _harvestIdMeta,
        harvestId.isAcceptableOrUnknown(data['harvest_id']!, _harvestIdMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $ItemsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      ownerRole: $ItemsTable.$converterownerRole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}owner_role'],
        )!,
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      grainType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grain_type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      quantityUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_unit'],
      )!,
      storageDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}storage_date'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      lotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot_id'],
      ),
      harvestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}harvest_id'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<Role, String, String> $converterownerRole =
      const EnumNameConverter<Role>(Role.values);
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final Role ownerRole;
  final String label;
  final String grainType;
  final double quantity;
  final String quantityUnit;
  final DateTime storageDate;
  final String? locationId;
  final String? lotId;

  /// Farmer harvest this sack belongs to (v2).
  final String? harvestId;

  /// Soft delete (v2). Scans, inspections and reminders are kept.
  final DateTime? archivedAt;
  const ItemRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.ownerRole,
    required this.label,
    required this.grainType,
    required this.quantity,
    required this.quantityUnit,
    required this.storageDate,
    this.locationId,
    this.lotId,
    this.harvestId,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $ItemsTable.$convertersyncState.toSql(syncState),
      );
    }
    {
      map['owner_role'] = Variable<String>(
        $ItemsTable.$converterownerRole.toSql(ownerRole),
      );
    }
    map['label'] = Variable<String>(label);
    map['grain_type'] = Variable<String>(grainType);
    map['quantity'] = Variable<double>(quantity);
    map['quantity_unit'] = Variable<String>(quantityUnit);
    map['storage_date'] = Variable<DateTime>(storageDate);
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || lotId != null) {
      map['lot_id'] = Variable<String>(lotId);
    }
    if (!nullToAbsent || harvestId != null) {
      map['harvest_id'] = Variable<String>(harvestId);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      ownerRole: Value(ownerRole),
      label: Value(label),
      grainType: Value(grainType),
      quantity: Value(quantity),
      quantityUnit: Value(quantityUnit),
      storageDate: Value(storageDate),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      lotId: lotId == null && nullToAbsent
          ? const Value.absent()
          : Value(lotId),
      harvestId: harvestId == null && nullToAbsent
          ? const Value.absent()
          : Value(harvestId),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $ItemsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      ownerRole: $ItemsTable.$converterownerRole.fromJson(
        serializer.fromJson<String>(json['ownerRole']),
      ),
      label: serializer.fromJson<String>(json['label']),
      grainType: serializer.fromJson<String>(json['grainType']),
      quantity: serializer.fromJson<double>(json['quantity']),
      quantityUnit: serializer.fromJson<String>(json['quantityUnit']),
      storageDate: serializer.fromJson<DateTime>(json['storageDate']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      lotId: serializer.fromJson<String?>(json['lotId']),
      harvestId: serializer.fromJson<String?>(json['harvestId']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $ItemsTable.$convertersyncState.toJson(syncState),
      ),
      'ownerRole': serializer.toJson<String>(
        $ItemsTable.$converterownerRole.toJson(ownerRole),
      ),
      'label': serializer.toJson<String>(label),
      'grainType': serializer.toJson<String>(grainType),
      'quantity': serializer.toJson<double>(quantity),
      'quantityUnit': serializer.toJson<String>(quantityUnit),
      'storageDate': serializer.toJson<DateTime>(storageDate),
      'locationId': serializer.toJson<String?>(locationId),
      'lotId': serializer.toJson<String?>(lotId),
      'harvestId': serializer.toJson<String?>(harvestId),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  ItemRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    Role? ownerRole,
    String? label,
    String? grainType,
    double? quantity,
    String? quantityUnit,
    DateTime? storageDate,
    Value<String?> locationId = const Value.absent(),
    Value<String?> lotId = const Value.absent(),
    Value<String?> harvestId = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => ItemRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    ownerRole: ownerRole ?? this.ownerRole,
    label: label ?? this.label,
    grainType: grainType ?? this.grainType,
    quantity: quantity ?? this.quantity,
    quantityUnit: quantityUnit ?? this.quantityUnit,
    storageDate: storageDate ?? this.storageDate,
    locationId: locationId.present ? locationId.value : this.locationId,
    lotId: lotId.present ? lotId.value : this.lotId,
    harvestId: harvestId.present ? harvestId.value : this.harvestId,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      ownerRole: data.ownerRole.present ? data.ownerRole.value : this.ownerRole,
      label: data.label.present ? data.label.value : this.label,
      grainType: data.grainType.present ? data.grainType.value : this.grainType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      quantityUnit: data.quantityUnit.present
          ? data.quantityUnit.value
          : this.quantityUnit,
      storageDate: data.storageDate.present
          ? data.storageDate.value
          : this.storageDate,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      lotId: data.lotId.present ? data.lotId.value : this.lotId,
      harvestId: data.harvestId.present ? data.harvestId.value : this.harvestId,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('ownerRole: $ownerRole, ')
          ..write('label: $label, ')
          ..write('grainType: $grainType, ')
          ..write('quantity: $quantity, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('storageDate: $storageDate, ')
          ..write('locationId: $locationId, ')
          ..write('lotId: $lotId, ')
          ..write('harvestId: $harvestId, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    ownerRole,
    label,
    grainType,
    quantity,
    quantityUnit,
    storageDate,
    locationId,
    lotId,
    harvestId,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.ownerRole == this.ownerRole &&
          other.label == this.label &&
          other.grainType == this.grainType &&
          other.quantity == this.quantity &&
          other.quantityUnit == this.quantityUnit &&
          other.storageDate == this.storageDate &&
          other.locationId == this.locationId &&
          other.lotId == this.lotId &&
          other.harvestId == this.harvestId &&
          other.archivedAt == this.archivedAt);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<Role> ownerRole;
  final Value<String> label;
  final Value<String> grainType;
  final Value<double> quantity;
  final Value<String> quantityUnit;
  final Value<DateTime> storageDate;
  final Value<String?> locationId;
  final Value<String?> lotId;
  final Value<String?> harvestId;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.ownerRole = const Value.absent(),
    this.label = const Value.absent(),
    this.grainType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityUnit = const Value.absent(),
    this.storageDate = const Value.absent(),
    this.locationId = const Value.absent(),
    this.lotId = const Value.absent(),
    this.harvestId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required Role ownerRole,
    required String label,
    required String grainType,
    required double quantity,
    required String quantityUnit,
    required DateTime storageDate,
    this.locationId = const Value.absent(),
    this.lotId = const Value.absent(),
    this.harvestId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       ownerRole = Value(ownerRole),
       label = Value(label),
       grainType = Value(grainType),
       quantity = Value(quantity),
       quantityUnit = Value(quantityUnit),
       storageDate = Value(storageDate);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? ownerRole,
    Expression<String>? label,
    Expression<String>? grainType,
    Expression<double>? quantity,
    Expression<String>? quantityUnit,
    Expression<DateTime>? storageDate,
    Expression<String>? locationId,
    Expression<String>? lotId,
    Expression<String>? harvestId,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (ownerRole != null) 'owner_role': ownerRole,
      if (label != null) 'label': label,
      if (grainType != null) 'grain_type': grainType,
      if (quantity != null) 'quantity': quantity,
      if (quantityUnit != null) 'quantity_unit': quantityUnit,
      if (storageDate != null) 'storage_date': storageDate,
      if (locationId != null) 'location_id': locationId,
      if (lotId != null) 'lot_id': lotId,
      if (harvestId != null) 'harvest_id': harvestId,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<Role>? ownerRole,
    Value<String>? label,
    Value<String>? grainType,
    Value<double>? quantity,
    Value<String>? quantityUnit,
    Value<DateTime>? storageDate,
    Value<String?>? locationId,
    Value<String?>? lotId,
    Value<String?>? harvestId,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      ownerRole: ownerRole ?? this.ownerRole,
      label: label ?? this.label,
      grainType: grainType ?? this.grainType,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      storageDate: storageDate ?? this.storageDate,
      locationId: locationId ?? this.locationId,
      lotId: lotId ?? this.lotId,
      harvestId: harvestId ?? this.harvestId,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $ItemsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (ownerRole.present) {
      map['owner_role'] = Variable<String>(
        $ItemsTable.$converterownerRole.toSql(ownerRole.value),
      );
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (grainType.present) {
      map['grain_type'] = Variable<String>(grainType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (quantityUnit.present) {
      map['quantity_unit'] = Variable<String>(quantityUnit.value);
    }
    if (storageDate.present) {
      map['storage_date'] = Variable<DateTime>(storageDate.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (lotId.present) {
      map['lot_id'] = Variable<String>(lotId.value);
    }
    if (harvestId.present) {
      map['harvest_id'] = Variable<String>(harvestId.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('ownerRole: $ownerRole, ')
          ..write('label: $label, ')
          ..write('grainType: $grainType, ')
          ..write('quantity: $quantity, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('storageDate: $storageDate, ')
          ..write('locationId: $locationId, ')
          ..write('lotId: $lotId, ')
          ..write('harvestId: $harvestId, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScansTable extends Scans with TableInfo<$ScansTable, ScanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($ScansTable.$convertersyncState);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleRateMeta = const VerificationMeta(
    'sampleRate',
  );
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
    'sample_rate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScanQuality, String> quality =
      GeneratedColumn<String>(
        'quality',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ScanQuality>($ScansTable.$converterquality);
  @override
  late final GeneratedColumnWithTypeConverter<List<QualityReason>, String>
  qualityReasons = GeneratedColumn<String>(
    'quality_reasons',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<QualityReason>>($ScansTable.$converterqualityReasons);
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Classification, String> result =
      GeneratedColumn<String>(
        'result',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Classification>($ScansTable.$converterresult);
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _experimentalMeta = const VerificationMeta(
    'experimental',
  );
  @override
  late final GeneratedColumn<bool> experimental = GeneratedColumn<bool>(
    'experimental',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("experimental" IN (0, 1))',
    ),
  );
  static const VerificationMeta _latencyMsMeta = const VerificationMeta(
    'latencyMs',
  );
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
    'latency_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceModelMeta = const VerificationMeta(
    'deviceModel',
  );
  @override
  late final GeneratedColumn<String> deviceModel = GeneratedColumn<String>(
    'device_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _osVersionMeta = const VerificationMeta(
    'osVersion',
  );
  @override
  late final GeneratedColumn<String> osVersion = GeneratedColumn<String>(
    'os_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioRetainedMeta = const VerificationMeta(
    'audioRetained',
  );
  @override
  late final GeneratedColumn<bool> audioRetained = GeneratedColumn<bool>(
    'audio_retained',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("audio_retained" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    itemId,
    capturedAt,
    durationMs,
    sampleRate,
    quality,
    qualityReasons,
    modelVersion,
    result,
    confidence,
    experimental,
    latencyMs,
    deviceModel,
    osVersion,
    audioRetained,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scans';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
        _sampleRateMeta,
        sampleRate.isAcceptableOrUnknown(data['sample_rate']!, _sampleRateMeta),
      );
    } else if (isInserting) {
      context.missing(_sampleRateMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('experimental')) {
      context.handle(
        _experimentalMeta,
        experimental.isAcceptableOrUnknown(
          data['experimental']!,
          _experimentalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_experimentalMeta);
    }
    if (data.containsKey('latency_ms')) {
      context.handle(
        _latencyMsMeta,
        latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta),
      );
    } else if (isInserting) {
      context.missing(_latencyMsMeta);
    }
    if (data.containsKey('device_model')) {
      context.handle(
        _deviceModelMeta,
        deviceModel.isAcceptableOrUnknown(
          data['device_model']!,
          _deviceModelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceModelMeta);
    }
    if (data.containsKey('os_version')) {
      context.handle(
        _osVersionMeta,
        osVersion.isAcceptableOrUnknown(data['os_version']!, _osVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_osVersionMeta);
    }
    if (data.containsKey('audio_retained')) {
      context.handle(
        _audioRetainedMeta,
        audioRetained.isAcceptableOrUnknown(
          data['audio_retained']!,
          _audioRetainedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $ScansTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      sampleRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate'],
      )!,
      quality: $ScansTable.$converterquality.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quality'],
        )!,
      ),
      qualityReasons: $ScansTable.$converterqualityReasons.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quality_reasons'],
        )!,
      ),
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      )!,
      result: $ScansTable.$converterresult.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        )!,
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      experimental: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}experimental'],
      )!,
      latencyMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latency_ms'],
      )!,
      deviceModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_model'],
      )!,
      osVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os_version'],
      )!,
      audioRetained: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}audio_retained'],
      )!,
    );
  }

  @override
  $ScansTable createAlias(String alias) {
    return $ScansTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<ScanQuality, String, String> $converterquality =
      const EnumNameConverter<ScanQuality>(ScanQuality.values);
  static TypeConverter<List<QualityReason>, String> $converterqualityReasons =
      const QualityReasonsConverter();
  static JsonTypeConverter2<Classification, String, String> $converterresult =
      const EnumNameConverter<Classification>(Classification.values);
}

class ScanRow extends DataClass implements Insertable<ScanRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String itemId;
  final DateTime capturedAt;
  final int durationMs;
  final int sampleRate;
  final ScanQuality quality;

  /// Comma-separated [QualityReason] names, empty when none.
  final List<QualityReason> qualityReasons;
  final String modelVersion;

  /// Predicted class. Never derived from, or written to, an inspection.
  final Classification result;
  final double? confidence;
  final bool experimental;
  final int latencyMs;
  final String deviceModel;
  final String osVersion;

  /// Whether the engine kept the WAV for this scan (v2). Immutable.
  final bool audioRetained;
  const ScanRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.itemId,
    required this.capturedAt,
    required this.durationMs,
    required this.sampleRate,
    required this.quality,
    required this.qualityReasons,
    required this.modelVersion,
    required this.result,
    this.confidence,
    required this.experimental,
    required this.latencyMs,
    required this.deviceModel,
    required this.osVersion,
    required this.audioRetained,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $ScansTable.$convertersyncState.toSql(syncState),
      );
    }
    map['item_id'] = Variable<String>(itemId);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['duration_ms'] = Variable<int>(durationMs);
    map['sample_rate'] = Variable<int>(sampleRate);
    {
      map['quality'] = Variable<String>(
        $ScansTable.$converterquality.toSql(quality),
      );
    }
    {
      map['quality_reasons'] = Variable<String>(
        $ScansTable.$converterqualityReasons.toSql(qualityReasons),
      );
    }
    map['model_version'] = Variable<String>(modelVersion);
    {
      map['result'] = Variable<String>(
        $ScansTable.$converterresult.toSql(result),
      );
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    map['experimental'] = Variable<bool>(experimental);
    map['latency_ms'] = Variable<int>(latencyMs);
    map['device_model'] = Variable<String>(deviceModel);
    map['os_version'] = Variable<String>(osVersion);
    map['audio_retained'] = Variable<bool>(audioRetained);
    return map;
  }

  ScansCompanion toCompanion(bool nullToAbsent) {
    return ScansCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      itemId: Value(itemId),
      capturedAt: Value(capturedAt),
      durationMs: Value(durationMs),
      sampleRate: Value(sampleRate),
      quality: Value(quality),
      qualityReasons: Value(qualityReasons),
      modelVersion: Value(modelVersion),
      result: Value(result),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      experimental: Value(experimental),
      latencyMs: Value(latencyMs),
      deviceModel: Value(deviceModel),
      osVersion: Value(osVersion),
      audioRetained: Value(audioRetained),
    );
  }

  factory ScanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $ScansTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      itemId: serializer.fromJson<String>(json['itemId']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      sampleRate: serializer.fromJson<int>(json['sampleRate']),
      quality: $ScansTable.$converterquality.fromJson(
        serializer.fromJson<String>(json['quality']),
      ),
      qualityReasons: serializer.fromJson<List<QualityReason>>(
        json['qualityReasons'],
      ),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      result: $ScansTable.$converterresult.fromJson(
        serializer.fromJson<String>(json['result']),
      ),
      confidence: serializer.fromJson<double?>(json['confidence']),
      experimental: serializer.fromJson<bool>(json['experimental']),
      latencyMs: serializer.fromJson<int>(json['latencyMs']),
      deviceModel: serializer.fromJson<String>(json['deviceModel']),
      osVersion: serializer.fromJson<String>(json['osVersion']),
      audioRetained: serializer.fromJson<bool>(json['audioRetained']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $ScansTable.$convertersyncState.toJson(syncState),
      ),
      'itemId': serializer.toJson<String>(itemId),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'sampleRate': serializer.toJson<int>(sampleRate),
      'quality': serializer.toJson<String>(
        $ScansTable.$converterquality.toJson(quality),
      ),
      'qualityReasons': serializer.toJson<List<QualityReason>>(qualityReasons),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'result': serializer.toJson<String>(
        $ScansTable.$converterresult.toJson(result),
      ),
      'confidence': serializer.toJson<double?>(confidence),
      'experimental': serializer.toJson<bool>(experimental),
      'latencyMs': serializer.toJson<int>(latencyMs),
      'deviceModel': serializer.toJson<String>(deviceModel),
      'osVersion': serializer.toJson<String>(osVersion),
      'audioRetained': serializer.toJson<bool>(audioRetained),
    };
  }

  ScanRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? itemId,
    DateTime? capturedAt,
    int? durationMs,
    int? sampleRate,
    ScanQuality? quality,
    List<QualityReason>? qualityReasons,
    String? modelVersion,
    Classification? result,
    Value<double?> confidence = const Value.absent(),
    bool? experimental,
    int? latencyMs,
    String? deviceModel,
    String? osVersion,
    bool? audioRetained,
  }) => ScanRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    itemId: itemId ?? this.itemId,
    capturedAt: capturedAt ?? this.capturedAt,
    durationMs: durationMs ?? this.durationMs,
    sampleRate: sampleRate ?? this.sampleRate,
    quality: quality ?? this.quality,
    qualityReasons: qualityReasons ?? this.qualityReasons,
    modelVersion: modelVersion ?? this.modelVersion,
    result: result ?? this.result,
    confidence: confidence.present ? confidence.value : this.confidence,
    experimental: experimental ?? this.experimental,
    latencyMs: latencyMs ?? this.latencyMs,
    deviceModel: deviceModel ?? this.deviceModel,
    osVersion: osVersion ?? this.osVersion,
    audioRetained: audioRetained ?? this.audioRetained,
  );
  ScanRow copyWithCompanion(ScansCompanion data) {
    return ScanRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sampleRate: data.sampleRate.present
          ? data.sampleRate.value
          : this.sampleRate,
      quality: data.quality.present ? data.quality.value : this.quality,
      qualityReasons: data.qualityReasons.present
          ? data.qualityReasons.value
          : this.qualityReasons,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      result: data.result.present ? data.result.value : this.result,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      experimental: data.experimental.present
          ? data.experimental.value
          : this.experimental,
      latencyMs: data.latencyMs.present ? data.latencyMs.value : this.latencyMs,
      deviceModel: data.deviceModel.present
          ? data.deviceModel.value
          : this.deviceModel,
      osVersion: data.osVersion.present ? data.osVersion.value : this.osVersion,
      audioRetained: data.audioRetained.present
          ? data.audioRetained.value
          : this.audioRetained,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('itemId: $itemId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('quality: $quality, ')
          ..write('qualityReasons: $qualityReasons, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('result: $result, ')
          ..write('confidence: $confidence, ')
          ..write('experimental: $experimental, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('osVersion: $osVersion, ')
          ..write('audioRetained: $audioRetained')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    itemId,
    capturedAt,
    durationMs,
    sampleRate,
    quality,
    qualityReasons,
    modelVersion,
    result,
    confidence,
    experimental,
    latencyMs,
    deviceModel,
    osVersion,
    audioRetained,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.itemId == this.itemId &&
          other.capturedAt == this.capturedAt &&
          other.durationMs == this.durationMs &&
          other.sampleRate == this.sampleRate &&
          other.quality == this.quality &&
          other.qualityReasons == this.qualityReasons &&
          other.modelVersion == this.modelVersion &&
          other.result == this.result &&
          other.confidence == this.confidence &&
          other.experimental == this.experimental &&
          other.latencyMs == this.latencyMs &&
          other.deviceModel == this.deviceModel &&
          other.osVersion == this.osVersion &&
          other.audioRetained == this.audioRetained);
}

class ScansCompanion extends UpdateCompanion<ScanRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> itemId;
  final Value<DateTime> capturedAt;
  final Value<int> durationMs;
  final Value<int> sampleRate;
  final Value<ScanQuality> quality;
  final Value<List<QualityReason>> qualityReasons;
  final Value<String> modelVersion;
  final Value<Classification> result;
  final Value<double?> confidence;
  final Value<bool> experimental;
  final Value<int> latencyMs;
  final Value<String> deviceModel;
  final Value<String> osVersion;
  final Value<bool> audioRetained;
  final Value<int> rowid;
  const ScansCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.itemId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.quality = const Value.absent(),
    this.qualityReasons = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.result = const Value.absent(),
    this.confidence = const Value.absent(),
    this.experimental = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.deviceModel = const Value.absent(),
    this.osVersion = const Value.absent(),
    this.audioRetained = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScansCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String itemId,
    required DateTime capturedAt,
    required int durationMs,
    required int sampleRate,
    required ScanQuality quality,
    required List<QualityReason> qualityReasons,
    required String modelVersion,
    required Classification result,
    this.confidence = const Value.absent(),
    required bool experimental,
    required int latencyMs,
    required String deviceModel,
    required String osVersion,
    this.audioRetained = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       itemId = Value(itemId),
       capturedAt = Value(capturedAt),
       durationMs = Value(durationMs),
       sampleRate = Value(sampleRate),
       quality = Value(quality),
       qualityReasons = Value(qualityReasons),
       modelVersion = Value(modelVersion),
       result = Value(result),
       experimental = Value(experimental),
       latencyMs = Value(latencyMs),
       deviceModel = Value(deviceModel),
       osVersion = Value(osVersion);
  static Insertable<ScanRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? itemId,
    Expression<DateTime>? capturedAt,
    Expression<int>? durationMs,
    Expression<int>? sampleRate,
    Expression<String>? quality,
    Expression<String>? qualityReasons,
    Expression<String>? modelVersion,
    Expression<String>? result,
    Expression<double>? confidence,
    Expression<bool>? experimental,
    Expression<int>? latencyMs,
    Expression<String>? deviceModel,
    Expression<String>? osVersion,
    Expression<bool>? audioRetained,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (itemId != null) 'item_id': itemId,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (quality != null) 'quality': quality,
      if (qualityReasons != null) 'quality_reasons': qualityReasons,
      if (modelVersion != null) 'model_version': modelVersion,
      if (result != null) 'result': result,
      if (confidence != null) 'confidence': confidence,
      if (experimental != null) 'experimental': experimental,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (deviceModel != null) 'device_model': deviceModel,
      if (osVersion != null) 'os_version': osVersion,
      if (audioRetained != null) 'audio_retained': audioRetained,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScansCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? itemId,
    Value<DateTime>? capturedAt,
    Value<int>? durationMs,
    Value<int>? sampleRate,
    Value<ScanQuality>? quality,
    Value<List<QualityReason>>? qualityReasons,
    Value<String>? modelVersion,
    Value<Classification>? result,
    Value<double?>? confidence,
    Value<bool>? experimental,
    Value<int>? latencyMs,
    Value<String>? deviceModel,
    Value<String>? osVersion,
    Value<bool>? audioRetained,
    Value<int>? rowid,
  }) {
    return ScansCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      itemId: itemId ?? this.itemId,
      capturedAt: capturedAt ?? this.capturedAt,
      durationMs: durationMs ?? this.durationMs,
      sampleRate: sampleRate ?? this.sampleRate,
      quality: quality ?? this.quality,
      qualityReasons: qualityReasons ?? this.qualityReasons,
      modelVersion: modelVersion ?? this.modelVersion,
      result: result ?? this.result,
      confidence: confidence ?? this.confidence,
      experimental: experimental ?? this.experimental,
      latencyMs: latencyMs ?? this.latencyMs,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      audioRetained: audioRetained ?? this.audioRetained,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $ScansTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(
        $ScansTable.$converterquality.toSql(quality.value),
      );
    }
    if (qualityReasons.present) {
      map['quality_reasons'] = Variable<String>(
        $ScansTable.$converterqualityReasons.toSql(qualityReasons.value),
      );
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $ScansTable.$converterresult.toSql(result.value),
      );
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (experimental.present) {
      map['experimental'] = Variable<bool>(experimental.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (deviceModel.present) {
      map['device_model'] = Variable<String>(deviceModel.value);
    }
    if (osVersion.present) {
      map['os_version'] = Variable<String>(osVersion.value);
    }
    if (audioRetained.present) {
      map['audio_retained'] = Variable<bool>(audioRetained.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScansCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('itemId: $itemId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('quality: $quality, ')
          ..write('qualityReasons: $qualityReasons, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('result: $result, ')
          ..write('confidence: $confidence, ')
          ..write('experimental: $experimental, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('osVersion: $osVersion, ')
          ..write('audioRetained: $audioRetained, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InspectionsTable extends Inspections
    with TableInfo<$InspectionsTable, InspectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($InspectionsTable.$convertersyncState);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scans (id)',
    ),
  );
  static const VerificationMeta _inspectedAtMeta = const VerificationMeta(
    'inspectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> inspectedAt = GeneratedColumn<DateTime>(
    'inspected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inspectorMeta = const VerificationMeta(
    'inspector',
  );
  @override
  late final GeneratedColumn<String> inspector = GeneratedColumn<String>(
    'inspector',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observationsMeta = const VerificationMeta(
    'observations',
  );
  @override
  late final GeneratedColumn<String> observations = GeneratedColumn<String>(
    'observations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VerifiedFinding, String>
  verifiedFinding = GeneratedColumn<String>(
    'verified_finding',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<VerifiedFinding>($InspectionsTable.$converterverifiedFinding);
  @override
  late final GeneratedColumnWithTypeConverter<FollowUpStatus, String>
  followUpStatus = GeneratedColumn<String>(
    'follow_up_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FollowUpStatus>($InspectionsTable.$converterfollowUpStatus);
  static const VerificationMeta _assignedToMeta = const VerificationMeta(
    'assignedTo',
  );
  @override
  late final GeneratedColumn<String> assignedTo = GeneratedColumn<String>(
    'assigned_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> photoPaths =
      GeneratedColumn<String>(
        'photo_paths',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($InspectionsTable.$converterphotoPaths);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    itemId,
    scanId,
    inspectedAt,
    inspector,
    observations,
    verifiedFinding,
    followUpStatus,
    assignedTo,
    photoPaths,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspections';
  @override
  VerificationContext validateIntegrity(
    Insertable<InspectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    }
    if (data.containsKey('inspected_at')) {
      context.handle(
        _inspectedAtMeta,
        inspectedAt.isAcceptableOrUnknown(
          data['inspected_at']!,
          _inspectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inspectedAtMeta);
    }
    if (data.containsKey('inspector')) {
      context.handle(
        _inspectorMeta,
        inspector.isAcceptableOrUnknown(data['inspector']!, _inspectorMeta),
      );
    } else if (isInserting) {
      context.missing(_inspectorMeta);
    }
    if (data.containsKey('observations')) {
      context.handle(
        _observationsMeta,
        observations.isAcceptableOrUnknown(
          data['observations']!,
          _observationsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_observationsMeta);
    }
    if (data.containsKey('assigned_to')) {
      context.handle(
        _assignedToMeta,
        assignedTo.isAcceptableOrUnknown(data['assigned_to']!, _assignedToMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InspectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InspectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $InspectionsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      ),
      inspectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}inspected_at'],
      )!,
      inspector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspector'],
      )!,
      observations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observations'],
      )!,
      verifiedFinding: $InspectionsTable.$converterverifiedFinding.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}verified_finding'],
        )!,
      ),
      followUpStatus: $InspectionsTable.$converterfollowUpStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}follow_up_status'],
        )!,
      ),
      assignedTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_to'],
      ),
      photoPaths: $InspectionsTable.$converterphotoPaths.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}photo_paths'],
        )!,
      ),
    );
  }

  @override
  $InspectionsTable createAlias(String alias) {
    return $InspectionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<VerifiedFinding, String, String>
  $converterverifiedFinding = const EnumNameConverter<VerifiedFinding>(
    VerifiedFinding.values,
  );
  static JsonTypeConverter2<FollowUpStatus, String, String>
  $converterfollowUpStatus = const EnumNameConverter<FollowUpStatus>(
    FollowUpStatus.values,
  );
  static TypeConverter<List<String>, String> $converterphotoPaths =
      const StringListConverter();
}

class InspectionRow extends DataClass implements Insertable<InspectionRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String itemId;
  final String? scanId;
  final DateTime inspectedAt;
  final String inspector;
  final String observations;

  /// Human-verified finding. Never derived from a scan result.
  final VerifiedFinding verifiedFinding;
  final FollowUpStatus followUpStatus;

  /// Staff member responsible for the follow-up (v2). Updatable.
  final String? assignedTo;

  /// App-private evidence photo paths as a JSON array (v2). Part of the
  /// immutable inspection record.
  final List<String> photoPaths;
  const InspectionRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.itemId,
    this.scanId,
    required this.inspectedAt,
    required this.inspector,
    required this.observations,
    required this.verifiedFinding,
    required this.followUpStatus,
    this.assignedTo,
    required this.photoPaths,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $InspectionsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || scanId != null) {
      map['scan_id'] = Variable<String>(scanId);
    }
    map['inspected_at'] = Variable<DateTime>(inspectedAt);
    map['inspector'] = Variable<String>(inspector);
    map['observations'] = Variable<String>(observations);
    {
      map['verified_finding'] = Variable<String>(
        $InspectionsTable.$converterverifiedFinding.toSql(verifiedFinding),
      );
    }
    {
      map['follow_up_status'] = Variable<String>(
        $InspectionsTable.$converterfollowUpStatus.toSql(followUpStatus),
      );
    }
    if (!nullToAbsent || assignedTo != null) {
      map['assigned_to'] = Variable<String>(assignedTo);
    }
    {
      map['photo_paths'] = Variable<String>(
        $InspectionsTable.$converterphotoPaths.toSql(photoPaths),
      );
    }
    return map;
  }

  InspectionsCompanion toCompanion(bool nullToAbsent) {
    return InspectionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      itemId: Value(itemId),
      scanId: scanId == null && nullToAbsent
          ? const Value.absent()
          : Value(scanId),
      inspectedAt: Value(inspectedAt),
      inspector: Value(inspector),
      observations: Value(observations),
      verifiedFinding: Value(verifiedFinding),
      followUpStatus: Value(followUpStatus),
      assignedTo: assignedTo == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedTo),
      photoPaths: Value(photoPaths),
    );
  }

  factory InspectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InspectionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $InspectionsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      itemId: serializer.fromJson<String>(json['itemId']),
      scanId: serializer.fromJson<String?>(json['scanId']),
      inspectedAt: serializer.fromJson<DateTime>(json['inspectedAt']),
      inspector: serializer.fromJson<String>(json['inspector']),
      observations: serializer.fromJson<String>(json['observations']),
      verifiedFinding: $InspectionsTable.$converterverifiedFinding.fromJson(
        serializer.fromJson<String>(json['verifiedFinding']),
      ),
      followUpStatus: $InspectionsTable.$converterfollowUpStatus.fromJson(
        serializer.fromJson<String>(json['followUpStatus']),
      ),
      assignedTo: serializer.fromJson<String?>(json['assignedTo']),
      photoPaths: serializer.fromJson<List<String>>(json['photoPaths']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $InspectionsTable.$convertersyncState.toJson(syncState),
      ),
      'itemId': serializer.toJson<String>(itemId),
      'scanId': serializer.toJson<String?>(scanId),
      'inspectedAt': serializer.toJson<DateTime>(inspectedAt),
      'inspector': serializer.toJson<String>(inspector),
      'observations': serializer.toJson<String>(observations),
      'verifiedFinding': serializer.toJson<String>(
        $InspectionsTable.$converterverifiedFinding.toJson(verifiedFinding),
      ),
      'followUpStatus': serializer.toJson<String>(
        $InspectionsTable.$converterfollowUpStatus.toJson(followUpStatus),
      ),
      'assignedTo': serializer.toJson<String?>(assignedTo),
      'photoPaths': serializer.toJson<List<String>>(photoPaths),
    };
  }

  InspectionRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? itemId,
    Value<String?> scanId = const Value.absent(),
    DateTime? inspectedAt,
    String? inspector,
    String? observations,
    VerifiedFinding? verifiedFinding,
    FollowUpStatus? followUpStatus,
    Value<String?> assignedTo = const Value.absent(),
    List<String>? photoPaths,
  }) => InspectionRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    itemId: itemId ?? this.itemId,
    scanId: scanId.present ? scanId.value : this.scanId,
    inspectedAt: inspectedAt ?? this.inspectedAt,
    inspector: inspector ?? this.inspector,
    observations: observations ?? this.observations,
    verifiedFinding: verifiedFinding ?? this.verifiedFinding,
    followUpStatus: followUpStatus ?? this.followUpStatus,
    assignedTo: assignedTo.present ? assignedTo.value : this.assignedTo,
    photoPaths: photoPaths ?? this.photoPaths,
  );
  InspectionRow copyWithCompanion(InspectionsCompanion data) {
    return InspectionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      inspectedAt: data.inspectedAt.present
          ? data.inspectedAt.value
          : this.inspectedAt,
      inspector: data.inspector.present ? data.inspector.value : this.inspector,
      observations: data.observations.present
          ? data.observations.value
          : this.observations,
      verifiedFinding: data.verifiedFinding.present
          ? data.verifiedFinding.value
          : this.verifiedFinding,
      followUpStatus: data.followUpStatus.present
          ? data.followUpStatus.value
          : this.followUpStatus,
      assignedTo: data.assignedTo.present
          ? data.assignedTo.value
          : this.assignedTo,
      photoPaths: data.photoPaths.present
          ? data.photoPaths.value
          : this.photoPaths,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InspectionRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('itemId: $itemId, ')
          ..write('scanId: $scanId, ')
          ..write('inspectedAt: $inspectedAt, ')
          ..write('inspector: $inspector, ')
          ..write('observations: $observations, ')
          ..write('verifiedFinding: $verifiedFinding, ')
          ..write('followUpStatus: $followUpStatus, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('photoPaths: $photoPaths')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    itemId,
    scanId,
    inspectedAt,
    inspector,
    observations,
    verifiedFinding,
    followUpStatus,
    assignedTo,
    photoPaths,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InspectionRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.itemId == this.itemId &&
          other.scanId == this.scanId &&
          other.inspectedAt == this.inspectedAt &&
          other.inspector == this.inspector &&
          other.observations == this.observations &&
          other.verifiedFinding == this.verifiedFinding &&
          other.followUpStatus == this.followUpStatus &&
          other.assignedTo == this.assignedTo &&
          other.photoPaths == this.photoPaths);
}

class InspectionsCompanion extends UpdateCompanion<InspectionRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> itemId;
  final Value<String?> scanId;
  final Value<DateTime> inspectedAt;
  final Value<String> inspector;
  final Value<String> observations;
  final Value<VerifiedFinding> verifiedFinding;
  final Value<FollowUpStatus> followUpStatus;
  final Value<String?> assignedTo;
  final Value<List<String>> photoPaths;
  final Value<int> rowid;
  const InspectionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.itemId = const Value.absent(),
    this.scanId = const Value.absent(),
    this.inspectedAt = const Value.absent(),
    this.inspector = const Value.absent(),
    this.observations = const Value.absent(),
    this.verifiedFinding = const Value.absent(),
    this.followUpStatus = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.photoPaths = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String itemId,
    this.scanId = const Value.absent(),
    required DateTime inspectedAt,
    required String inspector,
    required String observations,
    required VerifiedFinding verifiedFinding,
    required FollowUpStatus followUpStatus,
    this.assignedTo = const Value.absent(),
    this.photoPaths = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       itemId = Value(itemId),
       inspectedAt = Value(inspectedAt),
       inspector = Value(inspector),
       observations = Value(observations),
       verifiedFinding = Value(verifiedFinding),
       followUpStatus = Value(followUpStatus);
  static Insertable<InspectionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? itemId,
    Expression<String>? scanId,
    Expression<DateTime>? inspectedAt,
    Expression<String>? inspector,
    Expression<String>? observations,
    Expression<String>? verifiedFinding,
    Expression<String>? followUpStatus,
    Expression<String>? assignedTo,
    Expression<String>? photoPaths,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (itemId != null) 'item_id': itemId,
      if (scanId != null) 'scan_id': scanId,
      if (inspectedAt != null) 'inspected_at': inspectedAt,
      if (inspector != null) 'inspector': inspector,
      if (observations != null) 'observations': observations,
      if (verifiedFinding != null) 'verified_finding': verifiedFinding,
      if (followUpStatus != null) 'follow_up_status': followUpStatus,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (photoPaths != null) 'photo_paths': photoPaths,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? itemId,
    Value<String?>? scanId,
    Value<DateTime>? inspectedAt,
    Value<String>? inspector,
    Value<String>? observations,
    Value<VerifiedFinding>? verifiedFinding,
    Value<FollowUpStatus>? followUpStatus,
    Value<String?>? assignedTo,
    Value<List<String>>? photoPaths,
    Value<int>? rowid,
  }) {
    return InspectionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      itemId: itemId ?? this.itemId,
      scanId: scanId ?? this.scanId,
      inspectedAt: inspectedAt ?? this.inspectedAt,
      inspector: inspector ?? this.inspector,
      observations: observations ?? this.observations,
      verifiedFinding: verifiedFinding ?? this.verifiedFinding,
      followUpStatus: followUpStatus ?? this.followUpStatus,
      assignedTo: assignedTo ?? this.assignedTo,
      photoPaths: photoPaths ?? this.photoPaths,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $InspectionsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (inspectedAt.present) {
      map['inspected_at'] = Variable<DateTime>(inspectedAt.value);
    }
    if (inspector.present) {
      map['inspector'] = Variable<String>(inspector.value);
    }
    if (observations.present) {
      map['observations'] = Variable<String>(observations.value);
    }
    if (verifiedFinding.present) {
      map['verified_finding'] = Variable<String>(
        $InspectionsTable.$converterverifiedFinding.toSql(
          verifiedFinding.value,
        ),
      );
    }
    if (followUpStatus.present) {
      map['follow_up_status'] = Variable<String>(
        $InspectionsTable.$converterfollowUpStatus.toSql(followUpStatus.value),
      );
    }
    if (assignedTo.present) {
      map['assigned_to'] = Variable<String>(assignedTo.value);
    }
    if (photoPaths.present) {
      map['photo_paths'] = Variable<String>(
        $InspectionsTable.$converterphotoPaths.toSql(photoPaths.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspectionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('itemId: $itemId, ')
          ..write('scanId: $scanId, ')
          ..write('inspectedAt: $inspectedAt, ')
          ..write('inspector: $inspector, ')
          ..write('observations: $observations, ')
          ..write('verifiedFinding: $verifiedFinding, ')
          ..write('followUpStatus: $followUpStatus, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('photoPaths: $photoPaths, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabeledSamplesTable extends LabeledSamples
    with TableInfo<$LabeledSamplesTable, LabeledSampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabeledSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($LabeledSamplesTable.$convertersyncState);
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES scans (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SampleLabel, String> label =
      GeneratedColumn<String>(
        'label',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SampleLabel>($LabeledSamplesTable.$converterlabel);
  static const VerificationMeta _inspectionIdMeta = const VerificationMeta(
    'inspectionId',
  );
  @override
  late final GeneratedColumn<String> inspectionId = GeneratedColumn<String>(
    'inspection_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inspections (id)',
    ),
  );
  static const VerificationMeta _grainTypeMeta = const VerificationMeta(
    'grainType',
  );
  @override
  late final GeneratedColumn<String> grainType = GeneratedColumn<String>(
    'grain_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sackMaterialMeta = const VerificationMeta(
    'sackMaterial',
  );
  @override
  late final GeneratedColumn<String> sackMaterial = GeneratedColumn<String>(
    'sack_material',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _environmentMeta = const VerificationMeta(
    'environment',
  );
  @override
  late final GeneratedColumn<String> environment = GeneratedColumn<String>(
    'environment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    scanId,
    itemId,
    label,
    inspectionId,
    grainType,
    sackMaterial,
    environment,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'labeled_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabeledSampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('inspection_id')) {
      context.handle(
        _inspectionIdMeta,
        inspectionId.isAcceptableOrUnknown(
          data['inspection_id']!,
          _inspectionIdMeta,
        ),
      );
    }
    if (data.containsKey('grain_type')) {
      context.handle(
        _grainTypeMeta,
        grainType.isAcceptableOrUnknown(data['grain_type']!, _grainTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_grainTypeMeta);
    }
    if (data.containsKey('sack_material')) {
      context.handle(
        _sackMaterialMeta,
        sackMaterial.isAcceptableOrUnknown(
          data['sack_material']!,
          _sackMaterialMeta,
        ),
      );
    }
    if (data.containsKey('environment')) {
      context.handle(
        _environmentMeta,
        environment.isAcceptableOrUnknown(
          data['environment']!,
          _environmentMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LabeledSampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabeledSampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $LabeledSamplesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      label: $LabeledSamplesTable.$converterlabel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}label'],
        )!,
      ),
      inspectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspection_id'],
      ),
      grainType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grain_type'],
      )!,
      sackMaterial: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sack_material'],
      ),
      environment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $LabeledSamplesTable createAlias(String alias) {
    return $LabeledSamplesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<SampleLabel, String, String> $converterlabel =
      const EnumNameConverter<SampleLabel>(SampleLabel.values);
}

class LabeledSampleRow extends DataClass
    implements Insertable<LabeledSampleRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String scanId;
  final String itemId;
  final SampleLabel label;
  final String? inspectionId;
  final String grainType;
  final String? sackMaterial;
  final String? environment;
  final String? notes;
  const LabeledSampleRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.scanId,
    required this.itemId,
    required this.label,
    this.inspectionId,
    required this.grainType,
    this.sackMaterial,
    this.environment,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $LabeledSamplesTable.$convertersyncState.toSql(syncState),
      );
    }
    map['scan_id'] = Variable<String>(scanId);
    map['item_id'] = Variable<String>(itemId);
    {
      map['label'] = Variable<String>(
        $LabeledSamplesTable.$converterlabel.toSql(label),
      );
    }
    if (!nullToAbsent || inspectionId != null) {
      map['inspection_id'] = Variable<String>(inspectionId);
    }
    map['grain_type'] = Variable<String>(grainType);
    if (!nullToAbsent || sackMaterial != null) {
      map['sack_material'] = Variable<String>(sackMaterial);
    }
    if (!nullToAbsent || environment != null) {
      map['environment'] = Variable<String>(environment);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  LabeledSamplesCompanion toCompanion(bool nullToAbsent) {
    return LabeledSamplesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      scanId: Value(scanId),
      itemId: Value(itemId),
      label: Value(label),
      inspectionId: inspectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(inspectionId),
      grainType: Value(grainType),
      sackMaterial: sackMaterial == null && nullToAbsent
          ? const Value.absent()
          : Value(sackMaterial),
      environment: environment == null && nullToAbsent
          ? const Value.absent()
          : Value(environment),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory LabeledSampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabeledSampleRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $LabeledSamplesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      scanId: serializer.fromJson<String>(json['scanId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      label: $LabeledSamplesTable.$converterlabel.fromJson(
        serializer.fromJson<String>(json['label']),
      ),
      inspectionId: serializer.fromJson<String?>(json['inspectionId']),
      grainType: serializer.fromJson<String>(json['grainType']),
      sackMaterial: serializer.fromJson<String?>(json['sackMaterial']),
      environment: serializer.fromJson<String?>(json['environment']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $LabeledSamplesTable.$convertersyncState.toJson(syncState),
      ),
      'scanId': serializer.toJson<String>(scanId),
      'itemId': serializer.toJson<String>(itemId),
      'label': serializer.toJson<String>(
        $LabeledSamplesTable.$converterlabel.toJson(label),
      ),
      'inspectionId': serializer.toJson<String?>(inspectionId),
      'grainType': serializer.toJson<String>(grainType),
      'sackMaterial': serializer.toJson<String?>(sackMaterial),
      'environment': serializer.toJson<String?>(environment),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  LabeledSampleRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? scanId,
    String? itemId,
    SampleLabel? label,
    Value<String?> inspectionId = const Value.absent(),
    String? grainType,
    Value<String?> sackMaterial = const Value.absent(),
    Value<String?> environment = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => LabeledSampleRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    scanId: scanId ?? this.scanId,
    itemId: itemId ?? this.itemId,
    label: label ?? this.label,
    inspectionId: inspectionId.present ? inspectionId.value : this.inspectionId,
    grainType: grainType ?? this.grainType,
    sackMaterial: sackMaterial.present ? sackMaterial.value : this.sackMaterial,
    environment: environment.present ? environment.value : this.environment,
    notes: notes.present ? notes.value : this.notes,
  );
  LabeledSampleRow copyWithCompanion(LabeledSamplesCompanion data) {
    return LabeledSampleRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      label: data.label.present ? data.label.value : this.label,
      inspectionId: data.inspectionId.present
          ? data.inspectionId.value
          : this.inspectionId,
      grainType: data.grainType.present ? data.grainType.value : this.grainType,
      sackMaterial: data.sackMaterial.present
          ? data.sackMaterial.value
          : this.sackMaterial,
      environment: data.environment.present
          ? data.environment.value
          : this.environment,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabeledSampleRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('scanId: $scanId, ')
          ..write('itemId: $itemId, ')
          ..write('label: $label, ')
          ..write('inspectionId: $inspectionId, ')
          ..write('grainType: $grainType, ')
          ..write('sackMaterial: $sackMaterial, ')
          ..write('environment: $environment, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    scanId,
    itemId,
    label,
    inspectionId,
    grainType,
    sackMaterial,
    environment,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabeledSampleRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.scanId == this.scanId &&
          other.itemId == this.itemId &&
          other.label == this.label &&
          other.inspectionId == this.inspectionId &&
          other.grainType == this.grainType &&
          other.sackMaterial == this.sackMaterial &&
          other.environment == this.environment &&
          other.notes == this.notes);
}

class LabeledSamplesCompanion extends UpdateCompanion<LabeledSampleRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> scanId;
  final Value<String> itemId;
  final Value<SampleLabel> label;
  final Value<String?> inspectionId;
  final Value<String> grainType;
  final Value<String?> sackMaterial;
  final Value<String?> environment;
  final Value<String?> notes;
  final Value<int> rowid;
  const LabeledSamplesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.scanId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.label = const Value.absent(),
    this.inspectionId = const Value.absent(),
    this.grainType = const Value.absent(),
    this.sackMaterial = const Value.absent(),
    this.environment = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabeledSamplesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String scanId,
    required String itemId,
    required SampleLabel label,
    this.inspectionId = const Value.absent(),
    required String grainType,
    this.sackMaterial = const Value.absent(),
    this.environment = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       scanId = Value(scanId),
       itemId = Value(itemId),
       label = Value(label),
       grainType = Value(grainType);
  static Insertable<LabeledSampleRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? scanId,
    Expression<String>? itemId,
    Expression<String>? label,
    Expression<String>? inspectionId,
    Expression<String>? grainType,
    Expression<String>? sackMaterial,
    Expression<String>? environment,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (scanId != null) 'scan_id': scanId,
      if (itemId != null) 'item_id': itemId,
      if (label != null) 'label': label,
      if (inspectionId != null) 'inspection_id': inspectionId,
      if (grainType != null) 'grain_type': grainType,
      if (sackMaterial != null) 'sack_material': sackMaterial,
      if (environment != null) 'environment': environment,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabeledSamplesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? scanId,
    Value<String>? itemId,
    Value<SampleLabel>? label,
    Value<String?>? inspectionId,
    Value<String>? grainType,
    Value<String?>? sackMaterial,
    Value<String?>? environment,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return LabeledSamplesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      scanId: scanId ?? this.scanId,
      itemId: itemId ?? this.itemId,
      label: label ?? this.label,
      inspectionId: inspectionId ?? this.inspectionId,
      grainType: grainType ?? this.grainType,
      sackMaterial: sackMaterial ?? this.sackMaterial,
      environment: environment ?? this.environment,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $LabeledSamplesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(
        $LabeledSamplesTable.$converterlabel.toSql(label.value),
      );
    }
    if (inspectionId.present) {
      map['inspection_id'] = Variable<String>(inspectionId.value);
    }
    if (grainType.present) {
      map['grain_type'] = Variable<String>(grainType.value);
    }
    if (sackMaterial.present) {
      map['sack_material'] = Variable<String>(sackMaterial.value);
    }
    if (environment.present) {
      map['environment'] = Variable<String>(environment.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabeledSamplesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('scanId: $scanId, ')
          ..write('itemId: $itemId, ')
          ..write('label: $label, ')
          ..write('inspectionId: $inspectionId, ')
          ..write('grainType: $grainType, ')
          ..write('sackMaterial: $sackMaterial, ')
          ..write('environment: $environment, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SightingsTable extends Sightings
    with TableInfo<$SightingsTable, SightingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SightingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($SightingsTable.$convertersyncState);
  @override
  late final GeneratedColumnWithTypeConverter<Role, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Role>($SightingsTable.$converterrole);
  @override
  late final GeneratedColumnWithTypeConverter<SignalSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SignalSource>($SightingsTable.$convertersource);
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES locations (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMetersMeta = const VerificationMeta(
    'accuracyMeters',
  );
  @override
  late final GeneratedColumn<double> accuracyMeters = GeneratedColumn<double>(
    'accuracy_meters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DistanceEstimate?, String>
  distance = GeneratedColumn<String>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DistanceEstimate?>($SightingsTable.$converterdistancen);
  @override
  late final GeneratedColumnWithTypeConverter<PestAnalysis?, String> analysis =
      GeneratedColumn<String>(
        'analysis',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<PestAnalysis?>($SightingsTable.$converteranalysisn);
  @override
  late final GeneratedColumnWithTypeConverter<SoundAnalysis?, String> sound =
      GeneratedColumn<String>(
        'sound',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SoundAnalysis?>($SightingsTable.$convertersoundn);
  static const VerificationMeta _userValidatedMeta = const VerificationMeta(
    'userValidated',
  );
  @override
  late final GeneratedColumn<bool> userValidated = GeneratedColumn<bool>(
    'user_validated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_validated" IN (0, 1))',
    ),
  );
  static const VerificationMeta _userCardIdMeta = const VerificationMeta(
    'userCardId',
  );
  @override
  late final GeneratedColumn<String> userCardId = GeneratedColumn<String>(
    'user_card_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VerifiedFinding?, String>
  verifiedFinding = GeneratedColumn<String>(
    'verified_finding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<VerifiedFinding?>($SightingsTable.$converterverifiedFindingn);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaPathMeta = const VerificationMeta(
    'mediaPath',
  );
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
    'media_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    role,
    source,
    observedAt,
    locationId,
    itemId,
    latitude,
    longitude,
    accuracyMeters,
    distance,
    analysis,
    sound,
    userValidated,
    userCardId,
    verifiedFinding,
    notes,
    mediaPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sightings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SightingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('accuracy_meters')) {
      context.handle(
        _accuracyMetersMeta,
        accuracyMeters.isAcceptableOrUnknown(
          data['accuracy_meters']!,
          _accuracyMetersMeta,
        ),
      );
    }
    if (data.containsKey('user_validated')) {
      context.handle(
        _userValidatedMeta,
        userValidated.isAcceptableOrUnknown(
          data['user_validated']!,
          _userValidatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userValidatedMeta);
    }
    if (data.containsKey('user_card_id')) {
      context.handle(
        _userCardIdMeta,
        userCardId.isAcceptableOrUnknown(
          data['user_card_id']!,
          _userCardIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('media_path')) {
      context.handle(
        _mediaPathMeta,
        mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SightingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SightingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $SightingsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      role: $SightingsTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      source: $SightingsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      accuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_meters'],
      ),
      distance: $SightingsTable.$converterdistancen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}distance'],
        ),
      ),
      analysis: $SightingsTable.$converteranalysisn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}analysis'],
        ),
      ),
      sound: $SightingsTable.$convertersoundn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sound'],
        ),
      ),
      userValidated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_validated'],
      )!,
      userCardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_card_id'],
      ),
      verifiedFinding: $SightingsTable.$converterverifiedFindingn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}verified_finding'],
        ),
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      mediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_path'],
      ),
    );
  }

  @override
  $SightingsTable createAlias(String alias) {
    return $SightingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<Role, String, String> $converterrole =
      const EnumNameConverter<Role>(Role.values);
  static JsonTypeConverter2<SignalSource, String, String> $convertersource =
      const EnumNameConverter<SignalSource>(SignalSource.values);
  static TypeConverter<DistanceEstimate, String> $converterdistance =
      const DistanceEstimateConverter();
  static TypeConverter<DistanceEstimate?, String?> $converterdistancen =
      NullAwareTypeConverter.wrap($converterdistance);
  static TypeConverter<PestAnalysis, String> $converteranalysis =
      const PestAnalysisConverter();
  static TypeConverter<PestAnalysis?, String?> $converteranalysisn =
      NullAwareTypeConverter.wrap($converteranalysis);
  static TypeConverter<SoundAnalysis, String> $convertersound =
      const SoundAnalysisConverter();
  static TypeConverter<SoundAnalysis?, String?> $convertersoundn =
      NullAwareTypeConverter.wrap($convertersound);
  static JsonTypeConverter2<VerifiedFinding, String, String>
  $converterverifiedFinding = const EnumNameConverter<VerifiedFinding>(
    VerifiedFinding.values,
  );
  static JsonTypeConverter2<VerifiedFinding?, String?, String?>
  $converterverifiedFindingn = JsonTypeConverter2.asNullable(
    $converterverifiedFinding,
  );
}

class SightingRow extends DataClass implements Insertable<SightingRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final Role role;
  final SignalSource source;
  final DateTime observedAt;
  final String? locationId;
  final String? itemId;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  /// DistanceEstimate as JSON.
  final DistanceEstimate? distance;

  /// PestAnalysis as JSON. Immutable.
  final PestAnalysis? analysis;

  /// SoundAnalysis as JSON. Immutable.
  final SoundAnalysis? sound;
  final bool userValidated;
  final String? userCardId;

  /// Human physical verification. Null until set once; never overwritten.
  final VerifiedFinding? verifiedFinding;
  final String? notes;

  /// App-private still or clip, only when the user chose to keep media.
  final String? mediaPath;
  const SightingRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.role,
    required this.source,
    required this.observedAt,
    this.locationId,
    this.itemId,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.distance,
    this.analysis,
    this.sound,
    required this.userValidated,
    this.userCardId,
    this.verifiedFinding,
    this.notes,
    this.mediaPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $SightingsTable.$convertersyncState.toSql(syncState),
      );
    }
    {
      map['role'] = Variable<String>(
        $SightingsTable.$converterrole.toSql(role),
      );
    }
    {
      map['source'] = Variable<String>(
        $SightingsTable.$convertersource.toSql(source),
      );
    }
    map['observed_at'] = Variable<DateTime>(observedAt);
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || accuracyMeters != null) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters);
    }
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<String>(
        $SightingsTable.$converterdistancen.toSql(distance),
      );
    }
    if (!nullToAbsent || analysis != null) {
      map['analysis'] = Variable<String>(
        $SightingsTable.$converteranalysisn.toSql(analysis),
      );
    }
    if (!nullToAbsent || sound != null) {
      map['sound'] = Variable<String>(
        $SightingsTable.$convertersoundn.toSql(sound),
      );
    }
    map['user_validated'] = Variable<bool>(userValidated);
    if (!nullToAbsent || userCardId != null) {
      map['user_card_id'] = Variable<String>(userCardId);
    }
    if (!nullToAbsent || verifiedFinding != null) {
      map['verified_finding'] = Variable<String>(
        $SightingsTable.$converterverifiedFindingn.toSql(verifiedFinding),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || mediaPath != null) {
      map['media_path'] = Variable<String>(mediaPath);
    }
    return map;
  }

  SightingsCompanion toCompanion(bool nullToAbsent) {
    return SightingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      role: Value(role),
      source: Value(source),
      observedAt: Value(observedAt),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      accuracyMeters: accuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyMeters),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      analysis: analysis == null && nullToAbsent
          ? const Value.absent()
          : Value(analysis),
      sound: sound == null && nullToAbsent
          ? const Value.absent()
          : Value(sound),
      userValidated: Value(userValidated),
      userCardId: userCardId == null && nullToAbsent
          ? const Value.absent()
          : Value(userCardId),
      verifiedFinding: verifiedFinding == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedFinding),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      mediaPath: mediaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaPath),
    );
  }

  factory SightingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SightingRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $SightingsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      role: $SightingsTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      source: $SightingsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      accuracyMeters: serializer.fromJson<double?>(json['accuracyMeters']),
      distance: serializer.fromJson<DistanceEstimate?>(json['distance']),
      analysis: serializer.fromJson<PestAnalysis?>(json['analysis']),
      sound: serializer.fromJson<SoundAnalysis?>(json['sound']),
      userValidated: serializer.fromJson<bool>(json['userValidated']),
      userCardId: serializer.fromJson<String?>(json['userCardId']),
      verifiedFinding: $SightingsTable.$converterverifiedFindingn.fromJson(
        serializer.fromJson<String?>(json['verifiedFinding']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      mediaPath: serializer.fromJson<String?>(json['mediaPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $SightingsTable.$convertersyncState.toJson(syncState),
      ),
      'role': serializer.toJson<String>(
        $SightingsTable.$converterrole.toJson(role),
      ),
      'source': serializer.toJson<String>(
        $SightingsTable.$convertersource.toJson(source),
      ),
      'observedAt': serializer.toJson<DateTime>(observedAt),
      'locationId': serializer.toJson<String?>(locationId),
      'itemId': serializer.toJson<String?>(itemId),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'accuracyMeters': serializer.toJson<double?>(accuracyMeters),
      'distance': serializer.toJson<DistanceEstimate?>(distance),
      'analysis': serializer.toJson<PestAnalysis?>(analysis),
      'sound': serializer.toJson<SoundAnalysis?>(sound),
      'userValidated': serializer.toJson<bool>(userValidated),
      'userCardId': serializer.toJson<String?>(userCardId),
      'verifiedFinding': serializer.toJson<String?>(
        $SightingsTable.$converterverifiedFindingn.toJson(verifiedFinding),
      ),
      'notes': serializer.toJson<String?>(notes),
      'mediaPath': serializer.toJson<String?>(mediaPath),
    };
  }

  SightingRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    Role? role,
    SignalSource? source,
    DateTime? observedAt,
    Value<String?> locationId = const Value.absent(),
    Value<String?> itemId = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<double?> accuracyMeters = const Value.absent(),
    Value<DistanceEstimate?> distance = const Value.absent(),
    Value<PestAnalysis?> analysis = const Value.absent(),
    Value<SoundAnalysis?> sound = const Value.absent(),
    bool? userValidated,
    Value<String?> userCardId = const Value.absent(),
    Value<VerifiedFinding?> verifiedFinding = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> mediaPath = const Value.absent(),
  }) => SightingRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    role: role ?? this.role,
    source: source ?? this.source,
    observedAt: observedAt ?? this.observedAt,
    locationId: locationId.present ? locationId.value : this.locationId,
    itemId: itemId.present ? itemId.value : this.itemId,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    accuracyMeters: accuracyMeters.present
        ? accuracyMeters.value
        : this.accuracyMeters,
    distance: distance.present ? distance.value : this.distance,
    analysis: analysis.present ? analysis.value : this.analysis,
    sound: sound.present ? sound.value : this.sound,
    userValidated: userValidated ?? this.userValidated,
    userCardId: userCardId.present ? userCardId.value : this.userCardId,
    verifiedFinding: verifiedFinding.present
        ? verifiedFinding.value
        : this.verifiedFinding,
    notes: notes.present ? notes.value : this.notes,
    mediaPath: mediaPath.present ? mediaPath.value : this.mediaPath,
  );
  SightingRow copyWithCompanion(SightingsCompanion data) {
    return SightingRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      role: data.role.present ? data.role.value : this.role,
      source: data.source.present ? data.source.value : this.source,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracyMeters: data.accuracyMeters.present
          ? data.accuracyMeters.value
          : this.accuracyMeters,
      distance: data.distance.present ? data.distance.value : this.distance,
      analysis: data.analysis.present ? data.analysis.value : this.analysis,
      sound: data.sound.present ? data.sound.value : this.sound,
      userValidated: data.userValidated.present
          ? data.userValidated.value
          : this.userValidated,
      userCardId: data.userCardId.present
          ? data.userCardId.value
          : this.userCardId,
      verifiedFinding: data.verifiedFinding.present
          ? data.verifiedFinding.value
          : this.verifiedFinding,
      notes: data.notes.present ? data.notes.value : this.notes,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SightingRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('role: $role, ')
          ..write('source: $source, ')
          ..write('observedAt: $observedAt, ')
          ..write('locationId: $locationId, ')
          ..write('itemId: $itemId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('distance: $distance, ')
          ..write('analysis: $analysis, ')
          ..write('sound: $sound, ')
          ..write('userValidated: $userValidated, ')
          ..write('userCardId: $userCardId, ')
          ..write('verifiedFinding: $verifiedFinding, ')
          ..write('notes: $notes, ')
          ..write('mediaPath: $mediaPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    role,
    source,
    observedAt,
    locationId,
    itemId,
    latitude,
    longitude,
    accuracyMeters,
    distance,
    analysis,
    sound,
    userValidated,
    userCardId,
    verifiedFinding,
    notes,
    mediaPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SightingRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.role == this.role &&
          other.source == this.source &&
          other.observedAt == this.observedAt &&
          other.locationId == this.locationId &&
          other.itemId == this.itemId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracyMeters == this.accuracyMeters &&
          other.distance == this.distance &&
          other.analysis == this.analysis &&
          other.sound == this.sound &&
          other.userValidated == this.userValidated &&
          other.userCardId == this.userCardId &&
          other.verifiedFinding == this.verifiedFinding &&
          other.notes == this.notes &&
          other.mediaPath == this.mediaPath);
}

class SightingsCompanion extends UpdateCompanion<SightingRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<Role> role;
  final Value<SignalSource> source;
  final Value<DateTime> observedAt;
  final Value<String?> locationId;
  final Value<String?> itemId;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> accuracyMeters;
  final Value<DistanceEstimate?> distance;
  final Value<PestAnalysis?> analysis;
  final Value<SoundAnalysis?> sound;
  final Value<bool> userValidated;
  final Value<String?> userCardId;
  final Value<VerifiedFinding?> verifiedFinding;
  final Value<String?> notes;
  final Value<String?> mediaPath;
  final Value<int> rowid;
  const SightingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.role = const Value.absent(),
    this.source = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.locationId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.distance = const Value.absent(),
    this.analysis = const Value.absent(),
    this.sound = const Value.absent(),
    this.userValidated = const Value.absent(),
    this.userCardId = const Value.absent(),
    this.verifiedFinding = const Value.absent(),
    this.notes = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SightingsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required Role role,
    required SignalSource source,
    required DateTime observedAt,
    this.locationId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.distance = const Value.absent(),
    this.analysis = const Value.absent(),
    this.sound = const Value.absent(),
    required bool userValidated,
    this.userCardId = const Value.absent(),
    this.verifiedFinding = const Value.absent(),
    this.notes = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       role = Value(role),
       source = Value(source),
       observedAt = Value(observedAt),
       userValidated = Value(userValidated);
  static Insertable<SightingRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? role,
    Expression<String>? source,
    Expression<DateTime>? observedAt,
    Expression<String>? locationId,
    Expression<String>? itemId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracyMeters,
    Expression<String>? distance,
    Expression<String>? analysis,
    Expression<String>? sound,
    Expression<bool>? userValidated,
    Expression<String>? userCardId,
    Expression<String>? verifiedFinding,
    Expression<String>? notes,
    Expression<String>? mediaPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (role != null) 'role': role,
      if (source != null) 'source': source,
      if (observedAt != null) 'observed_at': observedAt,
      if (locationId != null) 'location_id': locationId,
      if (itemId != null) 'item_id': itemId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (distance != null) 'distance': distance,
      if (analysis != null) 'analysis': analysis,
      if (sound != null) 'sound': sound,
      if (userValidated != null) 'user_validated': userValidated,
      if (userCardId != null) 'user_card_id': userCardId,
      if (verifiedFinding != null) 'verified_finding': verifiedFinding,
      if (notes != null) 'notes': notes,
      if (mediaPath != null) 'media_path': mediaPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SightingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<Role>? role,
    Value<SignalSource>? source,
    Value<DateTime>? observedAt,
    Value<String?>? locationId,
    Value<String?>? itemId,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<double?>? accuracyMeters,
    Value<DistanceEstimate?>? distance,
    Value<PestAnalysis?>? analysis,
    Value<SoundAnalysis?>? sound,
    Value<bool>? userValidated,
    Value<String?>? userCardId,
    Value<VerifiedFinding?>? verifiedFinding,
    Value<String?>? notes,
    Value<String?>? mediaPath,
    Value<int>? rowid,
  }) {
    return SightingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      role: role ?? this.role,
      source: source ?? this.source,
      observedAt: observedAt ?? this.observedAt,
      locationId: locationId ?? this.locationId,
      itemId: itemId ?? this.itemId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      distance: distance ?? this.distance,
      analysis: analysis ?? this.analysis,
      sound: sound ?? this.sound,
      userValidated: userValidated ?? this.userValidated,
      userCardId: userCardId ?? this.userCardId,
      verifiedFinding: verifiedFinding ?? this.verifiedFinding,
      notes: notes ?? this.notes,
      mediaPath: mediaPath ?? this.mediaPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $SightingsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $SightingsTable.$converterrole.toSql(role.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $SightingsTable.$convertersource.toSql(source.value),
      );
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracyMeters.present) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters.value);
    }
    if (distance.present) {
      map['distance'] = Variable<String>(
        $SightingsTable.$converterdistancen.toSql(distance.value),
      );
    }
    if (analysis.present) {
      map['analysis'] = Variable<String>(
        $SightingsTable.$converteranalysisn.toSql(analysis.value),
      );
    }
    if (sound.present) {
      map['sound'] = Variable<String>(
        $SightingsTable.$convertersoundn.toSql(sound.value),
      );
    }
    if (userValidated.present) {
      map['user_validated'] = Variable<bool>(userValidated.value);
    }
    if (userCardId.present) {
      map['user_card_id'] = Variable<String>(userCardId.value);
    }
    if (verifiedFinding.present) {
      map['verified_finding'] = Variable<String>(
        $SightingsTable.$converterverifiedFindingn.toSql(verifiedFinding.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SightingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('role: $role, ')
          ..write('source: $source, ')
          ..write('observedAt: $observedAt, ')
          ..write('locationId: $locationId, ')
          ..write('itemId: $itemId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('distance: $distance, ')
          ..write('analysis: $analysis, ')
          ..write('sound: $sound, ')
          ..write('userValidated: $userValidated, ')
          ..write('userCardId: $userCardId, ')
          ..write('verifiedFinding: $verifiedFinding, ')
          ..write('notes: $notes, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SensorNodesTable extends SensorNodes
    with TableInfo<$SensorNodesTable, SensorNodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SensorNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($SensorNodesTable.$convertersyncState);
  static const VerificationMeta _deviceAddressMeta = const VerificationMeta(
    'deviceAddress',
  );
  @override
  late final GeneratedColumn<String> deviceAddress = GeneratedColumn<String>(
    'device_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SensorType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SensorType>($SensorNodesTable.$convertertype);
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<int> protocolVersion = GeneratedColumn<int>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firmwareVersionMeta = const VerificationMeta(
    'firmwareVersion',
  );
  @override
  late final GeneratedColumn<String> firmwareVersion = GeneratedColumn<String>(
    'firmware_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyFingerprintMeta = const VerificationMeta(
    'keyFingerprint',
  );
  @override
  late final GeneratedColumn<String> keyFingerprint = GeneratedColumn<String>(
    'key_fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES locations (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batteryPercentMeta = const VerificationMeta(
    'batteryPercent',
  );
  @override
  late final GeneratedColumn<int> batteryPercent = GeneratedColumn<int>(
    'battery_percent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventsClearedThroughSeqMeta =
      const VerificationMeta('eventsClearedThroughSeq');
  @override
  late final GeneratedColumn<int> eventsClearedThroughSeq =
      GeneratedColumn<int>(
        'events_cleared_through_seq',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    deviceAddress,
    name,
    type,
    protocolVersion,
    firmwareVersion,
    keyFingerprint,
    locationId,
    itemId,
    lastSeenAt,
    batteryPercent,
    eventsClearedThroughSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sensor_nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SensorNodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_address')) {
      context.handle(
        _deviceAddressMeta,
        deviceAddress.isAcceptableOrUnknown(
          data['device_address']!,
          _deviceAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceAddressMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionMeta);
    }
    if (data.containsKey('firmware_version')) {
      context.handle(
        _firmwareVersionMeta,
        firmwareVersion.isAcceptableOrUnknown(
          data['firmware_version']!,
          _firmwareVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firmwareVersionMeta);
    }
    if (data.containsKey('key_fingerprint')) {
      context.handle(
        _keyFingerprintMeta,
        keyFingerprint.isAcceptableOrUnknown(
          data['key_fingerprint']!,
          _keyFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyFingerprintMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('battery_percent')) {
      context.handle(
        _batteryPercentMeta,
        batteryPercent.isAcceptableOrUnknown(
          data['battery_percent']!,
          _batteryPercentMeta,
        ),
      );
    }
    if (data.containsKey('events_cleared_through_seq')) {
      context.handle(
        _eventsClearedThroughSeqMeta,
        eventsClearedThroughSeq.isAcceptableOrUnknown(
          data['events_cleared_through_seq']!,
          _eventsClearedThroughSeqMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SensorNodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SensorNodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $SensorNodesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      deviceAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_address'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $SensorNodesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protocol_version'],
      )!,
      firmwareVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firmware_version'],
      )!,
      keyFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_fingerprint'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
      batteryPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_percent'],
      ),
      eventsClearedThroughSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}events_cleared_through_seq'],
      ),
    );
  }

  @override
  $SensorNodesTable createAlias(String alias) {
    return $SensorNodesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<SensorType, String, String> $convertertype =
      const EnumNameConverter<SensorType>(SensorType.values);
}

class SensorNodeRow extends DataClass implements Insertable<SensorNodeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String deviceAddress;
  final String name;
  final SensorType type;
  final int protocolVersion;
  final String firmwareVersion;
  final String keyFingerprint;
  final String? locationId;
  final String? itemId;
  final DateTime? lastSeenAt;
  final int? batteryPercent;

  /// Highest event seq removed by `deleteAllHistory`. Events at or below it
  /// are never re-imported from the node's store-and-forward buffer.
  final int? eventsClearedThroughSeq;
  const SensorNodeRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.deviceAddress,
    required this.name,
    required this.type,
    required this.protocolVersion,
    required this.firmwareVersion,
    required this.keyFingerprint,
    this.locationId,
    this.itemId,
    this.lastSeenAt,
    this.batteryPercent,
    this.eventsClearedThroughSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $SensorNodesTable.$convertersyncState.toSql(syncState),
      );
    }
    map['device_address'] = Variable<String>(deviceAddress);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $SensorNodesTable.$convertertype.toSql(type),
      );
    }
    map['protocol_version'] = Variable<int>(protocolVersion);
    map['firmware_version'] = Variable<String>(firmwareVersion);
    map['key_fingerprint'] = Variable<String>(keyFingerprint);
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    if (!nullToAbsent || batteryPercent != null) {
      map['battery_percent'] = Variable<int>(batteryPercent);
    }
    if (!nullToAbsent || eventsClearedThroughSeq != null) {
      map['events_cleared_through_seq'] = Variable<int>(
        eventsClearedThroughSeq,
      );
    }
    return map;
  }

  SensorNodesCompanion toCompanion(bool nullToAbsent) {
    return SensorNodesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      deviceAddress: Value(deviceAddress),
      name: Value(name),
      type: Value(type),
      protocolVersion: Value(protocolVersion),
      firmwareVersion: Value(firmwareVersion),
      keyFingerprint: Value(keyFingerprint),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      batteryPercent: batteryPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(batteryPercent),
      eventsClearedThroughSeq: eventsClearedThroughSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(eventsClearedThroughSeq),
    );
  }

  factory SensorNodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SensorNodeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $SensorNodesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      deviceAddress: serializer.fromJson<String>(json['deviceAddress']),
      name: serializer.fromJson<String>(json['name']),
      type: $SensorNodesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      protocolVersion: serializer.fromJson<int>(json['protocolVersion']),
      firmwareVersion: serializer.fromJson<String>(json['firmwareVersion']),
      keyFingerprint: serializer.fromJson<String>(json['keyFingerprint']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      batteryPercent: serializer.fromJson<int?>(json['batteryPercent']),
      eventsClearedThroughSeq: serializer.fromJson<int?>(
        json['eventsClearedThroughSeq'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $SensorNodesTable.$convertersyncState.toJson(syncState),
      ),
      'deviceAddress': serializer.toJson<String>(deviceAddress),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $SensorNodesTable.$convertertype.toJson(type),
      ),
      'protocolVersion': serializer.toJson<int>(protocolVersion),
      'firmwareVersion': serializer.toJson<String>(firmwareVersion),
      'keyFingerprint': serializer.toJson<String>(keyFingerprint),
      'locationId': serializer.toJson<String?>(locationId),
      'itemId': serializer.toJson<String?>(itemId),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'batteryPercent': serializer.toJson<int?>(batteryPercent),
      'eventsClearedThroughSeq': serializer.toJson<int?>(
        eventsClearedThroughSeq,
      ),
    };
  }

  SensorNodeRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? deviceAddress,
    String? name,
    SensorType? type,
    int? protocolVersion,
    String? firmwareVersion,
    String? keyFingerprint,
    Value<String?> locationId = const Value.absent(),
    Value<String?> itemId = const Value.absent(),
    Value<DateTime?> lastSeenAt = const Value.absent(),
    Value<int?> batteryPercent = const Value.absent(),
    Value<int?> eventsClearedThroughSeq = const Value.absent(),
  }) => SensorNodeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    deviceAddress: deviceAddress ?? this.deviceAddress,
    name: name ?? this.name,
    type: type ?? this.type,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    firmwareVersion: firmwareVersion ?? this.firmwareVersion,
    keyFingerprint: keyFingerprint ?? this.keyFingerprint,
    locationId: locationId.present ? locationId.value : this.locationId,
    itemId: itemId.present ? itemId.value : this.itemId,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    batteryPercent: batteryPercent.present
        ? batteryPercent.value
        : this.batteryPercent,
    eventsClearedThroughSeq: eventsClearedThroughSeq.present
        ? eventsClearedThroughSeq.value
        : this.eventsClearedThroughSeq,
  );
  SensorNodeRow copyWithCompanion(SensorNodesCompanion data) {
    return SensorNodeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deviceAddress: data.deviceAddress.present
          ? data.deviceAddress.value
          : this.deviceAddress,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      firmwareVersion: data.firmwareVersion.present
          ? data.firmwareVersion.value
          : this.firmwareVersion,
      keyFingerprint: data.keyFingerprint.present
          ? data.keyFingerprint.value
          : this.keyFingerprint,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      batteryPercent: data.batteryPercent.present
          ? data.batteryPercent.value
          : this.batteryPercent,
      eventsClearedThroughSeq: data.eventsClearedThroughSeq.present
          ? data.eventsClearedThroughSeq.value
          : this.eventsClearedThroughSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SensorNodeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('deviceAddress: $deviceAddress, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('firmwareVersion: $firmwareVersion, ')
          ..write('keyFingerprint: $keyFingerprint, ')
          ..write('locationId: $locationId, ')
          ..write('itemId: $itemId, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('batteryPercent: $batteryPercent, ')
          ..write('eventsClearedThroughSeq: $eventsClearedThroughSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    deviceAddress,
    name,
    type,
    protocolVersion,
    firmwareVersion,
    keyFingerprint,
    locationId,
    itemId,
    lastSeenAt,
    batteryPercent,
    eventsClearedThroughSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SensorNodeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.deviceAddress == this.deviceAddress &&
          other.name == this.name &&
          other.type == this.type &&
          other.protocolVersion == this.protocolVersion &&
          other.firmwareVersion == this.firmwareVersion &&
          other.keyFingerprint == this.keyFingerprint &&
          other.locationId == this.locationId &&
          other.itemId == this.itemId &&
          other.lastSeenAt == this.lastSeenAt &&
          other.batteryPercent == this.batteryPercent &&
          other.eventsClearedThroughSeq == this.eventsClearedThroughSeq);
}

class SensorNodesCompanion extends UpdateCompanion<SensorNodeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> deviceAddress;
  final Value<String> name;
  final Value<SensorType> type;
  final Value<int> protocolVersion;
  final Value<String> firmwareVersion;
  final Value<String> keyFingerprint;
  final Value<String?> locationId;
  final Value<String?> itemId;
  final Value<DateTime?> lastSeenAt;
  final Value<int?> batteryPercent;
  final Value<int?> eventsClearedThroughSeq;
  final Value<int> rowid;
  const SensorNodesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deviceAddress = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.firmwareVersion = const Value.absent(),
    this.keyFingerprint = const Value.absent(),
    this.locationId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.batteryPercent = const Value.absent(),
    this.eventsClearedThroughSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SensorNodesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String deviceAddress,
    required String name,
    required SensorType type,
    required int protocolVersion,
    required String firmwareVersion,
    required String keyFingerprint,
    this.locationId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.batteryPercent = const Value.absent(),
    this.eventsClearedThroughSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceAddress = Value(deviceAddress),
       name = Value(name),
       type = Value(type),
       protocolVersion = Value(protocolVersion),
       firmwareVersion = Value(firmwareVersion),
       keyFingerprint = Value(keyFingerprint);
  static Insertable<SensorNodeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? deviceAddress,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? protocolVersion,
    Expression<String>? firmwareVersion,
    Expression<String>? keyFingerprint,
    Expression<String>? locationId,
    Expression<String>? itemId,
    Expression<DateTime>? lastSeenAt,
    Expression<int>? batteryPercent,
    Expression<int>? eventsClearedThroughSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (deviceAddress != null) 'device_address': deviceAddress,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      if (keyFingerprint != null) 'key_fingerprint': keyFingerprint,
      if (locationId != null) 'location_id': locationId,
      if (itemId != null) 'item_id': itemId,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (batteryPercent != null) 'battery_percent': batteryPercent,
      if (eventsClearedThroughSeq != null)
        'events_cleared_through_seq': eventsClearedThroughSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SensorNodesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? deviceAddress,
    Value<String>? name,
    Value<SensorType>? type,
    Value<int>? protocolVersion,
    Value<String>? firmwareVersion,
    Value<String>? keyFingerprint,
    Value<String?>? locationId,
    Value<String?>? itemId,
    Value<DateTime?>? lastSeenAt,
    Value<int?>? batteryPercent,
    Value<int?>? eventsClearedThroughSeq,
    Value<int>? rowid,
  }) {
    return SensorNodesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      name: name ?? this.name,
      type: type ?? this.type,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      keyFingerprint: keyFingerprint ?? this.keyFingerprint,
      locationId: locationId ?? this.locationId,
      itemId: itemId ?? this.itemId,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      eventsClearedThroughSeq:
          eventsClearedThroughSeq ?? this.eventsClearedThroughSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $SensorNodesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (deviceAddress.present) {
      map['device_address'] = Variable<String>(deviceAddress.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $SensorNodesTable.$convertertype.toSql(type.value),
      );
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<int>(protocolVersion.value);
    }
    if (firmwareVersion.present) {
      map['firmware_version'] = Variable<String>(firmwareVersion.value);
    }
    if (keyFingerprint.present) {
      map['key_fingerprint'] = Variable<String>(keyFingerprint.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (batteryPercent.present) {
      map['battery_percent'] = Variable<int>(batteryPercent.value);
    }
    if (eventsClearedThroughSeq.present) {
      map['events_cleared_through_seq'] = Variable<int>(
        eventsClearedThroughSeq.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SensorNodesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('deviceAddress: $deviceAddress, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('firmwareVersion: $firmwareVersion, ')
          ..write('keyFingerprint: $keyFingerprint, ')
          ..write('locationId: $locationId, ')
          ..write('itemId: $itemId, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('batteryPercent: $batteryPercent, ')
          ..write('eventsClearedThroughSeq: $eventsClearedThroughSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SensorEventsTable extends SensorEvents
    with TableInfo<$SensorEventsTable, SensorEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SensorEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($SensorEventsTable.$convertersyncState);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sensor_nodes (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SensorEventClass, String>
  eventClass = GeneratedColumn<String>(
    'event_class',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<SensorEventClass>($SensorEventsTable.$convertereventClass);
  static const VerificationMeta _peakHzMeta = const VerificationMeta('peakHz');
  @override
  late final GeneratedColumn<double> peakHz = GeneratedColumn<double>(
    'peak_hz',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minHzMeta = const VerificationMeta('minHz');
  @override
  late final GeneratedColumn<double> minHz = GeneratedColumn<double>(
    'min_hz',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxHzMeta = const VerificationMeta('maxHz');
  @override
  late final GeneratedColumn<double> maxHz = GeneratedColumn<double>(
    'max_hz',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slopeHzPerMsMeta = const VerificationMeta(
    'slopeHzPerMs',
  );
  @override
  late final GeneratedColumn<double> slopeHzPerMs = GeneratedColumn<double>(
    'slope_hz_per_ms',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snrDbMeta = const VerificationMeta('snrDb');
  @override
  late final GeneratedColumn<double> snrDb = GeneratedColumn<double>(
    'snr_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peakDbfsMeta = const VerificationMeta(
    'peakDbfs',
  );
  @override
  late final GeneratedColumn<double> peakDbfs = GeneratedColumn<double>(
    'peak_dbfs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _impulsesMeta = const VerificationMeta(
    'impulses',
  );
  @override
  late final GeneratedColumn<int> impulses = GeneratedColumn<int>(
    'impulses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repRateHzMeta = const VerificationMeta(
    'repRateHz',
  );
  @override
  late final GeneratedColumn<double> repRateHz = GeneratedColumn<double>(
    'rep_rate_hz',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _harmonicsMeta = const VerificationMeta(
    'harmonics',
  );
  @override
  late final GeneratedColumn<int> harmonics = GeneratedColumn<int>(
    'harmonics',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureIdMeta = const VerificationMeta(
    'signatureId',
  );
  @override
  late final GeneratedColumn<String> signatureId = GeneratedColumn<String>(
    'signature_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _packVersionMeta = const VerificationMeta(
    'packVersion',
  );
  @override
  late final GeneratedColumn<String> packVersion = GeneratedColumn<String>(
    'pack_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchScoreMeta = const VerificationMeta(
    'matchScore',
  );
  @override
  late final GeneratedColumn<double> matchScore = GeneratedColumn<double>(
    'match_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchExperimentalMeta = const VerificationMeta(
    'matchExperimental',
  );
  @override
  late final GeneratedColumn<bool> matchExperimental = GeneratedColumn<bool>(
    'match_experimental',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("match_experimental" IN (0, 1))',
    ),
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES locations (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    nodeId,
    seq,
    startedAt,
    durationMs,
    eventClass,
    peakHz,
    minHz,
    maxHz,
    slopeHzPerMs,
    snrDb,
    peakDbfs,
    impulses,
    repRateHz,
    harmonics,
    signatureId,
    packVersion,
    matchScore,
    matchExperimental,
    locationId,
    itemId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sensor_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SensorEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('peak_hz')) {
      context.handle(
        _peakHzMeta,
        peakHz.isAcceptableOrUnknown(data['peak_hz']!, _peakHzMeta),
      );
    } else if (isInserting) {
      context.missing(_peakHzMeta);
    }
    if (data.containsKey('min_hz')) {
      context.handle(
        _minHzMeta,
        minHz.isAcceptableOrUnknown(data['min_hz']!, _minHzMeta),
      );
    } else if (isInserting) {
      context.missing(_minHzMeta);
    }
    if (data.containsKey('max_hz')) {
      context.handle(
        _maxHzMeta,
        maxHz.isAcceptableOrUnknown(data['max_hz']!, _maxHzMeta),
      );
    } else if (isInserting) {
      context.missing(_maxHzMeta);
    }
    if (data.containsKey('slope_hz_per_ms')) {
      context.handle(
        _slopeHzPerMsMeta,
        slopeHzPerMs.isAcceptableOrUnknown(
          data['slope_hz_per_ms']!,
          _slopeHzPerMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_slopeHzPerMsMeta);
    }
    if (data.containsKey('snr_db')) {
      context.handle(
        _snrDbMeta,
        snrDb.isAcceptableOrUnknown(data['snr_db']!, _snrDbMeta),
      );
    } else if (isInserting) {
      context.missing(_snrDbMeta);
    }
    if (data.containsKey('peak_dbfs')) {
      context.handle(
        _peakDbfsMeta,
        peakDbfs.isAcceptableOrUnknown(data['peak_dbfs']!, _peakDbfsMeta),
      );
    } else if (isInserting) {
      context.missing(_peakDbfsMeta);
    }
    if (data.containsKey('impulses')) {
      context.handle(
        _impulsesMeta,
        impulses.isAcceptableOrUnknown(data['impulses']!, _impulsesMeta),
      );
    } else if (isInserting) {
      context.missing(_impulsesMeta);
    }
    if (data.containsKey('rep_rate_hz')) {
      context.handle(
        _repRateHzMeta,
        repRateHz.isAcceptableOrUnknown(data['rep_rate_hz']!, _repRateHzMeta),
      );
    } else if (isInserting) {
      context.missing(_repRateHzMeta);
    }
    if (data.containsKey('harmonics')) {
      context.handle(
        _harmonicsMeta,
        harmonics.isAcceptableOrUnknown(data['harmonics']!, _harmonicsMeta),
      );
    } else if (isInserting) {
      context.missing(_harmonicsMeta);
    }
    if (data.containsKey('signature_id')) {
      context.handle(
        _signatureIdMeta,
        signatureId.isAcceptableOrUnknown(
          data['signature_id']!,
          _signatureIdMeta,
        ),
      );
    }
    if (data.containsKey('pack_version')) {
      context.handle(
        _packVersionMeta,
        packVersion.isAcceptableOrUnknown(
          data['pack_version']!,
          _packVersionMeta,
        ),
      );
    }
    if (data.containsKey('match_score')) {
      context.handle(
        _matchScoreMeta,
        matchScore.isAcceptableOrUnknown(data['match_score']!, _matchScoreMeta),
      );
    }
    if (data.containsKey('match_experimental')) {
      context.handle(
        _matchExperimentalMeta,
        matchExperimental.isAcceptableOrUnknown(
          data['match_experimental']!,
          _matchExperimentalMeta,
        ),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {nodeId, seq},
  ];
  @override
  SensorEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SensorEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $SensorEventsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      eventClass: $SensorEventsTable.$convertereventClass.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}event_class'],
        )!,
      ),
      peakHz: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak_hz'],
      )!,
      minHz: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_hz'],
      )!,
      maxHz: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_hz'],
      )!,
      slopeHzPerMs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}slope_hz_per_ms'],
      )!,
      snrDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}snr_db'],
      )!,
      peakDbfs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak_dbfs'],
      )!,
      impulses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}impulses'],
      )!,
      repRateHz: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rep_rate_hz'],
      )!,
      harmonics: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}harmonics'],
      )!,
      signatureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_id'],
      ),
      packVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_version'],
      ),
      matchScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}match_score'],
      ),
      matchExperimental: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}match_experimental'],
      ),
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
    );
  }

  @override
  $SensorEventsTable createAlias(String alias) {
    return $SensorEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<SensorEventClass, String, String>
  $convertereventClass = const EnumNameConverter<SensorEventClass>(
    SensorEventClass.values,
  );
}

class SensorEventRow extends DataClass implements Insertable<SensorEventRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String nodeId;
  final int seq;
  final DateTime startedAt;
  final int durationMs;
  final SensorEventClass eventClass;
  final double peakHz;
  final double minHz;
  final double maxHz;
  final double slopeHzPerMs;
  final double snrDb;
  final double peakDbfs;
  final int impulses;
  final double repRateHz;
  final int harmonics;

  /// Signature match; all null when the event matched no signature.
  final String? signatureId;
  final String? packVersion;
  final double? matchScore;
  final bool? matchExperimental;

  /// Where the node was placed when the event was recorded.
  final String? locationId;
  final String? itemId;
  const SensorEventRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.nodeId,
    required this.seq,
    required this.startedAt,
    required this.durationMs,
    required this.eventClass,
    required this.peakHz,
    required this.minHz,
    required this.maxHz,
    required this.slopeHzPerMs,
    required this.snrDb,
    required this.peakDbfs,
    required this.impulses,
    required this.repRateHz,
    required this.harmonics,
    this.signatureId,
    this.packVersion,
    this.matchScore,
    this.matchExperimental,
    this.locationId,
    this.itemId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $SensorEventsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['node_id'] = Variable<String>(nodeId);
    map['seq'] = Variable<int>(seq);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_ms'] = Variable<int>(durationMs);
    {
      map['event_class'] = Variable<String>(
        $SensorEventsTable.$convertereventClass.toSql(eventClass),
      );
    }
    map['peak_hz'] = Variable<double>(peakHz);
    map['min_hz'] = Variable<double>(minHz);
    map['max_hz'] = Variable<double>(maxHz);
    map['slope_hz_per_ms'] = Variable<double>(slopeHzPerMs);
    map['snr_db'] = Variable<double>(snrDb);
    map['peak_dbfs'] = Variable<double>(peakDbfs);
    map['impulses'] = Variable<int>(impulses);
    map['rep_rate_hz'] = Variable<double>(repRateHz);
    map['harmonics'] = Variable<int>(harmonics);
    if (!nullToAbsent || signatureId != null) {
      map['signature_id'] = Variable<String>(signatureId);
    }
    if (!nullToAbsent || packVersion != null) {
      map['pack_version'] = Variable<String>(packVersion);
    }
    if (!nullToAbsent || matchScore != null) {
      map['match_score'] = Variable<double>(matchScore);
    }
    if (!nullToAbsent || matchExperimental != null) {
      map['match_experimental'] = Variable<bool>(matchExperimental);
    }
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    return map;
  }

  SensorEventsCompanion toCompanion(bool nullToAbsent) {
    return SensorEventsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      nodeId: Value(nodeId),
      seq: Value(seq),
      startedAt: Value(startedAt),
      durationMs: Value(durationMs),
      eventClass: Value(eventClass),
      peakHz: Value(peakHz),
      minHz: Value(minHz),
      maxHz: Value(maxHz),
      slopeHzPerMs: Value(slopeHzPerMs),
      snrDb: Value(snrDb),
      peakDbfs: Value(peakDbfs),
      impulses: Value(impulses),
      repRateHz: Value(repRateHz),
      harmonics: Value(harmonics),
      signatureId: signatureId == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureId),
      packVersion: packVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(packVersion),
      matchScore: matchScore == null && nullToAbsent
          ? const Value.absent()
          : Value(matchScore),
      matchExperimental: matchExperimental == null && nullToAbsent
          ? const Value.absent()
          : Value(matchExperimental),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
    );
  }

  factory SensorEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SensorEventRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $SensorEventsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      seq: serializer.fromJson<int>(json['seq']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      eventClass: $SensorEventsTable.$convertereventClass.fromJson(
        serializer.fromJson<String>(json['eventClass']),
      ),
      peakHz: serializer.fromJson<double>(json['peakHz']),
      minHz: serializer.fromJson<double>(json['minHz']),
      maxHz: serializer.fromJson<double>(json['maxHz']),
      slopeHzPerMs: serializer.fromJson<double>(json['slopeHzPerMs']),
      snrDb: serializer.fromJson<double>(json['snrDb']),
      peakDbfs: serializer.fromJson<double>(json['peakDbfs']),
      impulses: serializer.fromJson<int>(json['impulses']),
      repRateHz: serializer.fromJson<double>(json['repRateHz']),
      harmonics: serializer.fromJson<int>(json['harmonics']),
      signatureId: serializer.fromJson<String?>(json['signatureId']),
      packVersion: serializer.fromJson<String?>(json['packVersion']),
      matchScore: serializer.fromJson<double?>(json['matchScore']),
      matchExperimental: serializer.fromJson<bool?>(json['matchExperimental']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $SensorEventsTable.$convertersyncState.toJson(syncState),
      ),
      'nodeId': serializer.toJson<String>(nodeId),
      'seq': serializer.toJson<int>(seq),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'eventClass': serializer.toJson<String>(
        $SensorEventsTable.$convertereventClass.toJson(eventClass),
      ),
      'peakHz': serializer.toJson<double>(peakHz),
      'minHz': serializer.toJson<double>(minHz),
      'maxHz': serializer.toJson<double>(maxHz),
      'slopeHzPerMs': serializer.toJson<double>(slopeHzPerMs),
      'snrDb': serializer.toJson<double>(snrDb),
      'peakDbfs': serializer.toJson<double>(peakDbfs),
      'impulses': serializer.toJson<int>(impulses),
      'repRateHz': serializer.toJson<double>(repRateHz),
      'harmonics': serializer.toJson<int>(harmonics),
      'signatureId': serializer.toJson<String?>(signatureId),
      'packVersion': serializer.toJson<String?>(packVersion),
      'matchScore': serializer.toJson<double?>(matchScore),
      'matchExperimental': serializer.toJson<bool?>(matchExperimental),
      'locationId': serializer.toJson<String?>(locationId),
      'itemId': serializer.toJson<String?>(itemId),
    };
  }

  SensorEventRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? nodeId,
    int? seq,
    DateTime? startedAt,
    int? durationMs,
    SensorEventClass? eventClass,
    double? peakHz,
    double? minHz,
    double? maxHz,
    double? slopeHzPerMs,
    double? snrDb,
    double? peakDbfs,
    int? impulses,
    double? repRateHz,
    int? harmonics,
    Value<String?> signatureId = const Value.absent(),
    Value<String?> packVersion = const Value.absent(),
    Value<double?> matchScore = const Value.absent(),
    Value<bool?> matchExperimental = const Value.absent(),
    Value<String?> locationId = const Value.absent(),
    Value<String?> itemId = const Value.absent(),
  }) => SensorEventRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    nodeId: nodeId ?? this.nodeId,
    seq: seq ?? this.seq,
    startedAt: startedAt ?? this.startedAt,
    durationMs: durationMs ?? this.durationMs,
    eventClass: eventClass ?? this.eventClass,
    peakHz: peakHz ?? this.peakHz,
    minHz: minHz ?? this.minHz,
    maxHz: maxHz ?? this.maxHz,
    slopeHzPerMs: slopeHzPerMs ?? this.slopeHzPerMs,
    snrDb: snrDb ?? this.snrDb,
    peakDbfs: peakDbfs ?? this.peakDbfs,
    impulses: impulses ?? this.impulses,
    repRateHz: repRateHz ?? this.repRateHz,
    harmonics: harmonics ?? this.harmonics,
    signatureId: signatureId.present ? signatureId.value : this.signatureId,
    packVersion: packVersion.present ? packVersion.value : this.packVersion,
    matchScore: matchScore.present ? matchScore.value : this.matchScore,
    matchExperimental: matchExperimental.present
        ? matchExperimental.value
        : this.matchExperimental,
    locationId: locationId.present ? locationId.value : this.locationId,
    itemId: itemId.present ? itemId.value : this.itemId,
  );
  SensorEventRow copyWithCompanion(SensorEventsCompanion data) {
    return SensorEventRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      seq: data.seq.present ? data.seq.value : this.seq,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      eventClass: data.eventClass.present
          ? data.eventClass.value
          : this.eventClass,
      peakHz: data.peakHz.present ? data.peakHz.value : this.peakHz,
      minHz: data.minHz.present ? data.minHz.value : this.minHz,
      maxHz: data.maxHz.present ? data.maxHz.value : this.maxHz,
      slopeHzPerMs: data.slopeHzPerMs.present
          ? data.slopeHzPerMs.value
          : this.slopeHzPerMs,
      snrDb: data.snrDb.present ? data.snrDb.value : this.snrDb,
      peakDbfs: data.peakDbfs.present ? data.peakDbfs.value : this.peakDbfs,
      impulses: data.impulses.present ? data.impulses.value : this.impulses,
      repRateHz: data.repRateHz.present ? data.repRateHz.value : this.repRateHz,
      harmonics: data.harmonics.present ? data.harmonics.value : this.harmonics,
      signatureId: data.signatureId.present
          ? data.signatureId.value
          : this.signatureId,
      packVersion: data.packVersion.present
          ? data.packVersion.value
          : this.packVersion,
      matchScore: data.matchScore.present
          ? data.matchScore.value
          : this.matchScore,
      matchExperimental: data.matchExperimental.present
          ? data.matchExperimental.value
          : this.matchExperimental,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SensorEventRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('nodeId: $nodeId, ')
          ..write('seq: $seq, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('eventClass: $eventClass, ')
          ..write('peakHz: $peakHz, ')
          ..write('minHz: $minHz, ')
          ..write('maxHz: $maxHz, ')
          ..write('slopeHzPerMs: $slopeHzPerMs, ')
          ..write('snrDb: $snrDb, ')
          ..write('peakDbfs: $peakDbfs, ')
          ..write('impulses: $impulses, ')
          ..write('repRateHz: $repRateHz, ')
          ..write('harmonics: $harmonics, ')
          ..write('signatureId: $signatureId, ')
          ..write('packVersion: $packVersion, ')
          ..write('matchScore: $matchScore, ')
          ..write('matchExperimental: $matchExperimental, ')
          ..write('locationId: $locationId, ')
          ..write('itemId: $itemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    syncState,
    nodeId,
    seq,
    startedAt,
    durationMs,
    eventClass,
    peakHz,
    minHz,
    maxHz,
    slopeHzPerMs,
    snrDb,
    peakDbfs,
    impulses,
    repRateHz,
    harmonics,
    signatureId,
    packVersion,
    matchScore,
    matchExperimental,
    locationId,
    itemId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SensorEventRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.nodeId == this.nodeId &&
          other.seq == this.seq &&
          other.startedAt == this.startedAt &&
          other.durationMs == this.durationMs &&
          other.eventClass == this.eventClass &&
          other.peakHz == this.peakHz &&
          other.minHz == this.minHz &&
          other.maxHz == this.maxHz &&
          other.slopeHzPerMs == this.slopeHzPerMs &&
          other.snrDb == this.snrDb &&
          other.peakDbfs == this.peakDbfs &&
          other.impulses == this.impulses &&
          other.repRateHz == this.repRateHz &&
          other.harmonics == this.harmonics &&
          other.signatureId == this.signatureId &&
          other.packVersion == this.packVersion &&
          other.matchScore == this.matchScore &&
          other.matchExperimental == this.matchExperimental &&
          other.locationId == this.locationId &&
          other.itemId == this.itemId);
}

class SensorEventsCompanion extends UpdateCompanion<SensorEventRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> nodeId;
  final Value<int> seq;
  final Value<DateTime> startedAt;
  final Value<int> durationMs;
  final Value<SensorEventClass> eventClass;
  final Value<double> peakHz;
  final Value<double> minHz;
  final Value<double> maxHz;
  final Value<double> slopeHzPerMs;
  final Value<double> snrDb;
  final Value<double> peakDbfs;
  final Value<int> impulses;
  final Value<double> repRateHz;
  final Value<int> harmonics;
  final Value<String?> signatureId;
  final Value<String?> packVersion;
  final Value<double?> matchScore;
  final Value<bool?> matchExperimental;
  final Value<String?> locationId;
  final Value<String?> itemId;
  final Value<int> rowid;
  const SensorEventsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.seq = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.eventClass = const Value.absent(),
    this.peakHz = const Value.absent(),
    this.minHz = const Value.absent(),
    this.maxHz = const Value.absent(),
    this.slopeHzPerMs = const Value.absent(),
    this.snrDb = const Value.absent(),
    this.peakDbfs = const Value.absent(),
    this.impulses = const Value.absent(),
    this.repRateHz = const Value.absent(),
    this.harmonics = const Value.absent(),
    this.signatureId = const Value.absent(),
    this.packVersion = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.matchExperimental = const Value.absent(),
    this.locationId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SensorEventsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String nodeId,
    required int seq,
    required DateTime startedAt,
    required int durationMs,
    required SensorEventClass eventClass,
    required double peakHz,
    required double minHz,
    required double maxHz,
    required double slopeHzPerMs,
    required double snrDb,
    required double peakDbfs,
    required int impulses,
    required double repRateHz,
    required int harmonics,
    this.signatureId = const Value.absent(),
    this.packVersion = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.matchExperimental = const Value.absent(),
    this.locationId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       nodeId = Value(nodeId),
       seq = Value(seq),
       startedAt = Value(startedAt),
       durationMs = Value(durationMs),
       eventClass = Value(eventClass),
       peakHz = Value(peakHz),
       minHz = Value(minHz),
       maxHz = Value(maxHz),
       slopeHzPerMs = Value(slopeHzPerMs),
       snrDb = Value(snrDb),
       peakDbfs = Value(peakDbfs),
       impulses = Value(impulses),
       repRateHz = Value(repRateHz),
       harmonics = Value(harmonics);
  static Insertable<SensorEventRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? nodeId,
    Expression<int>? seq,
    Expression<DateTime>? startedAt,
    Expression<int>? durationMs,
    Expression<String>? eventClass,
    Expression<double>? peakHz,
    Expression<double>? minHz,
    Expression<double>? maxHz,
    Expression<double>? slopeHzPerMs,
    Expression<double>? snrDb,
    Expression<double>? peakDbfs,
    Expression<int>? impulses,
    Expression<double>? repRateHz,
    Expression<int>? harmonics,
    Expression<String>? signatureId,
    Expression<String>? packVersion,
    Expression<double>? matchScore,
    Expression<bool>? matchExperimental,
    Expression<String>? locationId,
    Expression<String>? itemId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (nodeId != null) 'node_id': nodeId,
      if (seq != null) 'seq': seq,
      if (startedAt != null) 'started_at': startedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (eventClass != null) 'event_class': eventClass,
      if (peakHz != null) 'peak_hz': peakHz,
      if (minHz != null) 'min_hz': minHz,
      if (maxHz != null) 'max_hz': maxHz,
      if (slopeHzPerMs != null) 'slope_hz_per_ms': slopeHzPerMs,
      if (snrDb != null) 'snr_db': snrDb,
      if (peakDbfs != null) 'peak_dbfs': peakDbfs,
      if (impulses != null) 'impulses': impulses,
      if (repRateHz != null) 'rep_rate_hz': repRateHz,
      if (harmonics != null) 'harmonics': harmonics,
      if (signatureId != null) 'signature_id': signatureId,
      if (packVersion != null) 'pack_version': packVersion,
      if (matchScore != null) 'match_score': matchScore,
      if (matchExperimental != null) 'match_experimental': matchExperimental,
      if (locationId != null) 'location_id': locationId,
      if (itemId != null) 'item_id': itemId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SensorEventsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? nodeId,
    Value<int>? seq,
    Value<DateTime>? startedAt,
    Value<int>? durationMs,
    Value<SensorEventClass>? eventClass,
    Value<double>? peakHz,
    Value<double>? minHz,
    Value<double>? maxHz,
    Value<double>? slopeHzPerMs,
    Value<double>? snrDb,
    Value<double>? peakDbfs,
    Value<int>? impulses,
    Value<double>? repRateHz,
    Value<int>? harmonics,
    Value<String?>? signatureId,
    Value<String?>? packVersion,
    Value<double?>? matchScore,
    Value<bool?>? matchExperimental,
    Value<String?>? locationId,
    Value<String?>? itemId,
    Value<int>? rowid,
  }) {
    return SensorEventsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      nodeId: nodeId ?? this.nodeId,
      seq: seq ?? this.seq,
      startedAt: startedAt ?? this.startedAt,
      durationMs: durationMs ?? this.durationMs,
      eventClass: eventClass ?? this.eventClass,
      peakHz: peakHz ?? this.peakHz,
      minHz: minHz ?? this.minHz,
      maxHz: maxHz ?? this.maxHz,
      slopeHzPerMs: slopeHzPerMs ?? this.slopeHzPerMs,
      snrDb: snrDb ?? this.snrDb,
      peakDbfs: peakDbfs ?? this.peakDbfs,
      impulses: impulses ?? this.impulses,
      repRateHz: repRateHz ?? this.repRateHz,
      harmonics: harmonics ?? this.harmonics,
      signatureId: signatureId ?? this.signatureId,
      packVersion: packVersion ?? this.packVersion,
      matchScore: matchScore ?? this.matchScore,
      matchExperimental: matchExperimental ?? this.matchExperimental,
      locationId: locationId ?? this.locationId,
      itemId: itemId ?? this.itemId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $SensorEventsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (eventClass.present) {
      map['event_class'] = Variable<String>(
        $SensorEventsTable.$convertereventClass.toSql(eventClass.value),
      );
    }
    if (peakHz.present) {
      map['peak_hz'] = Variable<double>(peakHz.value);
    }
    if (minHz.present) {
      map['min_hz'] = Variable<double>(minHz.value);
    }
    if (maxHz.present) {
      map['max_hz'] = Variable<double>(maxHz.value);
    }
    if (slopeHzPerMs.present) {
      map['slope_hz_per_ms'] = Variable<double>(slopeHzPerMs.value);
    }
    if (snrDb.present) {
      map['snr_db'] = Variable<double>(snrDb.value);
    }
    if (peakDbfs.present) {
      map['peak_dbfs'] = Variable<double>(peakDbfs.value);
    }
    if (impulses.present) {
      map['impulses'] = Variable<int>(impulses.value);
    }
    if (repRateHz.present) {
      map['rep_rate_hz'] = Variable<double>(repRateHz.value);
    }
    if (harmonics.present) {
      map['harmonics'] = Variable<int>(harmonics.value);
    }
    if (signatureId.present) {
      map['signature_id'] = Variable<String>(signatureId.value);
    }
    if (packVersion.present) {
      map['pack_version'] = Variable<String>(packVersion.value);
    }
    if (matchScore.present) {
      map['match_score'] = Variable<double>(matchScore.value);
    }
    if (matchExperimental.present) {
      map['match_experimental'] = Variable<bool>(matchExperimental.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SensorEventsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('nodeId: $nodeId, ')
          ..write('seq: $seq, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('eventClass: $eventClass, ')
          ..write('peakHz: $peakHz, ')
          ..write('minHz: $minHz, ')
          ..write('maxHz: $maxHz, ')
          ..write('slopeHzPerMs: $slopeHzPerMs, ')
          ..write('snrDb: $snrDb, ')
          ..write('peakDbfs: $peakDbfs, ')
          ..write('impulses: $impulses, ')
          ..write('repRateHz: $repRateHz, ')
          ..write('harmonics: $harmonics, ')
          ..write('signatureId: $signatureId, ')
          ..write('packVersion: $packVersion, ')
          ..write('matchScore: $matchScore, ')
          ..write('matchExperimental: $matchExperimental, ')
          ..write('locationId: $locationId, ')
          ..write('itemId: $itemId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($RemindersTable.$convertersyncState);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReminderStatus>($RemindersTable.$converterstatus);
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    itemId,
    dueAt,
    status,
    notificationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $RemindersTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      status: $RemindersTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static JsonTypeConverter2<ReminderStatus, String, String> $converterstatus =
      const EnumNameConverter<ReminderStatus>(ReminderStatus.values);
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String itemId;
  final DateTime dueAt;
  final ReminderStatus status;

  /// 32-bit id handed to the OS notification scheduler.
  final int notificationId;
  const ReminderRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.itemId,
    required this.dueAt,
    required this.status,
    required this.notificationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $RemindersTable.$convertersyncState.toSql(syncState),
      );
    }
    map['item_id'] = Variable<String>(itemId);
    map['due_at'] = Variable<DateTime>(dueAt);
    {
      map['status'] = Variable<String>(
        $RemindersTable.$converterstatus.toSql(status),
      );
    }
    map['notification_id'] = Variable<int>(notificationId);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      itemId: Value(itemId),
      dueAt: Value(dueAt),
      status: Value(status),
      notificationId: Value(notificationId),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $RemindersTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      itemId: serializer.fromJson<String>(json['itemId']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      status: $RemindersTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      notificationId: serializer.fromJson<int>(json['notificationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $RemindersTable.$convertersyncState.toJson(syncState),
      ),
      'itemId': serializer.toJson<String>(itemId),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'status': serializer.toJson<String>(
        $RemindersTable.$converterstatus.toJson(status),
      ),
      'notificationId': serializer.toJson<int>(notificationId),
    };
  }

  ReminderRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? itemId,
    DateTime? dueAt,
    ReminderStatus? status,
    int? notificationId,
  }) => ReminderRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    itemId: itemId ?? this.itemId,
    dueAt: dueAt ?? this.dueAt,
    status: status ?? this.status,
    notificationId: notificationId ?? this.notificationId,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      status: data.status.present ? data.status.value : this.status,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('itemId: $itemId, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('notificationId: $notificationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    itemId,
    dueAt,
    status,
    notificationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.itemId == this.itemId &&
          other.dueAt == this.dueAt &&
          other.status == this.status &&
          other.notificationId == this.notificationId);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> itemId;
  final Value<DateTime> dueAt;
  final Value<ReminderStatus> status;
  final Value<int> notificationId;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.itemId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.status = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String itemId,
    required DateTime dueAt,
    required ReminderStatus status,
    required int notificationId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       itemId = Value(itemId),
       dueAt = Value(dueAt),
       status = Value(status),
       notificationId = Value(notificationId);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? itemId,
    Expression<DateTime>? dueAt,
    Expression<String>? status,
    Expression<int>? notificationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (itemId != null) 'item_id': itemId,
      if (dueAt != null) 'due_at': dueAt,
      if (status != null) 'status': status,
      if (notificationId != null) 'notification_id': notificationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? itemId,
    Value<DateTime>? dueAt,
    Value<ReminderStatus>? status,
    Value<int>? notificationId,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      itemId: itemId ?? this.itemId,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      notificationId: notificationId ?? this.notificationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $RemindersTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $RemindersTable.$converterstatus.toSql(status.value),
      );
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('itemId: $itemId, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('notificationId: $notificationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($SettingsTable.$convertersyncState);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    key,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $SettingsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String key;
  final String value;
  const SettingRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $SettingsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $SettingsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $SettingsTable.$convertersyncState.toJson(syncState),
      ),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? key,
    String? value,
  }) => SettingRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, syncState, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $SettingsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KnowledgeCardsTable extends KnowledgeCards
    with TableInfo<$KnowledgeCardsTable, KnowledgeCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnowledgeCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($KnowledgeCardsTable.$convertersyncState);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, String>, String>
  names = GeneratedColumn<String>(
    'names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Map<String, String>>($KnowledgeCardsTable.$converternames);
  @override
  late final GeneratedColumnWithTypeConverter<PestGroup, String> pestGroup =
      GeneratedColumn<String>(
        'pest_group',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PestGroup>($KnowledgeCardsTable.$converterpestGroup);
  @override
  late final GeneratedColumnWithTypeConverter<SafetyLevel, String> safety =
      GeneratedColumn<String>(
        'safety',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SafetyLevel>($KnowledgeCardsTable.$convertersafety);
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> signs =
      GeneratedColumn<String>(
        'signs',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($KnowledgeCardsTable.$convertersigns);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> lookAlikes =
      GeneratedColumn<String>(
        'look_alikes',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($KnowledgeCardsTable.$converterlookAlikes);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  healthRisks = GeneratedColumn<String>(
    'health_risks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($KnowledgeCardsTable.$converterhealthRisks);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> safeSteps =
      GeneratedColumn<String>(
        'safe_steps',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($KnowledgeCardsTable.$convertersafeSteps);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  callProfessionalWhen =
      GeneratedColumn<String>(
        'call_professional_when',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>(
        $KnowledgeCardsTable.$convertercallProfessionalWhen,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> firstAid =
      GeneratedColumn<String>(
        'first_aid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($KnowledgeCardsTable.$converterfirstAid);
  static const VerificationMeta _legalMeta = const VerificationMeta('legal');
  @override
  late final GeneratedColumn<String> legal = GeneratedColumn<String>(
    'legal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> sources =
      GeneratedColumn<String>(
        'sources',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($KnowledgeCardsTable.$convertersources);
  static const VerificationMeta _reviewStatusMeta = const VerificationMeta(
    'reviewStatus',
  );
  @override
  late final GeneratedColumn<String> reviewStatus = GeneratedColumn<String>(
    'review_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packVersionMeta = const VerificationMeta(
    'packVersion',
  );
  @override
  late final GeneratedColumn<String> packVersion = GeneratedColumn<String>(
    'pack_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    cardId,
    names,
    pestGroup,
    safety,
    summary,
    signs,
    lookAlikes,
    healthRisks,
    safeSteps,
    callProfessionalWhen,
    firstAid,
    legal,
    sources,
    reviewStatus,
    packVersion,
    contentHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'knowledge_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnowledgeCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('legal')) {
      context.handle(
        _legalMeta,
        legal.isAcceptableOrUnknown(data['legal']!, _legalMeta),
      );
    }
    if (data.containsKey('review_status')) {
      context.handle(
        _reviewStatusMeta,
        reviewStatus.isAcceptableOrUnknown(
          data['review_status']!,
          _reviewStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewStatusMeta);
    }
    if (data.containsKey('pack_version')) {
      context.handle(
        _packVersionMeta,
        packVersion.isAcceptableOrUnknown(
          data['pack_version']!,
          _packVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packVersionMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnowledgeCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnowledgeCardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $KnowledgeCardsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      names: $KnowledgeCardsTable.$converternames.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}names'],
        )!,
      ),
      pestGroup: $KnowledgeCardsTable.$converterpestGroup.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}pest_group'],
        )!,
      ),
      safety: $KnowledgeCardsTable.$convertersafety.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}safety'],
        )!,
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      signs: $KnowledgeCardsTable.$convertersigns.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}signs'],
        )!,
      ),
      lookAlikes: $KnowledgeCardsTable.$converterlookAlikes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}look_alikes'],
        )!,
      ),
      healthRisks: $KnowledgeCardsTable.$converterhealthRisks.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}health_risks'],
        )!,
      ),
      safeSteps: $KnowledgeCardsTable.$convertersafeSteps.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}safe_steps'],
        )!,
      ),
      callProfessionalWhen: $KnowledgeCardsTable.$convertercallProfessionalWhen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}call_professional_when'],
            )!,
          ),
      firstAid: $KnowledgeCardsTable.$converterfirstAid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}first_aid'],
        )!,
      ),
      legal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal'],
      ),
      sources: $KnowledgeCardsTable.$convertersources.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sources'],
        )!,
      ),
      reviewStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_status'],
      )!,
      packVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pack_version'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
    );
  }

  @override
  $KnowledgeCardsTable createAlias(String alias) {
    return $KnowledgeCardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
  static TypeConverter<Map<String, String>, String> $converternames =
      const StringMapConverter();
  static JsonTypeConverter2<PestGroup, String, String> $converterpestGroup =
      const EnumNameConverter<PestGroup>(PestGroup.values);
  static JsonTypeConverter2<SafetyLevel, String, String> $convertersafety =
      const EnumNameConverter<SafetyLevel>(SafetyLevel.values);
  static TypeConverter<List<String>, String> $convertersigns =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterlookAlikes =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterhealthRisks =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertersafeSteps =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertercallProfessionalWhen =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converterfirstAid =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertersources =
      const StringListConverter();
}

class KnowledgeCardRow extends DataClass
    implements Insertable<KnowledgeCardRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;

  /// Stable snake_case card id from the pack.
  final String cardId;

  /// languageTag -> name as a JSON object; 'en' is always present.
  final Map<String, String> names;
  final PestGroup pestGroup;
  final SafetyLevel safety;
  final String summary;
  final List<String> signs;
  final List<String> lookAlikes;
  final List<String> healthRisks;
  final List<String> safeSteps;
  final List<String> callProfessionalWhen;
  final List<String> firstAid;
  final String? legal;
  final List<String> sources;
  final String reviewStatus;

  /// The pack's `version`.
  final String packVersion;

  /// Hash of the text that gets embedded; a change invalidates embeddings.
  final String contentHash;
  const KnowledgeCardRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.cardId,
    required this.names,
    required this.pestGroup,
    required this.safety,
    required this.summary,
    required this.signs,
    required this.lookAlikes,
    required this.healthRisks,
    required this.safeSteps,
    required this.callProfessionalWhen,
    required this.firstAid,
    this.legal,
    required this.sources,
    required this.reviewStatus,
    required this.packVersion,
    required this.contentHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $KnowledgeCardsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['card_id'] = Variable<String>(cardId);
    {
      map['names'] = Variable<String>(
        $KnowledgeCardsTable.$converternames.toSql(names),
      );
    }
    {
      map['pest_group'] = Variable<String>(
        $KnowledgeCardsTable.$converterpestGroup.toSql(pestGroup),
      );
    }
    {
      map['safety'] = Variable<String>(
        $KnowledgeCardsTable.$convertersafety.toSql(safety),
      );
    }
    map['summary'] = Variable<String>(summary);
    {
      map['signs'] = Variable<String>(
        $KnowledgeCardsTable.$convertersigns.toSql(signs),
      );
    }
    {
      map['look_alikes'] = Variable<String>(
        $KnowledgeCardsTable.$converterlookAlikes.toSql(lookAlikes),
      );
    }
    {
      map['health_risks'] = Variable<String>(
        $KnowledgeCardsTable.$converterhealthRisks.toSql(healthRisks),
      );
    }
    {
      map['safe_steps'] = Variable<String>(
        $KnowledgeCardsTable.$convertersafeSteps.toSql(safeSteps),
      );
    }
    {
      map['call_professional_when'] = Variable<String>(
        $KnowledgeCardsTable.$convertercallProfessionalWhen.toSql(
          callProfessionalWhen,
        ),
      );
    }
    {
      map['first_aid'] = Variable<String>(
        $KnowledgeCardsTable.$converterfirstAid.toSql(firstAid),
      );
    }
    if (!nullToAbsent || legal != null) {
      map['legal'] = Variable<String>(legal);
    }
    {
      map['sources'] = Variable<String>(
        $KnowledgeCardsTable.$convertersources.toSql(sources),
      );
    }
    map['review_status'] = Variable<String>(reviewStatus);
    map['pack_version'] = Variable<String>(packVersion);
    map['content_hash'] = Variable<String>(contentHash);
    return map;
  }

  KnowledgeCardsCompanion toCompanion(bool nullToAbsent) {
    return KnowledgeCardsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      cardId: Value(cardId),
      names: Value(names),
      pestGroup: Value(pestGroup),
      safety: Value(safety),
      summary: Value(summary),
      signs: Value(signs),
      lookAlikes: Value(lookAlikes),
      healthRisks: Value(healthRisks),
      safeSteps: Value(safeSteps),
      callProfessionalWhen: Value(callProfessionalWhen),
      firstAid: Value(firstAid),
      legal: legal == null && nullToAbsent
          ? const Value.absent()
          : Value(legal),
      sources: Value(sources),
      reviewStatus: Value(reviewStatus),
      packVersion: Value(packVersion),
      contentHash: Value(contentHash),
    );
  }

  factory KnowledgeCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnowledgeCardRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $KnowledgeCardsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      cardId: serializer.fromJson<String>(json['cardId']),
      names: serializer.fromJson<Map<String, String>>(json['names']),
      pestGroup: $KnowledgeCardsTable.$converterpestGroup.fromJson(
        serializer.fromJson<String>(json['pestGroup']),
      ),
      safety: $KnowledgeCardsTable.$convertersafety.fromJson(
        serializer.fromJson<String>(json['safety']),
      ),
      summary: serializer.fromJson<String>(json['summary']),
      signs: serializer.fromJson<List<String>>(json['signs']),
      lookAlikes: serializer.fromJson<List<String>>(json['lookAlikes']),
      healthRisks: serializer.fromJson<List<String>>(json['healthRisks']),
      safeSteps: serializer.fromJson<List<String>>(json['safeSteps']),
      callProfessionalWhen: serializer.fromJson<List<String>>(
        json['callProfessionalWhen'],
      ),
      firstAid: serializer.fromJson<List<String>>(json['firstAid']),
      legal: serializer.fromJson<String?>(json['legal']),
      sources: serializer.fromJson<List<String>>(json['sources']),
      reviewStatus: serializer.fromJson<String>(json['reviewStatus']),
      packVersion: serializer.fromJson<String>(json['packVersion']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $KnowledgeCardsTable.$convertersyncState.toJson(syncState),
      ),
      'cardId': serializer.toJson<String>(cardId),
      'names': serializer.toJson<Map<String, String>>(names),
      'pestGroup': serializer.toJson<String>(
        $KnowledgeCardsTable.$converterpestGroup.toJson(pestGroup),
      ),
      'safety': serializer.toJson<String>(
        $KnowledgeCardsTable.$convertersafety.toJson(safety),
      ),
      'summary': serializer.toJson<String>(summary),
      'signs': serializer.toJson<List<String>>(signs),
      'lookAlikes': serializer.toJson<List<String>>(lookAlikes),
      'healthRisks': serializer.toJson<List<String>>(healthRisks),
      'safeSteps': serializer.toJson<List<String>>(safeSteps),
      'callProfessionalWhen': serializer.toJson<List<String>>(
        callProfessionalWhen,
      ),
      'firstAid': serializer.toJson<List<String>>(firstAid),
      'legal': serializer.toJson<String?>(legal),
      'sources': serializer.toJson<List<String>>(sources),
      'reviewStatus': serializer.toJson<String>(reviewStatus),
      'packVersion': serializer.toJson<String>(packVersion),
      'contentHash': serializer.toJson<String>(contentHash),
    };
  }

  KnowledgeCardRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? cardId,
    Map<String, String>? names,
    PestGroup? pestGroup,
    SafetyLevel? safety,
    String? summary,
    List<String>? signs,
    List<String>? lookAlikes,
    List<String>? healthRisks,
    List<String>? safeSteps,
    List<String>? callProfessionalWhen,
    List<String>? firstAid,
    Value<String?> legal = const Value.absent(),
    List<String>? sources,
    String? reviewStatus,
    String? packVersion,
    String? contentHash,
  }) => KnowledgeCardRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    cardId: cardId ?? this.cardId,
    names: names ?? this.names,
    pestGroup: pestGroup ?? this.pestGroup,
    safety: safety ?? this.safety,
    summary: summary ?? this.summary,
    signs: signs ?? this.signs,
    lookAlikes: lookAlikes ?? this.lookAlikes,
    healthRisks: healthRisks ?? this.healthRisks,
    safeSteps: safeSteps ?? this.safeSteps,
    callProfessionalWhen: callProfessionalWhen ?? this.callProfessionalWhen,
    firstAid: firstAid ?? this.firstAid,
    legal: legal.present ? legal.value : this.legal,
    sources: sources ?? this.sources,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    packVersion: packVersion ?? this.packVersion,
    contentHash: contentHash ?? this.contentHash,
  );
  KnowledgeCardRow copyWithCompanion(KnowledgeCardsCompanion data) {
    return KnowledgeCardRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      names: data.names.present ? data.names.value : this.names,
      pestGroup: data.pestGroup.present ? data.pestGroup.value : this.pestGroup,
      safety: data.safety.present ? data.safety.value : this.safety,
      summary: data.summary.present ? data.summary.value : this.summary,
      signs: data.signs.present ? data.signs.value : this.signs,
      lookAlikes: data.lookAlikes.present
          ? data.lookAlikes.value
          : this.lookAlikes,
      healthRisks: data.healthRisks.present
          ? data.healthRisks.value
          : this.healthRisks,
      safeSteps: data.safeSteps.present ? data.safeSteps.value : this.safeSteps,
      callProfessionalWhen: data.callProfessionalWhen.present
          ? data.callProfessionalWhen.value
          : this.callProfessionalWhen,
      firstAid: data.firstAid.present ? data.firstAid.value : this.firstAid,
      legal: data.legal.present ? data.legal.value : this.legal,
      sources: data.sources.present ? data.sources.value : this.sources,
      reviewStatus: data.reviewStatus.present
          ? data.reviewStatus.value
          : this.reviewStatus,
      packVersion: data.packVersion.present
          ? data.packVersion.value
          : this.packVersion,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeCardRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('cardId: $cardId, ')
          ..write('names: $names, ')
          ..write('pestGroup: $pestGroup, ')
          ..write('safety: $safety, ')
          ..write('summary: $summary, ')
          ..write('signs: $signs, ')
          ..write('lookAlikes: $lookAlikes, ')
          ..write('healthRisks: $healthRisks, ')
          ..write('safeSteps: $safeSteps, ')
          ..write('callProfessionalWhen: $callProfessionalWhen, ')
          ..write('firstAid: $firstAid, ')
          ..write('legal: $legal, ')
          ..write('sources: $sources, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('packVersion: $packVersion, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    cardId,
    names,
    pestGroup,
    safety,
    summary,
    signs,
    lookAlikes,
    healthRisks,
    safeSteps,
    callProfessionalWhen,
    firstAid,
    legal,
    sources,
    reviewStatus,
    packVersion,
    contentHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnowledgeCardRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.cardId == this.cardId &&
          other.names == this.names &&
          other.pestGroup == this.pestGroup &&
          other.safety == this.safety &&
          other.summary == this.summary &&
          other.signs == this.signs &&
          other.lookAlikes == this.lookAlikes &&
          other.healthRisks == this.healthRisks &&
          other.safeSteps == this.safeSteps &&
          other.callProfessionalWhen == this.callProfessionalWhen &&
          other.firstAid == this.firstAid &&
          other.legal == this.legal &&
          other.sources == this.sources &&
          other.reviewStatus == this.reviewStatus &&
          other.packVersion == this.packVersion &&
          other.contentHash == this.contentHash);
}

class KnowledgeCardsCompanion extends UpdateCompanion<KnowledgeCardRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> cardId;
  final Value<Map<String, String>> names;
  final Value<PestGroup> pestGroup;
  final Value<SafetyLevel> safety;
  final Value<String> summary;
  final Value<List<String>> signs;
  final Value<List<String>> lookAlikes;
  final Value<List<String>> healthRisks;
  final Value<List<String>> safeSteps;
  final Value<List<String>> callProfessionalWhen;
  final Value<List<String>> firstAid;
  final Value<String?> legal;
  final Value<List<String>> sources;
  final Value<String> reviewStatus;
  final Value<String> packVersion;
  final Value<String> contentHash;
  final Value<int> rowid;
  const KnowledgeCardsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.cardId = const Value.absent(),
    this.names = const Value.absent(),
    this.pestGroup = const Value.absent(),
    this.safety = const Value.absent(),
    this.summary = const Value.absent(),
    this.signs = const Value.absent(),
    this.lookAlikes = const Value.absent(),
    this.healthRisks = const Value.absent(),
    this.safeSteps = const Value.absent(),
    this.callProfessionalWhen = const Value.absent(),
    this.firstAid = const Value.absent(),
    this.legal = const Value.absent(),
    this.sources = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.packVersion = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnowledgeCardsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String cardId,
    required Map<String, String> names,
    required PestGroup pestGroup,
    required SafetyLevel safety,
    required String summary,
    required List<String> signs,
    required List<String> lookAlikes,
    required List<String> healthRisks,
    required List<String> safeSteps,
    required List<String> callProfessionalWhen,
    required List<String> firstAid,
    this.legal = const Value.absent(),
    required List<String> sources,
    required String reviewStatus,
    required String packVersion,
    required String contentHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cardId = Value(cardId),
       names = Value(names),
       pestGroup = Value(pestGroup),
       safety = Value(safety),
       summary = Value(summary),
       signs = Value(signs),
       lookAlikes = Value(lookAlikes),
       healthRisks = Value(healthRisks),
       safeSteps = Value(safeSteps),
       callProfessionalWhen = Value(callProfessionalWhen),
       firstAid = Value(firstAid),
       sources = Value(sources),
       reviewStatus = Value(reviewStatus),
       packVersion = Value(packVersion),
       contentHash = Value(contentHash);
  static Insertable<KnowledgeCardRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? cardId,
    Expression<String>? names,
    Expression<String>? pestGroup,
    Expression<String>? safety,
    Expression<String>? summary,
    Expression<String>? signs,
    Expression<String>? lookAlikes,
    Expression<String>? healthRisks,
    Expression<String>? safeSteps,
    Expression<String>? callProfessionalWhen,
    Expression<String>? firstAid,
    Expression<String>? legal,
    Expression<String>? sources,
    Expression<String>? reviewStatus,
    Expression<String>? packVersion,
    Expression<String>? contentHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (cardId != null) 'card_id': cardId,
      if (names != null) 'names': names,
      if (pestGroup != null) 'pest_group': pestGroup,
      if (safety != null) 'safety': safety,
      if (summary != null) 'summary': summary,
      if (signs != null) 'signs': signs,
      if (lookAlikes != null) 'look_alikes': lookAlikes,
      if (healthRisks != null) 'health_risks': healthRisks,
      if (safeSteps != null) 'safe_steps': safeSteps,
      if (callProfessionalWhen != null)
        'call_professional_when': callProfessionalWhen,
      if (firstAid != null) 'first_aid': firstAid,
      if (legal != null) 'legal': legal,
      if (sources != null) 'sources': sources,
      if (reviewStatus != null) 'review_status': reviewStatus,
      if (packVersion != null) 'pack_version': packVersion,
      if (contentHash != null) 'content_hash': contentHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnowledgeCardsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? cardId,
    Value<Map<String, String>>? names,
    Value<PestGroup>? pestGroup,
    Value<SafetyLevel>? safety,
    Value<String>? summary,
    Value<List<String>>? signs,
    Value<List<String>>? lookAlikes,
    Value<List<String>>? healthRisks,
    Value<List<String>>? safeSteps,
    Value<List<String>>? callProfessionalWhen,
    Value<List<String>>? firstAid,
    Value<String?>? legal,
    Value<List<String>>? sources,
    Value<String>? reviewStatus,
    Value<String>? packVersion,
    Value<String>? contentHash,
    Value<int>? rowid,
  }) {
    return KnowledgeCardsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      cardId: cardId ?? this.cardId,
      names: names ?? this.names,
      pestGroup: pestGroup ?? this.pestGroup,
      safety: safety ?? this.safety,
      summary: summary ?? this.summary,
      signs: signs ?? this.signs,
      lookAlikes: lookAlikes ?? this.lookAlikes,
      healthRisks: healthRisks ?? this.healthRisks,
      safeSteps: safeSteps ?? this.safeSteps,
      callProfessionalWhen: callProfessionalWhen ?? this.callProfessionalWhen,
      firstAid: firstAid ?? this.firstAid,
      legal: legal ?? this.legal,
      sources: sources ?? this.sources,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      packVersion: packVersion ?? this.packVersion,
      contentHash: contentHash ?? this.contentHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $KnowledgeCardsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (names.present) {
      map['names'] = Variable<String>(
        $KnowledgeCardsTable.$converternames.toSql(names.value),
      );
    }
    if (pestGroup.present) {
      map['pest_group'] = Variable<String>(
        $KnowledgeCardsTable.$converterpestGroup.toSql(pestGroup.value),
      );
    }
    if (safety.present) {
      map['safety'] = Variable<String>(
        $KnowledgeCardsTable.$convertersafety.toSql(safety.value),
      );
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (signs.present) {
      map['signs'] = Variable<String>(
        $KnowledgeCardsTable.$convertersigns.toSql(signs.value),
      );
    }
    if (lookAlikes.present) {
      map['look_alikes'] = Variable<String>(
        $KnowledgeCardsTable.$converterlookAlikes.toSql(lookAlikes.value),
      );
    }
    if (healthRisks.present) {
      map['health_risks'] = Variable<String>(
        $KnowledgeCardsTable.$converterhealthRisks.toSql(healthRisks.value),
      );
    }
    if (safeSteps.present) {
      map['safe_steps'] = Variable<String>(
        $KnowledgeCardsTable.$convertersafeSteps.toSql(safeSteps.value),
      );
    }
    if (callProfessionalWhen.present) {
      map['call_professional_when'] = Variable<String>(
        $KnowledgeCardsTable.$convertercallProfessionalWhen.toSql(
          callProfessionalWhen.value,
        ),
      );
    }
    if (firstAid.present) {
      map['first_aid'] = Variable<String>(
        $KnowledgeCardsTable.$converterfirstAid.toSql(firstAid.value),
      );
    }
    if (legal.present) {
      map['legal'] = Variable<String>(legal.value);
    }
    if (sources.present) {
      map['sources'] = Variable<String>(
        $KnowledgeCardsTable.$convertersources.toSql(sources.value),
      );
    }
    if (reviewStatus.present) {
      map['review_status'] = Variable<String>(reviewStatus.value);
    }
    if (packVersion.present) {
      map['pack_version'] = Variable<String>(packVersion.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnowledgeCardsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('cardId: $cardId, ')
          ..write('names: $names, ')
          ..write('pestGroup: $pestGroup, ')
          ..write('safety: $safety, ')
          ..write('summary: $summary, ')
          ..write('signs: $signs, ')
          ..write('lookAlikes: $lookAlikes, ')
          ..write('healthRisks: $healthRisks, ')
          ..write('safeSteps: $safeSteps, ')
          ..write('callProfessionalWhen: $callProfessionalWhen, ')
          ..write('firstAid: $firstAid, ')
          ..write('legal: $legal, ')
          ..write('sources: $sources, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('packVersion: $packVersion, ')
          ..write('contentHash: $contentHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardEmbeddingsTable extends CardEmbeddings
    with TableInfo<$CardEmbeddingsTable, CardEmbeddingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardEmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.localOnly.name),
      ).withConverter<SyncState>($CardEmbeddingsTable.$convertersyncState);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES knowledge_cards (card_id)',
    ),
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dimMeta = const VerificationMeta('dim');
  @override
  late final GeneratedColumn<int> dim = GeneratedColumn<int>(
    'dim',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
    'vector',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    cardId,
    modelVersion,
    dim,
    vector,
    contentHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_embeddings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardEmbeddingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('dim')) {
      context.handle(
        _dimMeta,
        dim.isAcceptableOrUnknown(data['dim']!, _dimMeta),
      );
    } else if (isInserting) {
      context.missing(_dimMeta);
    }
    if (data.containsKey('vector')) {
      context.handle(
        _vectorMeta,
        vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta),
      );
    } else if (isInserting) {
      context.missing(_vectorMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cardId, modelVersion, dim},
  ];
  @override
  CardEmbeddingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardEmbeddingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: $CardEmbeddingsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      )!,
      dim: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dim'],
      )!,
      vector: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}vector'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
    );
  }

  @override
  $CardEmbeddingsTable createAlias(String alias) {
    return $CardEmbeddingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class CardEmbeddingRow extends DataClass
    implements Insertable<CardEmbeddingRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncState syncState;
  final String cardId;
  final String modelVersion;
  final int dim;
  final Uint8List vector;

  /// The card's contentHash when this vector was computed.
  final String contentHash;
  const CardEmbeddingRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.cardId,
    required this.modelVersion,
    required this.dim,
    required this.vector,
    required this.contentHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_state'] = Variable<String>(
        $CardEmbeddingsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['card_id'] = Variable<String>(cardId);
    map['model_version'] = Variable<String>(modelVersion);
    map['dim'] = Variable<int>(dim);
    map['vector'] = Variable<Uint8List>(vector);
    map['content_hash'] = Variable<String>(contentHash);
    return map;
  }

  CardEmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return CardEmbeddingsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
      cardId: Value(cardId),
      modelVersion: Value(modelVersion),
      dim: Value(dim),
      vector: Value(vector),
      contentHash: Value(contentHash),
    );
  }

  factory CardEmbeddingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardEmbeddingRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: $CardEmbeddingsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      cardId: serializer.fromJson<String>(json['cardId']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      dim: serializer.fromJson<int>(json['dim']),
      vector: serializer.fromJson<Uint8List>(json['vector']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(
        $CardEmbeddingsTable.$convertersyncState.toJson(syncState),
      ),
      'cardId': serializer.toJson<String>(cardId),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'dim': serializer.toJson<int>(dim),
      'vector': serializer.toJson<Uint8List>(vector),
      'contentHash': serializer.toJson<String>(contentHash),
    };
  }

  CardEmbeddingRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
    String? cardId,
    String? modelVersion,
    int? dim,
    Uint8List? vector,
    String? contentHash,
  }) => CardEmbeddingRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    cardId: cardId ?? this.cardId,
    modelVersion: modelVersion ?? this.modelVersion,
    dim: dim ?? this.dim,
    vector: vector ?? this.vector,
    contentHash: contentHash ?? this.contentHash,
  );
  CardEmbeddingRow copyWithCompanion(CardEmbeddingsCompanion data) {
    return CardEmbeddingRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      dim: data.dim.present ? data.dim.value : this.dim,
      vector: data.vector.present ? data.vector.value : this.vector,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardEmbeddingRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('cardId: $cardId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('dim: $dim, ')
          ..write('vector: $vector, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    syncState,
    cardId,
    modelVersion,
    dim,
    $driftBlobEquality.hash(vector),
    contentHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardEmbeddingRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.cardId == this.cardId &&
          other.modelVersion == this.modelVersion &&
          other.dim == this.dim &&
          $driftBlobEquality.equals(other.vector, this.vector) &&
          other.contentHash == this.contentHash);
}

class CardEmbeddingsCompanion extends UpdateCompanion<CardEmbeddingRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<String> cardId;
  final Value<String> modelVersion;
  final Value<int> dim;
  final Value<Uint8List> vector;
  final Value<String> contentHash;
  final Value<int> rowid;
  const CardEmbeddingsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.cardId = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.dim = const Value.absent(),
    this.vector = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardEmbeddingsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    required String cardId,
    required String modelVersion,
    required int dim,
    required Uint8List vector,
    required String contentHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       cardId = Value(cardId),
       modelVersion = Value(modelVersion),
       dim = Value(dim),
       vector = Value(vector),
       contentHash = Value(contentHash);
  static Insertable<CardEmbeddingRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? cardId,
    Expression<String>? modelVersion,
    Expression<int>? dim,
    Expression<Uint8List>? vector,
    Expression<String>? contentHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (cardId != null) 'card_id': cardId,
      if (modelVersion != null) 'model_version': modelVersion,
      if (dim != null) 'dim': dim,
      if (vector != null) 'vector': vector,
      if (contentHash != null) 'content_hash': contentHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardEmbeddingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncState>? syncState,
    Value<String>? cardId,
    Value<String>? modelVersion,
    Value<int>? dim,
    Value<Uint8List>? vector,
    Value<String>? contentHash,
    Value<int>? rowid,
  }) {
    return CardEmbeddingsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      cardId: cardId ?? this.cardId,
      modelVersion: modelVersion ?? this.modelVersion,
      dim: dim ?? this.dim,
      vector: vector ?? this.vector,
      contentHash: contentHash ?? this.contentHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $CardEmbeddingsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (dim.present) {
      map['dim'] = Variable<int>(dim.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardEmbeddingsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('cardId: $cardId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('dim: $dim, ')
          ..write('vector: $vector, ')
          ..write('contentHash: $contentHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$KernelDatabase extends GeneratedDatabase {
  _$KernelDatabase(QueryExecutor e) : super(e);
  late final $LocationsTable locations = $LocationsTable(this);
  late final $LotsTable lots = $LotsTable(this);
  late final $HarvestsTable harvests = $HarvestsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ScansTable scans = $ScansTable(this);
  late final Trigger scansAppendOnly = Trigger(
    'CREATE TRIGGER scans_append_only BEFORE UPDATE OF id, item_id, captured_at, duration_ms, sample_rate, quality, quality_reasons, model_version, result, confidence, experimental, latency_ms, device_model, os_version, audio_retained, created_at ON scans BEGIN SELECT RAISE (ABORT, \'scans are append-only\');END',
    'scans_append_only',
  );
  late final $InspectionsTable inspections = $InspectionsTable(this);
  late final Trigger inspectionsVerifiedImmutable = Trigger(
    'CREATE TRIGGER inspections_verified_immutable BEFORE UPDATE OF id, item_id, scan_id, inspected_at, inspector, observations, verified_finding, photo_paths, created_at ON inspections BEGIN SELECT RAISE (ABORT, \'verified inspection fields are immutable\');END',
    'inspections_verified_immutable',
  );
  late final $LabeledSamplesTable labeledSamples = $LabeledSamplesTable(this);
  late final Trigger labeledSamplesImmutable = Trigger(
    'CREATE TRIGGER labeled_samples_immutable BEFORE UPDATE OF id, scan_id, item_id, label, inspection_id, grain_type, sack_material, environment, notes, created_at ON labeled_samples BEGIN SELECT RAISE (ABORT, \'labeled samples are immutable\');END',
    'labeled_samples_immutable',
  );
  late final $SightingsTable sightings = $SightingsTable(this);
  late final Trigger sightingsAnalysisImmutable = Trigger(
    'CREATE TRIGGER sightings_analysis_immutable BEFORE UPDATE OF id, role, source, observed_at, latitude, longitude, accuracy_meters, distance, analysis, sound, created_at ON sightings BEGIN SELECT RAISE (ABORT, \'sighting AI analysis is immutable\');END',
    'sightings_analysis_immutable',
  );
  late final Trigger sightingsVerifiedOnce = Trigger(
    'CREATE TRIGGER sightings_verified_once BEFORE UPDATE OF verified_finding ON sightings WHEN OLD.verified_finding IS NOT NULL BEGIN SELECT RAISE (ABORT, \'verified sighting finding is immutable\');END',
    'sightings_verified_once',
  );
  late final $SensorNodesTable sensorNodes = $SensorNodesTable(this);
  late final $SensorEventsTable sensorEvents = $SensorEventsTable(this);
  late final Trigger sensorEventsAppendOnly = Trigger(
    'CREATE TRIGGER sensor_events_append_only BEFORE UPDATE OF id, node_id, seq, started_at, duration_ms, event_class, peak_hz, min_hz, max_hz, slope_hz_per_ms, snr_db, peak_dbfs, impulses, rep_rate_hz, harmonics, signature_id, pack_version, match_score, match_experimental, location_id, item_id, created_at ON sensor_events BEGIN SELECT RAISE (ABORT, \'sensor events are append-only\');END',
    'sensor_events_append_only',
  );
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $KnowledgeCardsTable knowledgeCards = $KnowledgeCardsTable(this);
  late final $CardEmbeddingsTable cardEmbeddings = $CardEmbeddingsTable(this);
  late final Index itemsOwnerRole = Index(
    'items_owner_role',
    'CREATE INDEX items_owner_role ON items (owner_role)',
  );
  late final Index itemsLocation = Index(
    'items_location',
    'CREATE INDEX items_location ON items (location_id)',
  );
  late final Index itemsLot = Index(
    'items_lot',
    'CREATE INDEX items_lot ON items (lot_id)',
  );
  late final Index itemsHarvest = Index(
    'items_harvest',
    'CREATE INDEX items_harvest ON items (harvest_id)',
  );
  late final Index scansItemCaptured = Index(
    'scans_item_captured',
    'CREATE INDEX scans_item_captured ON scans (item_id, captured_at)',
  );
  late final Index inspectionsItem = Index(
    'inspections_item',
    'CREATE INDEX inspections_item ON inspections (item_id)',
  );
  late final Index remindersItem = Index(
    'reminders_item',
    'CREATE INDEX reminders_item ON reminders (item_id)',
  );
  late final Index labeledSamplesItem = Index(
    'labeled_samples_item',
    'CREATE INDEX labeled_samples_item ON labeled_samples (item_id)',
  );
  late final Index sightingsObserved = Index(
    'sightings_observed',
    'CREATE INDEX sightings_observed ON sightings (observed_at)',
  );
  late final Index sightingsLocation = Index(
    'sightings_location',
    'CREATE INDEX sightings_location ON sightings (location_id)',
  );
  late final Index sightingsItem = Index(
    'sightings_item',
    'CREATE INDEX sightings_item ON sightings (item_id)',
  );
  late final Index sensorEventsStarted = Index(
    'sensor_events_started',
    'CREATE INDEX sensor_events_started ON sensor_events (started_at)',
  );
  late final Index sensorEventsLocation = Index(
    'sensor_events_location',
    'CREATE INDEX sensor_events_location ON sensor_events (location_id)',
  );
  late final Index sensorEventsItem = Index(
    'sensor_events_item',
    'CREATE INDEX sensor_events_item ON sensor_events (item_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locations,
    lots,
    harvests,
    items,
    scans,
    scansAppendOnly,
    inspections,
    inspectionsVerifiedImmutable,
    labeledSamples,
    labeledSamplesImmutable,
    sightings,
    sightingsAnalysisImmutable,
    sightingsVerifiedOnce,
    sensorNodes,
    sensorEvents,
    sensorEventsAppendOnly,
    reminders,
    settings,
    knowledgeCards,
    cardEmbeddings,
    itemsOwnerRole,
    itemsLocation,
    itemsLot,
    itemsHarvest,
    scansItemCaptured,
    inspectionsItem,
    remindersItem,
    labeledSamplesItem,
    sightingsObserved,
    sightingsLocation,
    sightingsItem,
    sensorEventsStarted,
    sensorEventsLocation,
    sensorEventsItem,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scans',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'inspections',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'labeled_samples',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sightings',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sightings',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sensor_events',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
