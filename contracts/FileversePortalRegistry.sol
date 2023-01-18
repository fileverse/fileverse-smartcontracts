// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./FileversePortal.sol";

contract FileversePortalRegistry is ReentrancyGuard, ERC2771Context {
    string public name = "Fileverse Portal Registry";
    struct Portal {
        address portal;
        uint256 index;
    }
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping of address of portal with address
    mapping(address => address) private _ownerOf;
    // Mapping from owner to list of hash
    mapping(address => mapping(uint256 => address)) private _ownedPortal;
    // Array with all token ids, used for enumeration
    address[] private _allPortal;
    // Mapping from FNS to position in the allFNS array
    mapping(address => uint256) private _allPortalIndex;

    mapping(address => Portal) private _portalInfo;

    address private immutable trustedForwarder;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    // Returns owner of portal
    function ownerOf(address _portal) public view returns (address) {
        return _ownerOf[_portal];
    }

    function mint(
        string calldata _metadataIPFSHash,
        string calldata _ownerViewDid,
        string calldata _ownerEditDid
    ) external nonReentrant {
        address owner = _msgSender();
        address _portal = address(
            new FileversePortal(
                _metadataIPFSHash,
                _ownerViewDid,
                _ownerEditDid,
                owner,
                trustedForwarder
            )
        );
        _mint(owner, _portal);
    }

    function _mint(address _owner, address _portal) internal {
        require(_ownerOf[_portal] == address(0), "FV200");
        uint256 length = _balances[_owner];
        ++length;
        uint256 _allPortalLength = _allPortal.length;
        _ownerOf[_portal] = _owner;
        _allPortal.push(_portal);
        _ownedPortal[_owner][length] = _portal;
        _allPortalIndex[_portal] = ++_allPortalLength;
        _portalInfo[_portal] = Portal(_portal, length);
        _balances[_owner] = length;
    }

    // Returns data for portal on address _portal 
    function portalInfo(address _portal)
        external
        view
        returns (Portal memory)
    {
        return _portalInfo[_portal];
    }

    // Returns all the portals in registry
    function allPortal() external view returns (Portal[] memory) {
        uint256 len = _allPortal.length;
        Portal[] memory viewFns = new Portal[](len);
        for (uint256 i; i < len; ++i) {
            viewFns[i] = _portalInfo[_allPortal[i]];
        }
        return viewFns;
    }

    // Returns number of portal owned by the address _owner
    function balancesOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    // Returns a list of portal that are owned by the address _owner
    function ownedPortal(address _owner)
        external
        view
        returns (Portal[] memory)
    {
        uint256 len = balancesOf(_owner);
        Portal[] memory portal = new Portal[](len);
        for (uint256 i; i < len; ++i) {
            portal[i] = _portalInfo[_ownedPortal[_owner][i]];
        }
        return portal;
    }
}
