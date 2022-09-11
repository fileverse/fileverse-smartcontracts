// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact security@fileverse.io
contract FileverseSubdomain is Ownable {
    using Counters for Counters.Counter;

    string public name;

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
        address account;
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

    constructor(string memory _name) {
        name = _name;
        address[] memory _collaborators = new address[](1);
        _collaborators[0] = _msgSender();
        setupCollaborators(_collaborators);
    }

    function setupCollaborators(address[] memory _collaborators) internal {
        // Initializing Subdomain collaborators.
        address currentCollaborator = SENTINEL_COLLABORATOR;
        for (uint256 i = 0; i < _collaborators.length; i++) {
            // Owner address cannot be null.
            address collaborator = _collaborators[i];
            require(collaborator != address(0) && collaborator != SENTINEL_COLLABORATOR && collaborator != address(this) && currentCollaborator != collaborator, "Cannot be sentinal");
            // No duplicate collaborators allowed.
            require(collaborators[collaborator] == address(0), "No Duplicates");
            collaborators[currentCollaborator] = collaborator;
            currentCollaborator = collaborator;
        }
        collaborators[currentCollaborator] = SENTINEL_COLLABORATOR;
        collaboratorCount = _collaborators.length;
    }

    event AddedCollaborator(address indexed to, address indexed by);

    function addCollaborator(address collaborator) public onlyOwner {
        require(collaborator != address(0) && collaborator != SENTINEL_COLLABORATOR && collaborator != address(this), "Cannot be sentinal");
        // No duplicate owners allowed.
        require(collaborators[collaborator] == address(0), "GS204");
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
        require(collaboratorCount - 1 >= 1, "Should have atleast greater than one owner");
        // Validate owner address and check that it corresponds to owner index.
        require(collaborator != address(0) && collaborator != SENTINEL_COLLABORATOR, "Cannot be sentinal");
        require(collaborators[prevCollaborator] == collaborator, "GS205");
        collaborators[prevCollaborator] = collaborators[collaborator];
        collaborators[collaborator] = address(0);
        collaboratorCount--;
        emit RemovedCollaborator(collaborator, _msgSender());
    }

    function isCollaborator(address collaborator) public view returns (bool) {
        return collaborator != SENTINEL_COLLABORATOR && collaborators[collaborator] != address(0);
    }

    function _checkRole(address account) internal view virtual {
        if (!isCollaborator(account)) {
            revert(
                "Role Missing"
            );
        }
    }

    modifier onlyCollaborator()  {
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


    event AddedFile(uint256 indexed fileId, address indexed by);

    function addFile(
        string calldata metadataIPFSHash,
        string calldata contentIPFSHash,
        string calldata gateIPFSHash,
        FileType filetype,
        uint256 version
    ) public onlyCollaborator {
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
        address sender = _msgSender();
        members[sender] = Member(sender, viewDid, editDid);
        emit RegisteredMember(_msgSender());
    }

    event RemovedMember(address indexed to);

    function removeSelfFromMember() public {
        address sender = _msgSender();
        delete members[sender];
        emit RemovedMember(_msgSender());
    }
}
