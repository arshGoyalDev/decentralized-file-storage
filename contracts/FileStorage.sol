// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FileStorage {
    enum StorageTier {
        HOT, // Frequently accessed, IPFS pinning
        WARM, // Moderate access, Storj/Filecoin
        COLD, // Rare access, Arweave
        ARCHIVE // Long-term retention, Arweave
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
    mapping(string => mapping(address => AccessPermission))
        private accessPermissions;
    mapping(address => string[]) private userFiles;
    mapping(string => MigrationRecord[]) private migrationHistory;

    uint256 public totalFiles;
    uint256 public totalStorageUsed;

    event FileUploaded(
        string indexed fileId,
        address indexed owner,
        string filename,
        uint256 fileSize,
        StorageTier tier,
        Provider provider
    );

    event FileDeleted(
        string indexed fileId,
        address indexed owner,
        uint256 timestamp
    );

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
        require(
            files[fileId].owner == msg.sender ||
                files[fileId].isPublic ||
                _hasValidPermission(fileId, msg.sender),
            "Access denied"
        );
        _;
    }

    function uploadFile(
        string memory fileId,
        string memory filename,
        uint256 fileSize,
        string memory mimeType,
        StorageTier tier,
        Provider provider,
        string memory contentHash,
        bool encrypted,
        bool isPublic
    ) external {
        require(!files[fileId].exists, "File already exists");
        require(bytes(fileId).length > 0, "Invalid file ID");
        require(bytes(contentHash).length > 0, "Invalid content hash");

        files[fileId] = FileMetadata({
            fileId: fileId,
            filename: filename,
            fileSize: fileSize,
            mimeType: mimeType,
            tier: tier,
            provider: provider,
            contentHash: contentHash,
            backupHash: "",
            encrypted: encrypted,
            isPublic: isPublic,
            owner: msg.sender,
            uploadTime: block.timestamp,
            lastAccessed: block.timestamp,
            accessCount: 0,
            exists: true
        });

        userFiles[msg.sender].push(fileId);
        totalFiles++;
        totalStorageUsed += fileSize;

        emit FileUploaded(
            fileId,
            msg.sender,
            filename,
            fileSize,
            tier,
            provider
        );
    }

    function deleteFile(string memory fileId) external onlyFileOwner(fileId) {
        totalStorageUsed -= files[fileId].fileSize;
        totalFiles--;

        delete files[fileId];

        emit FileDeleted(fileId, msg.sender, block.timestamp);
    }

    function _hasValidPermission(
        string memory fileId,
        address user
    ) internal view returns (bool) {
        AccessPermission memory permission = accessPermissions[fileId][user];

        if (!permission.exists) {
            return false;
        }

        if (
            permission.expiryTime != 0 &&
            block.timestamp > permission.expiryTime
        ) {
            return false;
        }

        return permission.canRead;
    }
}
