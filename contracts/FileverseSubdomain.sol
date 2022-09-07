// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact security@fileverse.io
contract FileverseSubdomain is AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _fileIdCounter;
    bytes32 public constant COLLAB_ROLE = keccak256("COLLAB_ROLE");

    struct KeyVerifier {
        string decryptionKeyVerifier;
        string encryptionKeyVerifier;
    }

    mapping(uint256 => KeyVerifier) public keyVerifiers;

    struct Member {
        address to;
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

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(COLLAB_ROLE, msg.sender);
    }

    event AddedCollaborator(address indexed to, address indexed by);

    function addCollaborator(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(COLLAB_ROLE, to);
        emit AddedCollaborator(to, msg.sender);
    }

    event RemovedCollaborator(address indexed to, address indexed by);

    function removeCollaborator(address to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(COLLAB_ROLE, to);
        emit RemovedCollaborator(to, msg.sender);
    }

    event AddedFile(uint256 indexed fileId, address indexed by);

    function addFile(
        string calldata metadataIPFSHash,
        string calldata contentIPFSHash,
        string calldata gateIPFSHash,
        FileType filetype,
        uint256 version
    ) public onlyRole(COLLAB_ROLE) {
        uint256 fileId = _fileIdCounter.current();
        _fileIdCounter.increment();
        files[fileId] = File(
            metadataIPFSHash,
            contentIPFSHash,
            gateIPFSHash,
            filetype,
            version
        );
        emit AddedFile(fileId, msg.sender);
    }

    event EditedFile(uint256 indexed fileId, address indexed by);

    function editFile(
        uint256 fileId,
        string calldata metadataIPFSHash,
        string calldata contentIPFSHash,
        string calldata gateIPFSHash,
        FileType filetype,
        uint256 version
    ) public onlyRole(COLLAB_ROLE) {
        files[fileId] = File(
            metadataIPFSHash,
            contentIPFSHash,
            gateIPFSHash,
            filetype,
            version
        );
        emit EditedFile(fileId, msg.sender);
    }

    event RegisteredMember(address indexed to);

    function registerSelfFromMember(
        string calldata viewDid,
        string calldata editDid
    ) public {
        address sender = msg.sender;
        members[sender] = Member(sender, viewDid, editDid);
        emit RegisteredMember(msg.sender);
    }

    event RemovedMember(address indexed to);

    function removeSelfFromMember() public {
        address sender = msg.sender;
        delete members[sender];
        emit RemovedMember(msg.sender);
    }
}
