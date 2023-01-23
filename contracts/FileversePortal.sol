// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/// @custom:security-contact security@fileverse.io
contract FileversePortal is ERC2771Context, Ownable {
    using Counters for Counters.Counter;

    // ipfs hash with metadata for portal contract
    string public metadataIPFSHash;

    // constant for sentinal collaborator
    address internal constant SENTINEL_COLLABORATOR = address(0x1);

    // mapping with address to collaborator
    mapping(address => address) internal collaborators;

    // number of collaborator added to the smart contract
    uint256 internal collaboratorCount;

    // counter instance for fileId
    Counters.Counter private _fileIdCounter;

    struct KeyVerifier {
        string decryptionKeyVerifier;
        string encryptionKeyVerifier;
    }

    // mapping from version to key verifier hashes
    mapping(uint256 => KeyVerifier) public keyVerifiers;

    struct Member {
        string viewDid;
        string editDid;
    }

    // mapping from address to the member data
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

    // mapping from fileId to the file metadata
    mapping(uint256 => File) public files;

    /**
     * @notice constructor for the fileverse portal smart contract
     * @dev It gets called by the mint function of the registry with proper data
     * @param _metadataIPFSHash - The IPFS hash of the metadata file.
     * @param _ownerViewDid - owner's view DID
     * @param _ownerEditDid - owner's edit DID
     * @param owner - address of the owner which is deploying the smart contract
     * @param _trustedForwarder - instance of the trusted forwarder
     */
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

    /**
     * @notice The function adds the members as one time initialization
     * of the contract
     * @dev It gets called by the constructor and owner gets added as collaborator
     * @param account - The address of the member to be added.
     * @param viewDid - The view DID of the member that will be used to view the data.
     * @param editDid - The edit DID of the member who is allowed to edit the data.
     */
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

    /**
     * @notice The function adds the collaborators as one time initialization
     * of the contract
     * @dev It gets called by the constructor and owner gets added as collaborator
     * @param _collaborators - The list of addresses which needs to added to the
     * collaborator array.
     */
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

    /**
     * @notice The function adds a collaborator to the list of collaborators
     * @dev If the collaborator is not the smart contract address and is not
     * sentinel collaborator and the collaborator is not the zero address,
     * then add it.
     * It also emits an event AddedCollaborator with params account and by addresses
     * It can be called only by the owner of the portal
     * @param collaborator - The address of the collaborator to be added.
     */
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

    /**
     * `function removeCollaborator(address prevCollaborator, address collaborator) public onlyOwner returns (void)`
     * @notice The function removes a collaborator from the list of collaborators
     * @dev If the collaborator is not the only collaborator and is not
     * sentinel collaborator and the collaborator is not the zero address,
     * then remove it.
     * It also emits an event RemovedCollaborator with params account and by addresses
     * It can be called only by the owner of the portal
     * @param prevCollaborator - The address of the previous collaborator.
     * @param collaborator - The address of the collaborator to be removed.
     */
    function removeCollaborator(
        address prevCollaborator,
        address collaborator
    ) public onlyOwner {
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

    /**
     * @notice This is a public function to check if an account is a
     * collaborator or not
     * @dev If the collaborator is not the sentinel collaborator and
     * the next collaborator is not the zero address, then return true.
     * @param account - The address of the account
     * @return bool - if the address is in collaborator list return true else false.
     */
    function isCollaborator(address account) public view returns (bool) {
        return
            account != SENTINEL_COLLABORATOR &&
            collaborators[account] != address(0);
    }

    /**
     * `_checkRole(address account)`
     * @notice Its a function that checks if the address `account` is a
     * collaborator. If it is not, it reverts the transaction.
     * @dev This function is used by onlyCollaborator modifier
     * @param account - The address of the account to check if the ther are a
     * collaborator
     */
    function _checkRole(address account) internal view virtual {
        if (!isCollaborator(account)) {
            revert("Role Missing");
        }
    }

    /**
     * `modifier onlyCollaborator()`
     * @notice This is a modifier that is used to check if the sender is a collaborator.
     * @dev this modifier is used across the contract. If the sender is not a
     * collaborator, the transaction is reverted.
     */
    modifier onlyCollaborator() {
        _checkRole(_msgSender());
        _;
    }

    /**
     * `function getCollaborators() public view returns (address[] memory)`
     * @notice This function is returns the list of collaborator of the portal.
     * @dev This is read only function which returns a list of addresses
     * @return collaboratorList - List of addresses that are added as collaborator
     * to the portal contract
     */
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

    /**
     * `function getCollaboratorCount() public view returns (uint256)`
     * @notice This function returns the number of collaborators in the contract
     * @return collaboratorCount The number of collaborators that are added to the
     * portal contract
     */
    function getCollaboratorCount() public view returns (uint256) {
        return collaboratorCount;
    }

    event UpdatedPortalMetadata(string metadataIPFSHash, address indexed by);

    /**
     * @notice Update the metadata hash of the smart contract. This is what is we
     * use to show name and description of the portal. It requires that the input
     * string is not empty and then sets the `metadataIPFSHash` variable to the
     * input string.
     * This function can only be called by owner
     * @dev It also emits an event called `UpdatedPortalMetadata` with the
     * `metadataIPFSHash` and the `msg.sender` as parameters
     * @param _metadataIPFSHash - The IPFS hash of the portal metadata file.
     */
    function updateMetadata(string memory _metadataIPFSHash) public onlyOwner {
        require(bytes(_metadataIPFSHash).length != 0, "FV206");
        metadataIPFSHash = _metadataIPFSHash;
        emit UpdatedPortalMetadata(metadataIPFSHash, _msgSender());
    }

    event AddedFile(
        uint256 indexed fileId,
        string metadataIPFSHash,
        string contentIPFSHash,
        string gateIPFSHash,
        address indexed by
    );

    /**
     * @notice Add a file to the smart contract. It requires _metadataIPFSHash and
     * _contentIPFSHash is not empty.
     * This function can only be called by a collaborator
     * @dev An event `event AddedFile` is also emitted at the end. All the data that is
     * passed as parameters is saved in files mapping.
     * @param _metadataIPFSHash - The IPFS hash of the metadata file.
     * @param _contentIPFSHash - The IPFS hash of the file's content.
     * @param _gateIPFSHash - The IPFS hash of the gate file.
     * @param filetype - This is an enum that can be one of the following: Public / Private / Gated
     * @param version - a uint256 which tells which version of the key was used to handle the file
     */
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
        emit AddedFile(
            fileId,
            _metadataIPFSHash,
            _contentIPFSHash,
            _gateIPFSHash,
            _msgSender()
        );
    }

    event EditedFile(
        uint256 indexed fileId,
        string metadataIPFSHash,
        string contentIPFSHash,
        string gateIPFSHash,
        address indexed by
    );

    /**
     * @notice Edit a file in the smart contract.
     * This function can only be called by a collaborator
     * @dev An event `event EditedFile` is also emitted at the end. All the data that is passed as parameters
     * replaces the data in files mapping.
     * @param fileId - fileId of the file being edited. Its of the type uint256.
     * @param _metadataIPFSHash - The IPFS hash of the metadata file.
     * @param _contentIPFSHash - The IPFS hash of the file's content.
     * @param _gateIPFSHash - The IPFS hash of the gate file.
     * @param filetype - This is an enum that can be one of the following: Public / Private / Gated
     * @param version - a uint256 which tells which version of the key was used to handle the file
     */
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
        emit EditedFile(
            fileId,
            _metadataIPFSHash,
            _contentIPFSHash,
            _gateIPFSHash,
            _msgSender()
        );
    }

    /**
     * `function getFileCount() public view returns (uint256)`
     * @notice This is a public getter function which returns the current file count
     * @dev It relies on the _fileIdCounter an instance of Counters.Counter and
     * doesn't change the state of the contract
     * @return fileCount The current number of files in the smart contract.
     */
    function getFileCount() public view returns (uint256) {
        return _fileIdCounter.current();
    }

    event RegisteredMember(address indexed account);

    /**
     * @notice This function allows a member to register their DIDs with the contract.
     * This function can only be called by a collaborator
     * @dev An event `event RegisteredMember(address indexed account)` is also emitted at the end
     * @param viewDid - The DID of the member that will be used to view the data.
     * @param editDid - The DID of the member that can edit the document.
     */
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

    /**
     * `function removeSelfFromMember() public onlyCollaborator returns (void)`
     * @notice This function removes the sender from the members mapping.
     * This function can only be called by a collaborator
     * @dev It also removes the view and edit DIDs from the members mapping
     * An event `event RemovedMember(address indexed account)` is also emitted at the end
     */
    function removeSelfFromMember() public onlyCollaborator {
        address sender = _msgSender();
        delete members[sender];
        memberCount--;
        emit RemovedMember(_msgSender());
    }

    /**
     * `function getMemberCount() public view returns (uint256)`
     * @notice This is public function to get all the onborded member of the portal
     * @return memberCount The number of members in the club.
     */
    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    /**
     * `function _msgSender() internal view override(Context, ERC2771Context) returns (address sender)`
     *
     * @notice The function is named `_msgSender` and it is `internal` and `view` (i.e. it does not modify the
     * state of the contract and it does not cost gas). It `overrides` the `_msgSender` function in the
     * `Context` contract. It returns the address of the sender of the message
     * @dev This function is required to make the contract gasless and is inherited from ERC2771Context
     * @return sender the address of the message sender
     */
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    /**
     * `function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata)`
     *
     * @notice The function is named `_msgData` and it is `internal` and `view` (i.e. it does not modify the
     * state of the contract and it does not cost gas). It `overrides` the `_msgData` function in the
     * `Context` contract. It returns a `bytes calldata` value
     * @dev This function is required to make the contract gasless and is inherited from ERC2771Context
     * @return The calldata of the message.
     */
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
