// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FileversePortal.sol";

/// @custom:security-contact security@fileverse.io
contract GranularPermission is Ownable {
    // Reference to the FileversePortal contract
    FileversePortal public portalContract;
    
    // Permission types as enum for clearer semantics
    enum Permission {
        NONE,      // No permissions (0)
        READ,      // Read-only permission (1)
        WRITE      // Write permission, implicitly includes read capability (2)
    }
    
    // Sentinel value for linked lists
    address constant SENTINEL_USER = address(0x1);
    uint256 constant SENTINEL_FILE = type(uint256).max;
    
    // Function selector from FileversePortal for the editFile function
    bytes4 private constant EDIT_FILE_SELECTOR = bytes4(keccak256("editFile(uint256,string,string,string,uint8,uint256)"));
    
    /**
     * @notice Maps a user's address to a file ID to their permission level
     * The value represents the user's highest permission for the file:
     * - 0: No permissions (NONE)
     * - 1: READ permission
     * - 2: WRITE permission (implicitly includes READ capability)
     */
    mapping(address => mapping(uint256 => Permission)) private permissions;
    
    /**
     * @notice User-File linked list: userFileNext[user][file] = nextFile
     * This creates a linked list of files for each user, enabling efficient traversal
     * of all files a user has permissions for, and efficient removal of permissions.
     */
    mapping(address => mapping(uint256 => uint256)) private userFileNext;
    
    /**
     * @notice File-User linked list: fileUserNext[file][user] = nextUser
     * This creates a linked list of users for each file, enabling efficient traversal
     * of all users who have permissions for a file, and efficient revocation.
     */
    mapping(uint256 => mapping(address => address)) private fileUserNext;
    
    /**
     * @notice Counts of active permissions per user
     * Maintains an accurate count of how many files a user has permissions for,
     * avoiding the need to iterate through the entire linked list to get the count.
     */
    mapping(address => uint256) private userPermissionCount;
    
    /**
     * @notice Counts of active permissions per file
     * Maintains an accurate count of how many users have permissions for a file,
     * avoiding the need to iterate through the entire linked list to get the count.
     */
    mapping(uint256 => uint256) private filePermissionCount;
    
    // Events
    event PermissionUpdated(address indexed user, uint256 indexed fileId, Permission newPermission);
    event ProxyOperationPerformed(address indexed user, uint256 indexed fileId, bytes4 indexed functionSelector);
    
    /**
     * @notice Constructor for the GranularPermission contract
     * @param _portalContract Address of the FileversePortal contract
     */
    constructor(address _portalContract) {
        require(_portalContract != address(0), "FP001: Portal contract cannot be zero address");
        portalContract = FileversePortal(_portalContract);
        
        // Initialize sentinel values for all linked lists
        userFileNext[SENTINEL_USER][SENTINEL_FILE] = SENTINEL_FILE;
        fileUserNext[SENTINEL_FILE][SENTINEL_USER] = SENTINEL_USER;
    }
    
    /**
     * @notice Modifier to ensure the file exists
     * @param fileId ID of the file
     */
    modifier fileExists(uint256 fileId) {
        require(fileId < portalContract.getFileCount(), "FP004: File does not exist");
        _;
    }
    
    /**
     * @notice Modifier to check if the permissions contract is a collaborator
     */
    modifier isCollaboratorCheck() {
        require(portalContract.isCollaborator(address(this)), "FP008: Contract must be a collaborator");
        _;
    }
    
    /**
     * @notice Check if a user has a relationship with a file in the tracking system
     * @param user Address of the user
     * @param fileId ID of the file
     * @return isTracked Whether the user-file relationship is tracked
     */
    function isUserFileTracked(address user, uint256 fileId) public view returns (bool) {
        // Check if the file is in the user's linked list
        return userFileNext[user][fileId] != 0;
    }
    
    /**
     * @notice Update a user's permission for a file
     * @param user Address of the user
     * @param fileId ID of the file
     * @param newPermission New permission level to set
     */
    function updatePermission(
        address user,
        uint256 fileId,
        Permission newPermission
    ) public onlyOwner fileExists(fileId) {
        require(user != address(0), "FP005: User cannot be zero address");
        
        // Get current permission
        Permission currentPermission = permissions[user][fileId];
        
        // Only proceed if the permission is actually changing
        if (currentPermission != newPermission) {
            // Update the permission
            permissions[user][fileId] = newPermission;
            
            // If adding a permission where none existed before, add tracking entries
            if (currentPermission == Permission.NONE && newPermission != Permission.NONE) {
                // Add to user's file list
                if (!isUserFileTracked(user, fileId)) {
                    _addUserFileLink(user, fileId);
                    
                    // Add to file's user list
                    _addFileUserLink(fileId, user);
                    
                    // Increment counters
                    userPermissionCount[user]++;
                    filePermissionCount[fileId]++;
                }
            } 
            // If revoking all permissions, remove tracking entries
            else if (currentPermission != Permission.NONE && newPermission == Permission.NONE) {
                // Remove from tracking
                _removeUserFileLink(user, fileId);
                _removeFileUserLink(fileId, user);
                
                // Decrement counters
                if (userPermissionCount[user] > 0) userPermissionCount[user]--;
                if (filePermissionCount[fileId] > 0) filePermissionCount[fileId]--;
            }
            
            emit PermissionUpdated(user, fileId, newPermission);
        }
    }
    
    /**
     * @notice Update permissions for multiple users on a file
     * @param users Array of user addresses
     * @param fileId ID of the file
     * @param newPermission New permission level to set
     */
    function updateBatchPermissions(
        address[] calldata users,
        uint256 fileId,
        Permission newPermission
    ) public onlyOwner fileExists(fileId) {
        uint256 length = users.length;
        // Using unchecked for gas optimization in loop counter
        for (uint256 i = 0; i < length;) {
            if (users[i] != address(0)) {
                updatePermission(users[i], fileId, newPermission);
            }
            
            unchecked { ++i; }
        }
    }
    
    /**
     * @notice Revoke all permissions for a specific file for all users
     * @param fileId ID of the file
     */
    function revokeAllFilePermissions(uint256 fileId) public onlyOwner fileExists(fileId) {
        // Traverse the linked list of users for this file
        address prevUser = SENTINEL_USER;
        address currentUser = fileUserNext[fileId][SENTINEL_USER];
        
        while (currentUser != SENTINEL_USER) {
            address nextUser = fileUserNext[fileId][currentUser];
            
            // Revoke permission for this user
            if (permissions[currentUser][fileId] != Permission.NONE) {
                // Remove user from file's list
                fileUserNext[fileId][prevUser] = nextUser;
                fileUserNext[fileId][currentUser] = address(0);
                
                // Remove file from user's list
                _removeUserFileLink(currentUser, fileId);
                
                // Update permission
                permissions[currentUser][fileId] = Permission.NONE;
                
                // Decrement counters
                if (userPermissionCount[currentUser] > 0) userPermissionCount[currentUser]--;
                
                emit PermissionUpdated(currentUser, fileId, Permission.NONE);
            } else {
                prevUser = currentUser;
            }
            
            currentUser = nextUser;
        }
        
        // Reset file permission count
        filePermissionCount[fileId] = 0;
    }
    
    /**
     * @notice Add a file to a user's linked list of files
     * @param user Address of the user
     * @param fileId ID of the file to add
     */
    function _addUserFileLink(address user, uint256 fileId) internal {
        // Initialize user's linked list if needed
        if (userFileNext[user][SENTINEL_FILE] == 0) {
            userFileNext[user][SENTINEL_FILE] = SENTINEL_FILE;
        }
        
        // Add file to the beginning of user's list (right after sentinel)
        userFileNext[user][fileId] = userFileNext[user][SENTINEL_FILE];
        userFileNext[user][SENTINEL_FILE] = fileId;
    }
    
    /**
     * @notice Add a user to a file's linked list of users
     * @param fileId ID of the file
     * @param user Address of the user to add
     */
    function _addFileUserLink(uint256 fileId, address user) internal {
        // Initialize file's linked list if needed
        if (fileUserNext[fileId][SENTINEL_USER] == address(0)) {
            fileUserNext[fileId][SENTINEL_USER] = SENTINEL_USER;
        }
        
        // Add user to the beginning of file's list (right after sentinel)
        fileUserNext[fileId][user] = fileUserNext[fileId][SENTINEL_USER];
        fileUserNext[fileId][SENTINEL_USER] = user;
    }
    
    /**
     * @notice Remove a file from a user's linked list
     * @param user Address of the user
     * @param fileId ID of the file to remove
     */
    function _removeUserFileLink(address user, uint256 fileId) internal {
        // Find the file in the user's list
        uint256 prevFileId = SENTINEL_FILE;
        uint256 currentFileId = userFileNext[user][SENTINEL_FILE];
        
        while (currentFileId != SENTINEL_FILE && currentFileId != fileId) {
            prevFileId = currentFileId;
            currentFileId = userFileNext[user][currentFileId];
        }
        
        // If file was found, remove it from the list
        if (currentFileId == fileId) {
            userFileNext[user][prevFileId] = userFileNext[user][fileId];
            userFileNext[user][fileId] = 0; // Clear the next pointer
        }
    }
    
    /**
     * @notice Remove a user from a file's linked list
     * @param fileId ID of the file
     * @param user Address of the user to remove
     */
    function _removeFileUserLink(uint256 fileId, address user) internal {
        // Find the user in the file's list
        address prevUser = SENTINEL_USER;
        address currentUser = fileUserNext[fileId][SENTINEL_USER];
        
        while (currentUser != SENTINEL_USER && currentUser != user) {
            prevUser = currentUser;
            currentUser = fileUserNext[fileId][currentUser];
        }
        
        // If user was found, remove it from the list
        if (currentUser == user) {
            fileUserNext[fileId][prevUser] = fileUserNext[fileId][user];
            fileUserNext[fileId][user] = address(0); // Clear the next pointer
        }
    }
    
    /**
     * @notice Get all files a user has active permissions for
     * @param user Address of the user
     * @param maxResults Maximum number of results to return
     * @return activeFiles Array of file IDs the user has actual permissions for
     * @return totalCount Total number of files with permissions (may be more than returned)
     */
    function getUserActiveFiles(
        address user, 
        uint256 maxResults
    ) public view returns (uint256[] memory activeFiles, uint256 totalCount) {
        totalCount = userPermissionCount[user];
        
        // Create array for results (capped by maxResults)
        uint256 resultCount = totalCount > maxResults ? maxResults : totalCount;
        activeFiles = new uint256[](resultCount);
        
        // Traverse the linked list
        uint256 currentFileId = userFileNext[user][SENTINEL_FILE];
        for (uint256 i = 0; i < resultCount && currentFileId != SENTINEL_FILE; i++) {
            activeFiles[i] = currentFileId;
            currentFileId = userFileNext[user][currentFileId];
        }
        
        return (activeFiles, totalCount);
    }
    
    /**
     * @notice Get a paginated list of files a user has active permissions for
     * @param user Address of the user
     * @param startAfter File ID to start after (for pagination)
     * @param maxResults Maximum number of results to return
     * @return activeFiles Array of file IDs the user has actual permissions for
     * @return hasMore Whether there are more files beyond what was returned
     */
    function getUserActiveFilesPaginated(
        address user,
        uint256 startAfter,
        uint256 maxResults
    ) public view returns (uint256[] memory activeFiles, bool hasMore) {
        // Initialize array with max size
        activeFiles = new uint256[](maxResults);
        
        // Find starting point in linked list
        uint256 currentFileId;
        if (startAfter == 0) {
            // Start from beginning
            currentFileId = userFileNext[user][SENTINEL_FILE];
        } else {
            // Start after the specified file
            currentFileId = userFileNext[user][startAfter];
        }
        
        // Collect up to maxResults files
        uint256 count = 0;
        while (count < maxResults && currentFileId != SENTINEL_FILE) {
            activeFiles[count] = currentFileId;
            count++;
            currentFileId = userFileNext[user][currentFileId];
        }
        
        // Check if there are more results
        hasMore = (currentFileId != SENTINEL_FILE);
        
        // If we didn't fill the array, resize it
        if (count < maxResults) {
            // Create a new array with the actual size
            uint256[] memory resizedArray = new uint256[](count);
            for (uint256 i = 0; i < count; i++) {
                resizedArray[i] = activeFiles[i];
            }
            return (resizedArray, hasMore);
        }
        
        return (activeFiles, hasMore);
    }
    
    /**
     * @notice Get all users who have active permissions for a file
     * @param fileId ID of the file
     * @param maxResults Maximum number of results to return
     * @return activeUsers Array of users who have actual permissions for the file
     * @return totalCount Total number of users with permissions (may be more than returned)
     */
    function getFileActiveUsers(
        uint256 fileId, 
        uint256 maxResults
    ) public view fileExists(fileId) returns (address[] memory activeUsers, uint256 totalCount) {
        totalCount = filePermissionCount[fileId];
        
        // Create array for results (capped by maxResults)
        uint256 resultCount = totalCount > maxResults ? maxResults : totalCount;
        activeUsers = new address[](resultCount);
        
        // Traverse the linked list
        address currentUser = fileUserNext[fileId][SENTINEL_USER];
        for (uint256 i = 0; i < resultCount && currentUser != SENTINEL_USER; i++) {
            activeUsers[i] = currentUser;
            currentUser = fileUserNext[fileId][currentUser];
        }
        
        return (activeUsers, totalCount);
    }
    
    /**
     * @notice Get a paginated list of users who have active permissions for a file
     * @param fileId ID of the file
     * @param startAfter Address to start after (for pagination)
     * @param maxResults Maximum number of results to return
     * @return activeUsers Array of users who have actual permissions for the file
     * @return hasMore Whether there are more users beyond what was returned
     */
    function getFileActiveUsersPaginated(
        uint256 fileId,
        address startAfter,
        uint256 maxResults
    ) public view fileExists(fileId) returns (address[] memory activeUsers, bool hasMore) {
        // Initialize array with max size
        activeUsers = new address[](maxResults);
        
        // Find starting point in linked list
        address currentUser;
        if (startAfter == address(0)) {
            // Start from beginning
            currentUser = fileUserNext[fileId][SENTINEL_USER];
        } else {
            // Start after the specified user
            currentUser = fileUserNext[fileId][startAfter];
        }
        
        // Collect up to maxResults users
        uint256 count = 0;
        while (count < maxResults && currentUser != SENTINEL_USER) {
            activeUsers[count] = currentUser;
            count++;
            currentUser = fileUserNext[fileId][currentUser];
        }
        
        // Check if there are more results
        hasMore = (currentUser != SENTINEL_USER);
        
        // If we didn't fill the array, resize it
        if (count < maxResults) {
            // Create a new array with the actual size
            address[] memory resizedArray = new address[](count);
            for (uint256 i = 0; i < count; i++) {
                resizedArray[i] = activeUsers[i];
            }
            return (resizedArray, hasMore);
        }
        
        return (activeUsers, hasMore);
    }
    
    /**
     * @notice Check if a user has READ permission for a file
     * @param user Address of the user
     * @param fileId ID of the file
     * @return hasReadPermission Whether the user has READ permission
     */
    function hasReadPermission(address user, uint256 fileId) public view returns (bool) {
        Permission userPermission = permissions[user][fileId];
        return userPermission == Permission.READ || userPermission == Permission.WRITE;
    }
    
    /**
     * @notice Check if a user has WRITE permission for a file
     * @param user Address of the user
     * @param fileId ID of the file
     * @return hasWritePermission Whether the user has WRITE permission
     */
    function hasWritePermission(address user, uint256 fileId) public view returns (bool) {
        return permissions[user][fileId] == Permission.WRITE;
    }
    
    /**
     * @notice Get a user's permission level for a file
     * @param user Address of the user
     * @param fileId ID of the file
     * @return permissionLevel The user's permission level
     */
    function getPermission(address user, uint256 fileId) public view returns (Permission) {
        return permissions[user][fileId];
    }
    
    /**
     * @notice Get permission details for a specific range of files for a user
     * @param user Address of the user
     * @param fileIds Array of file IDs to check
     * @return filePermissions Array of permissions for each file
     */
    function getUserFilePermissions(
        address user, 
        uint256[] calldata fileIds
    ) public view returns (Permission[] memory filePermissions) {
        filePermissions = new Permission[](fileIds.length);
        
        for (uint256 i = 0; i < fileIds.length; i++) {
            if (fileIds[i] < portalContract.getFileCount()) {
                filePermissions[i] = permissions[user][fileIds[i]];
            } else {
                filePermissions[i] = Permission.NONE; // Invalid file ID
            }
        }
        
        return filePermissions;
    }
    
    /**
     * @notice Execute a transaction to the portal contract with permission checking
     * @param user Address of the user on whose behalf the call is made
     * @param data Calldata for the function call
     * @return result The result data from the call
     */
    function executeTransaction(address user, bytes calldata data) 
        public 
        isCollaboratorCheck 
        returns (bytes memory result) 
    {
        require(msg.sender == user || msg.sender == owner(), "FP012: Only user or owner can request proxy operations");
        require(data.length >= 4, "FP013: Invalid calldata");
        
        bytes4 selector = bytes4(data[:4]);
        
        // We only support the edit file operation for users
        if (selector == EDIT_FILE_SELECTOR) {
            uint256 fileId = extractFileId(data);
            require(permissions[user][fileId] == Permission.WRITE, "FP009: User does not have write permission");
            
            (bool success, bytes memory returnData) = address(portalContract).call(data);
            require(success, "FP014: Transaction execution failed");
            
            emit ProxyOperationPerformed(user, fileId, selector);
            return returnData;
        }
        else {
            revert("FP015: Unsupported function selector");
        }
    }
    
    /**
     * @notice Extract fileId from edit function calldata
     * @param data Calldata for the function call
     * @return fileId The ID of the file being edited
     */
    function extractFileId(bytes calldata data) internal pure returns (uint256 fileId) {
        require(data.length >= 36, "FP016: Invalid data for extracting fileId");
        
        // The fileId is the first parameter after the function selector
        // Function selector is 4 bytes, and fileId is a uint256 (32 bytes)
        assembly {
            fileId := calldataload(add(data.offset, 4))
        }
    }
    
    /**
     * @notice Get file details with permission check
     * @param user Address of the user requesting the file
     * @param fileId ID of the file to get
     * @return metadataIPFSHash The IPFS hash of the metadata file
     * @return contentIPFSHash The IPFS hash of the file's content
     * @return gateIPFSHash The IPFS hash of the gate file
     * @return fileType Type of the file
     * @return version Version of the key used to handle the file
     */
    function getFileWithPermissionCheck(address user, uint256 fileId) 
        public 
        view 
        fileExists(fileId) 
        returns (
            string memory metadataIPFSHash,
            string memory contentIPFSHash,
            string memory gateIPFSHash,
            FileversePortal.FileType fileType,
            uint256 version
        ) 
    {
        require(hasReadPermission(user, fileId), "FP010: User does not have read permission");
        return portalContract.files(fileId);
    }
    
    /**
     * @notice Administrative function to add a file through the permissions contract
     * Used by the owner only to create files that can then have permissions set for users
     * @param _metadataIPFSHash The IPFS hash of the metadata file
     * @param _contentIPFSHash The IPFS hash of the file's content
     * @param _gateIPFSHash The IPFS hash of the gate file
     * @param filetype Type of the file (PUBLIC, PRIVATE, GATED, MEMBER_PRIVATE)
     * @param version Version of the key used to handle the file
     * @return fileId ID of the new file
     */
    function adminAddFile(
        string calldata _metadataIPFSHash,
        string calldata _contentIPFSHash,
        string calldata _gateIPFSHash,
        FileversePortal.FileType filetype,
        uint256 version
    ) public onlyOwner isCollaboratorCheck returns (uint256) {
        uint256 currentFileCount = portalContract.getFileCount();
        
        portalContract.addFile(
            _metadataIPFSHash,
            _contentIPFSHash,
            _gateIPFSHash,
            filetype,
            version
        );
        
        return currentFileCount; // The new file ID will be the previous count
    }
    
    /**
     * @notice Get the count of files a user has permissions for
     * @param user The user's address
     * @return count The number of files the user has permissions for
     */
    function getUserFileCount(address user) public view returns (uint256) {
        return userPermissionCount[user];
    }
    
    /**
     * @notice Get the count of users who have permissions for a file
     * @param fileId The file ID
     * @return count The number of users who have permissions for the file
     */
    function getFileUserCount(uint256 fileId) public view returns (uint256) {
        return filePermissionCount[fileId];
    }
}