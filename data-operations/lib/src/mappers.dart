import 'package:kernel_contracts/kernel_contracts.dart';

import 'db/database.dart';

// Row -> contracts model. Drift row types never leave this package.

extension ItemRowMapping on ItemRow {
  GrainItem toModel() => GrainItem(
    id: id,
    ownerRole: ownerRole,
    label: label,
    grainType: grainType,
    quantity: quantity,
    quantityUnit: quantityUnit,
    storageDate: storageDate,
    locationId: locationId,
    lotId: lotId,
    createdAt: createdAt,
    updatedAt: updatedAt,
    syncState: syncState,
  );
}

extension LocationRowMapping on LocationRow {
  Location toModel() => Location(
    id: id,
    type: type,
    name: name,
    parentId: parentId,
    createdAt: createdAt,
    updatedAt: updatedAt,
    syncState: syncState,
  );
}

extension LotRowMapping on LotRow {
  Lot toModel() => Lot(
    id: id,
    code: code,
    supplierId: supplierId,
    supplierName: supplierName,
    grainType: grainType,
    declaredQuantity: declaredQuantity,
    quantityUnit: quantityUnit,
    receivedAt: receivedAt,
    screeningStatus: screeningStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
    syncState: syncState,
  );
}

extension ScanRowMapping on ScanRow {
  ScanRecord toModel() => ScanRecord(
    id: id,
    itemId: itemId,
    capturedAt: capturedAt,
    durationMs: durationMs,
    sampleRate: sampleRate,
    quality: quality,
    qualityReasons: List.unmodifiable(qualityReasons),
    modelVersion: modelVersion,
    result: result,
    confidence: confidence,
    experimental: experimental,
    latencyMs: latencyMs,
    deviceModel: deviceModel,
    osVersion: osVersion,
    createdAt: createdAt,
    updatedAt: updatedAt,
    syncState: syncState,
  );
}

extension InspectionRowMapping on InspectionRow {
  Inspection toModel() => Inspection(
    id: id,
    itemId: itemId,
    scanId: scanId,
    inspectedAt: inspectedAt,
    inspector: inspector,
    observations: observations,
    verifiedFinding: verifiedFinding,
    followUpStatus: followUpStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
    syncState: syncState,
  );
}

extension ReminderRowMapping on ReminderRow {
  Reminder toModel() => Reminder(
    id: id,
    itemId: itemId,
    dueAt: dueAt,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    syncState: syncState,
  );
}
