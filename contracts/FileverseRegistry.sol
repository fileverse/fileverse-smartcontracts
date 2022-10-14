// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./FileverseSubdomain.sol";

contract FileverseRegistry is ReentrancyGuard {
    string public name = "Fileverse Registry";
    struct Subdomain {
        address subdomain;
        uint256 index;
    }
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping of address of subdomain with address
    mapping(address => address) private _ownerOf;
    // Mapping from owner to list of hash
    mapping(address => mapping(uint256 => address)) private _ownedSubdomain;
    // Array with all token ids, used for enumeration
    address[] private _allSubdomain;
    // Mapping from FNS to position in the allFNS array
    mapping(address => uint256) private _allSubdomainIndex;

    mapping(address => Subdomain) private _subdomainInfo;

    constructor() {}

    function ownerOf(address _subdomain) public view returns (address) {
        return _ownerOf[_subdomain];
    }

    function mint(
        string calldata _metadataIPFSHash,
        string calldata _ownerViewDid,
        string calldata _ownerEditDid
    ) external nonReentrant {
        address _subdomain = address(
            new FileverseSubdomain(
                _metadataIPFSHash,
                _ownerViewDid,
                _ownerEditDid
            )
        );
        _mint(msg.sender, _subdomain);
    }

    function _mint(address _owner, address _subdomain) internal {
        require(_ownerOf[_subdomain] == address(0), "FV200");
        uint256 length = _balances[_owner];
        ++length;
        uint256 _allSubdomainLength = _allSubdomain.length;
        _ownerOf[_subdomain] = _owner;
        _allSubdomain.push(_subdomain);
        _ownedSubdomain[_owner][length] = _subdomain;
        _allSubdomainIndex[_subdomain] = ++_allSubdomainLength;
        _subdomainInfo[_subdomain] = Subdomain(_subdomain, length);
        _balances[_owner] = length;
    }

    function subdomainInfo(address _subdomain)
        external
        view
        returns (Subdomain memory)
    {
        return _subdomainInfo[_subdomain];
    }

    function allSubdomain() external view returns (Subdomain[] memory) {
        uint256 len = _allSubdomain.length;
        Subdomain[] memory viewFns = new Subdomain[](len);
        for (uint256 i; i < len; ++i) {
            viewFns[i] = _subdomainInfo[_allSubdomain[i]];
        }
        return viewFns;
    }

    function balancesOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function ownedSubdomain(address _owner)
        external
        view
        returns (Subdomain[] memory)
    {
        uint256 len = balancesOf(_owner);
        Subdomain[] memory subdomain = new Subdomain[](len);
        for (uint256 i; i < len; ++i) {
            subdomain[i] = _subdomainInfo[_ownedSubdomain[_owner][i]];
        }
        return subdomain;
    }
}
