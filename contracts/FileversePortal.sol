// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";


/// @custom:security-contact security@fileverse.io
contract FileversePortal is ERC2771Context, Ownable {
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
    uint256 internal memberCount;

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
        string memory _ownerEditDid,
        address owner,
        address _trustedForwarder
    ) ERC2771Context(_trustedForwarder) {
        metadataIPFSHash = _metadataIPFSHash;
        address[] memory _collaborators = new address[](1);
        _collaborators[0] = owner;
        setupCollaborators(_collaborators);
        _transferOwnership(owner);
        setupMember(owner, _ownerViewDid, _ownerEditDid);
    }

    function setupMember(
        address account,
        string memory viewDid,
        string memory editDid
    ) internal {
        require(bytes(viewDid).length != 0, "FV201");
        require(bytes(editDid).length != 0, "FV201");
        members[account] = Member(viewDid, editDid);
        memberCount = 1;
        emit RegisteredMember(account);
    }

    function setupCollaborators(address[] memory _collaborators) internal {
        // Initializing Subdomain collaborators.
        uint256 len = _collaborators.length;
        require(len != 0, "FV202");
        address currentCollaborator = SENTINEL_COLLABORATOR;
        
        for (uint256 i; i < len; ++i) {
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
        collaboratorCount = len;
    }

    event AddedCollaborator(address indexed account, address indexed by);

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

    event RemovedCollaborator(address indexed account, address indexed by);

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
        uint256 index;
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

    event UpdatedPortalMetadata(string metadataIPFSHash, address indexed by);

    function updateMetadata(string memory _metadataIPFSHash) public onlyOwner {
        require(bytes(_metadataIPFSHash).length != 0, "FV206");
        metadataIPFSHash = _metadataIPFSHash;
        emit UpdatedPortalMetadata(metadataIPFSHash, _msgSender());
    }

    event AddedFile(uint256 indexed fileId, string metadataIPFSHash, string contentIPFSHash, string gateIPFSHash, address indexed by);

    function addFile(
        string calldata _metadataIPFSHash,
        string calldata _contentIPFSHash,
        string calldata _gateIPFSHash,
        FileType filetype,
        uint256 version
    ) public onlyCollaborator {
        require(bytes(_metadataIPFSHash).length != 0, "FV206");
        require(bytes(_contentIPFSHash).length != 0, "FV206");

        uint256 fileId = _fileIdCounter.current();
        _fileIdCounter.increment();
        files[fileId] = File(
            _metadataIPFSHash,
            _contentIPFSHash,
            _gateIPFSHash,
            filetype,
            version
        );
        emit AddedFile(fileId, _metadataIPFSHash, _contentIPFSHash, _gateIPFSHash, _msgSender());
    }

    event EditedFile(uint256 indexed fileId, string metadataIPFSHash, string contentIPFSHash, string gateIPFSHash, address indexed by);

    function editFile(
        uint256 fileId,
        string calldata _metadataIPFSHash,
        string calldata _contentIPFSHash,
        string calldata _gateIPFSHash,
        FileType filetype,
        uint256 version
    ) public onlyCollaborator {
        require(bytes(_metadataIPFSHash).length != 0, "FV206");
        require(bytes(_contentIPFSHash).length != 0, "FV206");

        files[fileId] = File(
            _metadataIPFSHash,
            _contentIPFSHash,
            _gateIPFSHash,
            filetype,
            version
        );
        emit EditedFile(fileId, _metadataIPFSHash, _contentIPFSHash, _gateIPFSHash, _msgSender());
    }

    function getFileCount() public view returns (uint256) {
        return _fileIdCounter.current();
    }

    event RegisteredMember(address indexed account);

    function registerSelfToMember(
        string calldata viewDid,
        string calldata editDid
    ) public onlyCollaborator {
        require(bytes(viewDid).length != 0, "FV201");
        require(bytes(editDid).length != 0, "FV201");
        address sender = _msgSender();
        members[sender] = Member(viewDid, editDid);
        memberCount++;
        emit RegisteredMember(_msgSender());
    }

    event RemovedMember(address indexed account);

    function removeSelfFromMember() public onlyCollaborator {
        address sender = _msgSender();
        delete members[sender];
        memberCount--;
        emit RemovedMember(_msgSender());
    }

    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }    
}
