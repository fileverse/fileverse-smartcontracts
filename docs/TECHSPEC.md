# Technical Specification Summary

There are two contracts in the repo:
* Fileverse Portal Registry Contract
* Fileverse Portal Contract

## Fileverse Portal Registry Contract

This contract is the first contract that the user interacts with. We have added ERC2771Context to this for gasless support using openzepplin defender and meta txns 

Admin deploys this contract only once. 

Any user that wants to create a portal calls the mint function to create a portal. It also sets the trusted forwarder for the portal contract.
After the mint is successful `Mint(owner, _portal);` event is emitted. 

Each portal that gets deployed has a tokenId which is the global index of the portal in the registry.

Once the portal is deployed no special access is given to the Registry and Registry is used as a read only directory for deployed portals.

There are following get functions in the contract to get the details related to deployed portal by registry:
- ownerOf(address _portal)
- portalInfo(address _portal)
- allPortal()
- balancesOf(address _owner)
- ownedPortal(address _owner)

## Fileverse Portal Contract

This contract is the portal contract that gets deployed by the registry contract. We have added ERC2771Context to this for gasless support using openzepplin defender and meta txns.

Registry deploys the contract. Users that want to manage their portal on other chains can also self deploy the contract by passing in proper values.

There are total of file entities in the contract:
- Collaborators
- Members
- Files
- Portal Metadata
- Key Verifiers

### Collaborators

The portal contract has collaborators. These are users that are allowed to interact with files in the contract.

We store the collaborators as a circular linked list and is inspired by the safe contracts way of managing owners.

### Members
The portal contract has members. These are users that put their edit and view DIDs in the contract.
- viewDID: ED25519 key 
- editDID: ED25519 key 

### Key Verifiers

The portal contract has key verifiers. These are sha256 hash of the portal and member keys.
Getter Functions dealing with this:
- keyVerifiers(uint256 version)
Setter Functions dealing with this:
- function updateKeyVerifiers(bytes32, bytes32, bytes32, bytes32)
    - An event is emitted to update the clients
    - event UpdatedKeyVerifiers(bytes32, bytes32, bytes32, bytes32);

### Files

The portal contract has files. 

A file in portal has five components that are generated client side:
- Metadata - metadataIPFSHash
    - Is JSON
- Content - contentIPFSHash
- Gate - gateIPFSHash
    - Is JSON
    - IPFS Hash with json in the following format:
    - { gateId: “”, params: [“erc721:<address>”] }
- File Type - filetype
    - Its an Enum - PUBLIC / PRIVATE / GATED / MEMBER_PRIVATE
    - Determines how the file will be stored and which key material will be used to encrypt the file.
- Key Verifier Version - version 
    - which version of key was used to encrypt the file content
Getter Functions dealing with this:
- [Anyone] files(uint256 fileId)
    - Returns the full file object with proper data
Setter Functions dealing with this:
- [Only Collaborator] function addFile(string calldata _metadataIPFSHash,string calldata _contentIPFSHash,string calldata _gateIPFSHash,FileType filetype,uint256 version)
    - An event is emitted to update the clients
    - event CreatedFile
- [Only Collaborator] function editFile(uint256 fileId, string calldata _metadataIPFSHash,string calldata _contentIPFSHash,string calldata _gateIPFSHash,FileType filetype,uint256 version)
    - An event is emitted to update the clients
    - event EditedFile

### Portal Metadata

The portal contract has metadata. It's the IPFS hash with some json in a format as follows.

{
  name: “”,
  description: “”,
  logo: “”,
  cover: “”,
  // Can be extended later on since its off chain
}

Getter Functions dealing with this:
- [Anyone] metadataIPFSHash
Setter Functions dealing with this:
- [Only Owner] function updateMetadata(string memory _metadataIPFSHash)
    - An event is emitted to update the clients
    - event UpdatedPortalMetadata(string metadataIPFSHash, address indexed by);
