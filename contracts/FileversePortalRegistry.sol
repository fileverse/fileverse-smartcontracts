// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./FileversePortal.sol";
import "./structs/PortalKeyVerifiers.sol";

contract FileversePortalRegistry is ReentrancyGuard, ERC2771Context {
    string public constant name = "Fileverse Portal Registry";
    struct Portal {
        address portal;
        uint256 index;
        uint256 tokenId;
    }

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping of address of portal with address
    mapping(address => address) private _ownerOf;
    // Mapping from owner to list of hash
    mapping(address => mapping(uint256 => address)) private _ownedPortal;
    // Array with all token ids, used for enumeration
    address[] private _allPortal;
    // Mapping from address of portal to Portal Data
    mapping(address => Portal) private _portalInfo;
    // address of trusted forwarder
    address private immutable trustedForwarder;

    /**
     * @notice constructor for the fileverse portal registry smart contract
     * Implementation that gets deployed:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/MinimalForwarder.sol
     * @param _trustedForwarder - instance of the trusted forwarder
     */
    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        require(_trustedForwarder != address(0), "FV211");
        trustedForwarder = _trustedForwarder;
    }

    /**
     * @notice get function that returns the owner address of the portal
     * @param _portal - The address of the portal
     * @return owner - The address of the owner
     */
    function ownerOf(address _portal) public view returns (address) {
        return _ownerOf[_portal];
    }

    event Mint(address indexed account, address indexed portal);

    /**
     * @notice Create a new FileversePortal contract and assign it to the owner
     * who calls this function
     * @dev This function also emits a Mint event
     * @param _metadataIPFSHash - The IPFS hash of the metadata file.
     * @param _ownerViewDid - owner's view DID
     * @param _ownerEditDid - owner's edit DID
     * @param _portalEncryptionKeyVerifier - sha256 hash of Portal Encryption Key
     * @param _portalDecryptionKeyVerifier - sha256 hash of Portal Decryption Key
     * @param _memberEncryptionKeyVerifier - sha256 hash of Member Encryption Key
     * @param _memberDecryptionKeyVerifier - sha256 hash of Member Decryption Key
     */
    function mint(
        string calldata _metadataIPFSHash,
        string calldata _ownerViewDid,
        string calldata _ownerEditDid,
        bytes32 _portalEncryptionKeyVerifier,
        bytes32 _portalDecryptionKeyVerifier,
        bytes32 _memberEncryptionKeyVerifier,
        bytes32 _memberDecryptionKeyVerifier
    ) external nonReentrant {
        address owner = _msgSender();
        PortalKeyVerifiers.KeyVerifier memory verifier = PortalKeyVerifiers
            .KeyVerifier(
                _portalEncryptionKeyVerifier,
                _portalDecryptionKeyVerifier,
                _memberEncryptionKeyVerifier,
                _memberDecryptionKeyVerifier
            );
        address _portal = address(
            new FileversePortal(
                _metadataIPFSHash,
                _ownerViewDid,
                _ownerEditDid,
                owner,
                trustedForwarder,
                verifier
            )
        );
        _mint(owner, _portal);
        emit Mint(owner, _portal);
    }

    /**
     * @notice A private function that is called by the public function `mint`.
     * It is used to create a new portal and assign it to the owner of the
     * contract.
     * @param _owner - The address of the owner
     * @param _portal - The address of the portal
     */
    function _mint(address _owner, address _portal) private {
        require(_ownerOf[_portal] == address(0), "FV200");
        uint256 length = _balances[_owner];
        uint256 _allPortalLength = _allPortal.length;
        _ownerOf[_portal] = _owner;
        _allPortal.push(_portal);
        _ownedPortal[_owner][length] = _portal;
        _portalInfo[_portal] = Portal(_portal, length, _allPortalLength);
        ++length;
        _balances[_owner] = length;
    }

    /**
     * @notice `portalInfo` returns the `Portal` struct for a given portal address
     * @param _portal - The address of the portal
     * @return portalInfo The Portal memory struct.
     */
    function portalInfo(address _portal) external view returns (Portal memory) {
        return _portalInfo[_portal];
    }

    /**
     * @notice This function returns an array of all the portals in the registry.
     * @param _resultsPerPage results per page
     * @param _page current page
     * @return portals The array of Portal memory struct with all the portals
     */
    function allPortal(uint256 _resultsPerPage, uint256 _page)
        external
        view
        returns (Portal[] memory)
    {
        uint256 len = _allPortal.length;
        uint256 startIndex = _resultsPerPage * _page - _resultsPerPage;
        uint256 endIndex = Math.min(_resultsPerPage * _page, len);
        require(startIndex <= len, "FV212");
        Portal[] memory results = new Portal[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; ++i) {
            if(i > len) {
                break;
            }
            results[i] = _portalInfo[_allPortal[i]];
        }
        return results;
    }

    /**
     * @notice Returning the number of portals owned by the address _owner
     * @param _owner address of the owner who's balance if being queried
     * @return balance The array of Portal memory struct with all the portals
     */
    function balancesOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @notice Returning a list of portals that are owned by the address _owner
     * @param _owner address of the owner who's balance if being queried
     * @param _resultsPerPage results per page
     * @param _page current page
     * @return portals The array of Portal memory struct owned by the address _owner
     */
    function ownedPortal(
        address _owner,
        uint256 _resultsPerPage,
        uint256 _page
    ) external view returns (Portal[] memory) {
        uint256 len = balancesOf(_owner);
        uint256 startIndex = _resultsPerPage * _page - _resultsPerPage;
        require(startIndex <= len, "FV212");
        uint256 endIndex = Math.min(_resultsPerPage * _page, len);
        Portal[] memory results = new Portal[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; ++i) {
            if(i > len) {
                break;
            }
            results[i] = _portalInfo[_ownedPortal[_owner][i]];
        }
        return results;
    }
}
