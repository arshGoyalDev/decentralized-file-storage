pragma solidity ^0.8.20;

contract FileStorage {
  enum StorageTier {
    HOT,
    WARM,
    COLD,
    ARCHIVE
  }

  enum Provider {
    IPFS,
    FILECOIN,
    ARWEAVE,
    STORJ,
    HYBRID
  }

  struct FileMetadata {
    string fileId;
    string filename;
    uint256 fileSize;
    string mimeType;
    StorageTier tier;
    Provider provider;
    string contentHash;
    string backupHash;
    bool encrypted;
    bool isPublic;
    address owner;
    uint256 uploadTime;
    uint256 lastAccessed;
    uint256 accessCount;
    bool exists;
  }

  struct AccessPermission {
    address grantee;
    bool canRead;
    bool canWrite;
    bool canDelete;
    uint256 expiryTime;
    bool exists;
  }

  struct MigrationRecord {
    StorageTier fromTier;
    StorageTier toTier;
    Provider fromProvider;
    Provider toProvider;
    uint256 timestamp;
    string reason;
  }

  mapping(string => FileMetadata) private files;
  mapping(string => address[]) private fileAccessList;
  mapping(string => mapping(address => AccessPermission)) private accessPermissions;
  mapping(address => string[]) private userFiles;
  mapping(string => MigrationRecord[]) private migrationHistory;

  uint256 public totalFiles;
  uint256 public totalStorageUsed;

  modifier onlyFileOwner(string memory fileId) {
    require(files[fileId].exists, "File does not exist");
    require(files[fileId].owner == msg.sender, "Not file owner");
    _;
  }

  modifier fileExists(string memory fileId) {
    require(files[fileId].exists, "File does not exist");
    _;
  }

  modifier hasReadAccess(string memory fileId) {
    require(files[fileId].exists, "File does not exist");
    require(files[fileId].owner == msg.sender || files[fileId].isPublic || _hasValidPermission(fileId, msg.sender), "Access denied");
    _;
  }
}
