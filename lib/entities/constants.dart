class EntityTag {
  static const appName = 'App-Name';
  static const appPlatform = 'App-Platform';
  static const appPlatformVersion = 'App-Platform-Version';
  static const appVersion = 'App-Version';
  static const contentType = 'Content-Type';
  static const unixTime = 'Unix-Time';

  static const arFs = 'ArFS';
  static const entityType = 'Entity-Type';

  static const driveId = 'Drive-Id';
  static const folderId = 'Folder-Id';
  static const parentFolderId = 'Parent-Folder-Id';
  static const fileId = 'File-Id';
  static const snapshotId = 'Snapshot-Id';

  static const drivePrivacy = 'Drive-Privacy';
  static const driveAuthMode = 'Drive-Auth-Mode';

  static const cipher = 'Cipher';
  static const cipherIv = 'Cipher-IV';

  static const protocolName = 'Protocol-Name';
  static const action = 'Action';
  static const input = 'Input';
  static const contract = 'Contract';

  static const blockStart = 'Block-Start';
  static const blockEnd = 'Block-End';
  static const dataStart = 'Data-Start';
  static const dataEnd = 'Data-End';
}

class ContentType {
  static const json = 'application/json';
  static const octetStream = 'application/octet-stream';
  static const manifest = 'application/x.arweave-manifest+json';
}

class EntityType {
  static const drive = 'drive';
  static const folder = 'folder';
  static const file = 'file';
  static const snapshot = 'snapshot';
}

class Cipher {
  static const aes256 = 'AES256-GCM';
}

class DrivePrivacy {
  static const public = 'public';
  static const private = 'private';
}

class DriveAuthMode {
  static const password = 'password';
  static const none = 'none';
}

const String rootPath = '';
const int maxConcurrentUploadCount = 32;
const String linkOriginProduction = 'https://app.ardrive.io';
