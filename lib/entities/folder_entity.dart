import 'dart:convert';
import 'dart:typed_data';

import 'package:ardrive/core/crypto/crypto.dart';
import 'package:ardrive/models/custom_metadata_type.dart';
import 'package:ardrive/services/services.dart';
import 'package:arweave/arweave.dart';
import 'package:cryptography/cryptography.dart';
import 'package:json_annotation/json_annotation.dart';

import 'entities.dart';

part 'folder_entity.g.dart';

@JsonSerializable()
class FolderEntity extends Entity {
  @JsonKey(ignore: true)
  String? id;
  @JsonKey(ignore: true)
  String? driveId;
  @JsonKey(ignore: true)
  String? parentFolderId;

  String? name;

  @JsonKey(
    ignore: true,
    fromJson: CustomMetadata.fromJson,
    toJson: CustomMetadata.toJson,
  )
  CustomMetadata? customMetadata;

  FolderEntity({
    this.id,
    this.driveId,
    this.parentFolderId,
    this.name,
    this.customMetadata,
  }) : super(ArDriveCrypto());

  static Future<FolderEntity> fromTransaction(
    TransactionCommonMixin transaction,
    ArDriveCrypto crypto,
    Uint8List data, [
    SecretKey? driveKey,
  ]) async {
    try {
      Map<String, dynamic>? entityJson;
      if (driveKey == null) {
        entityJson = json.decode(utf8.decode(data));
      } else {
        entityJson = await crypto.decryptEntityJson(
          transaction,
          data,
          driveKey,
        );
      }

      return FolderEntity.fromJson(entityJson!)
        ..id = transaction.getTag(EntityTag.folderId)
        ..driveId = transaction.getTag(EntityTag.driveId)
        ..parentFolderId = transaction.getTag(EntityTag.parentFolderId)
        ..txId = transaction.id
        ..ownerAddress = transaction.owner.address
        ..createdAt = transaction.getCommitTime();
    } catch (_) {
      throw EntityTransactionParseException(transactionId: transaction.id);
    }
  }

  @override
  void addEntityTagsToTransaction<T extends TransactionBase>(T tx) {
    assert(id != null && driveId != null && name != null);

    tx
      ..addArFsTag()
      ..addTag(EntityTag.entityType, EntityType.folder)
      ..addTag(EntityTag.driveId, driveId!)
      ..addTag(EntityTag.folderId, id!);

    if (parentFolderId != null) {
      tx.addTag(EntityTag.parentFolderId, parentFolderId!);
    }
  }

  factory FolderEntity.fromJson(Map<String, dynamic> json) =>
      _$FolderEntityFromJson(json);
  Map<String, dynamic> toJson() => _$FolderEntityToJson(this);
}
