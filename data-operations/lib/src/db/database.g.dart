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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    syncState,
    type,
    name,
    parentId,
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
  const LocationRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.syncState,
    required this.type,
    required this.name,
    this.parentId,
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
  }) => LocationRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
    type: type ?? this.type,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
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
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, syncState, type, name, parentId);
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
          other.parentId == this.parentId);
}

class LocationsCompanion extends UpdateCompanion<LocationRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncState> syncState;
  final Value<LocationType> type;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> rowid;
  const LocationsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
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
          ..write('screeningStatus: $screeningStatus')
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
          other.screeningStatus == this.screeningStatus);
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
          ..write('lotId: $lotId')
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
          other.lotId == this.lotId);
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
          ..write('osVersion: $osVersion')
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
          other.osVersion == this.osVersion);
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
          ..write('followUpStatus: $followUpStatus')
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
          other.followUpStatus == this.followUpStatus);
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

abstract class _$KernelDatabase extends GeneratedDatabase {
  _$KernelDatabase(QueryExecutor e) : super(e);
  late final $LocationsTable locations = $LocationsTable(this);
  late final $LotsTable lots = $LotsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ScansTable scans = $ScansTable(this);
  late final Trigger scansAppendOnly = Trigger(
    'CREATE TRIGGER scans_append_only BEFORE UPDATE OF id, item_id, captured_at, duration_ms, sample_rate, quality, quality_reasons, model_version, result, confidence, experimental, latency_ms, device_model, os_version, created_at ON scans BEGIN SELECT RAISE (ABORT, \'scans are append-only\');END',
    'scans_append_only',
  );
  late final $InspectionsTable inspections = $InspectionsTable(this);
  late final Trigger inspectionsVerifiedImmutable = Trigger(
    'CREATE TRIGGER inspections_verified_immutable BEFORE UPDATE OF id, item_id, scan_id, inspected_at, inspector, observations, verified_finding, created_at ON inspections BEGIN SELECT RAISE (ABORT, \'verified inspection fields are immutable\');END',
    'inspections_verified_immutable',
  );
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locations,
    lots,
    items,
    scans,
    scansAppendOnly,
    inspections,
    inspectionsVerifiedImmutable,
    reminders,
    settings,
    itemsOwnerRole,
    itemsLocation,
    itemsLot,
    scansItemCaptured,
    inspectionsItem,
    remindersItem,
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
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
