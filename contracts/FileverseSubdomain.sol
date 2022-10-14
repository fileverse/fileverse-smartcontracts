// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact security@fileverse.io
contract FileverseSubdomain is Ownable {
    using Counters for Counters.Counter;

    string public metadataIPFSHash;

    address internal constant SENTINEL_COLLABORATOR = address(0x1);

    mapping(address => address) internal collaborators;
    uint256 internal collaboratorCount;

    Counters.Counter private _fileIdCounter;

    struct KeyVerifier {
        string decryptionKeyVerifier;
        string encryptionKeyVerifier;
    }

    mapping(uint256 => KeyVerifier) public keyVerifiers;

    struct Member {
        string viewDid;
        string editDid;
    }

    mapping(address => Member) public members;

    enum FileType {
        PUBLIC,
        PRIVATE,
        GATED
    }

    struct File {
        string metadataIPFSHash;
        string contentIPFSHash;
        string gateIPFSHash;
        FileType fileType;
        uint256 version;
    }

    mapping(uint256 => File) public files;

    constructor(
        string memory _metadataIPFSHash,
        string memory _ownerViewDid,
        string memory _ownerEditDid
    ) {
        metadataIPFSHash = _metadataIPFSHash;
        address[] memory _collaborators = new address[](1);
        _collaborators[0] = _msgSender();
        setupCollaborators(_collaborators);
        setupMember(_msgSender(), _ownerViewDid, _ownerEditDid);
    }

    function setupMember(
        address account,
        string memory viewDid,
        string memory editDid
    ) internal {
        require(bytes(viewDid).length > 0, "FV201");
        require(bytes(editDid).length > 0, "FV201");
        members[account] = Member(viewDid, editDid);
        emit RegisteredMember(account);
    }

    function setupCollaborators(address[] memory _collaborators) internal {
        // Initializing Subdomain collaborators.
        require(_collaborators.length > 0, "FV202");
        address currentCollaborator = SENTINEL_COLLABORATOR;
        for (uint256 i = 0; i < _collaborators.length; i++) {
            // Owner address cannot be null.
            address collaborator = _collaborators[i];
            require(
                collaborator != address(0) &&
                    collaborator != SENTINEL_COLLABORATOR &&
                    collaborator != address(this) &&
                    currentCollaborator != collaborator,
                "FV203"
            );
            // No duplicate collaborators allowed.
            require(collaborators[collaborator] == address(0), "FV204");
            collaborators[currentCollaborator] = collaborator;
            currentCollaborator = collaborator;
        }
        collaborators[currentCollaborator] = SENTINEL_COLLABORATOR;
        collaboratorCount = _collaborators.length;
    }

    event AddedCollaborator(address indexed to, address indexed by);

    function addCollaborator(address collaborator) public onlyOwner {
        require(
            collaborator != address(0) &&
                collaborator != SENTINEL_COLLABORATOR &&
                collaborator != address(this),
            "FV203"
        );
        // No duplicate owners allowed.
        require(collaborators[collaborator] == address(0), "FV204");
        collaborators[collaborator] = collaborators[SENTINEL_COLLABORATOR];
        collaborators[SENTINEL_COLLABORATOR] = collaborator;
        collaboratorCount++;
        emit AddedCollaborator(collaborator, _msgSender());
    }

    event RemovedCollaborator(address indexed to, address indexed by);

    function removeCollaborator(address prevCollaborator, address collaborator)
        public
        onlyOwner
    {
        // Only allow to remove an owner, if greater than one.
        require(collaboratorCount - 1 >= 1, "FV205");
        // Validate owner address and check that it corresponds to owner index.
        require(
            collaborator != address(0) && collaborator != SENTINEL_COLLABORATOR,
            "FV203"
        );
        require(collaborators[prevCollaborator] == collaborator, "FV204");
        collaborators[prevCollaborator] = collaborators[collaborator];
        collaborators[collaborator] = address(0);
        collaboratorCount--;
        emit RemovedCollaborator(collaborator, _msgSender());
    }

    function isCollaborator(address collaborator) public view returns (bool) {
        return
            collaborator != SENTINEL_COLLABORATOR &&
            collaborators[collaborator] != address(0);
    }

    function _checkRole(address account) internal view virtual {
        if (!isCollaborator(account)) {
            revert("Role Missing");
        }
    }

    modifier onlyCollaborator() {
        _checkRole(_msgSender());
        _;
    }

    function getCollaborators() public view returns (address[] memory) {
        address[] memory array = new address[](collaboratorCount);

        // populate return array
        uint256 index = 0;
        address currentCollaborator = collaborators[SENTINEL_COLLABORATOR];
        while (currentCollaborator != SENTINEL_COLLABORATOR) {
            array[index] = currentCollaborator;
            currentCollaborator = collaborators[currentCollaborator];
            index++;
        }
        return array;
    }

    function getCollaboratorCount() public view returns (uint256) {
        return collaboratorCount;
    }

    event UpdatedMetadata(string indexed ipfsHash, address indexed by);

    function updateMetadata(string memory _metadataIPFSHash) public onlyOwner {
        require(bytes(_metadataIPFSHash).length > 0, "FV206");
        metadataIPFSHash = _metadataIPFSHash;
        emit UpdatedMetadata(metadataIPFSHash, _msgSender());
    }

    event AddedFile(uint256 indexed fileId, address indexed by);

    function addFile(
        string calldata metadataIPFSHash,
        string calldata contentIPFSHash,
        string calldata gateIPFSHash,
        FileType filetype,
        uint256 version
    ) public onlyCollaborator {
        require(bytes(metadataIPFSHash).length > 0, "FV206");
        require(bytes(contentIPFSHash).length > 0, "FV206");

        uint256 fileId = _fileIdCounter.current();
        _fileIdCounter.increment();
        files[fileId] = File(
            metadataIPFSHash,
            contentIPFSHash,
            gateIPFSHash,
            filetype,
            version
        );
        emit AddedFile(fileId, _msgSender());
    }

    event EditedFile(uint256 indexed fileId, address indexed by);

    function editFile(
        uint256 fileId,
        string calldata metadataIPFSHash,
        string calldata contentIPFSHash,
        string calldata gateIPFSHash,
        FileType filetype,
        uint256 version
    ) public onlyCollaborator {
        require(bytes(metadataIPFSHash).length > 0, "FV206");
        require(bytes(contentIPFSHash).length > 0, "FV206");

        files[fileId] = File(
            metadataIPFSHash,
            contentIPFSHash,
            gateIPFSHash,
            filetype,
            version
        );
        emit EditedFile(fileId, _msgSender());
    }

    function getFileCount() public view returns (uint256) {
        return _fileIdCounter.current();
    }

    event RegisteredMember(address indexed to);

    function registerSelfFromMember(
        string calldata viewDid,
        string calldata editDid
    ) public {
        require(bytes(viewDid).length > 0, "FV201");
        require(bytes(editDid).length > 0, "FV201");
        address sender = _msgSender();
        members[sender] = Member(viewDid, editDid);
        emit RegisteredMember(_msgSender());
    }

    event RemovedMember(address indexed to);

    function removeSelfFromMember() public {
        address sender = _msgSender();
        delete members[sender];
        emit RemovedMember(_msgSender());
    }
}
