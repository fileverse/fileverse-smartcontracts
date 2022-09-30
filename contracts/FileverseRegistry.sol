// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ValidateString.sol";
import "./FileverseSubdomain.sol";

contract FileverseRegistry is ReentrancyGuard, ValidateString {
    string public name = "Fileverse Registry";
    struct Subdomain {
        string name;
        address subdomain;
        bool isEnabled;
        uint256 index;
    }
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping of bytes32 with address
    mapping(bytes32 => address) private _ownerOf;
    // Mapping from owner to list of hash
    mapping(address => mapping(uint256 => bytes32)) private _ownedFNS;
    // Array with all token ids, used for enumeration
    bytes32[] private _allFNS;
    // Mapping from FNS to position in the allFNS array
    mapping(bytes32 => uint256) private _allFNSIndex;

    mapping(bytes32 => Subdomain) private _subdomainInfo;

    constructor() {}

    function ownerOf(string calldata _name) public view returns (address) {
        return _ownerOf[keccak256(abi.encodePacked(_name))];
    }

    function mint(
        string calldata _name,
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
        _mint(_name, msg.sender, _subdomain);
    }

    function _mint(
        string calldata _name,
        address _to,
        address _subdomain
    ) internal {
        require(validateName(_name), "FileverseRegistry: name is not valid");
        bytes32 fns = keccak256(abi.encodePacked(_name));
        require(
            _ownerOf[fns] == address(0),
            "FileverseRegistry: FNS name still exist"
        );
        uint256 length = balancesOf(_to) + 1;
        _ownerOf[fns] = _to;
        _allFNS.push(fns);
        _ownedFNS[_to][length] = fns;
        _allFNSIndex[fns] = _allFNS.length;
        _subdomainInfo[fns] = Subdomain(_name, _subdomain, true, length);
        _balances[_to] = length;
        emit NameChange(_name, msg.sender);
    }

    function changeENS(string calldata _oldname, string calldata _name)
        external
        nonReentrant
    {
        require(validateName(_name), "FileverseRegistry: name is not valid");
        bytes32 oldNameFns = keccak256(abi.encodePacked(_oldname));
        bytes32 fns = keccak256(abi.encodePacked(_name));
        uint256 _fnsIndex = _allFNSIndex[fns];
        require(
            _ownerOf[oldNameFns] == msg.sender,
            "FileverseRegistry: sender is not owner of fns"
        );
        require(
            _ownerOf[fns] == address(0),
            "FileverseRegistry: FNS name still exist"
        );
        _ownerOf[oldNameFns] = address(0);
        _ownerOf[fns] = msg.sender;
        _allFNS[_fnsIndex] = fns;
        Subdomain memory oldSubdomain = _subdomainInfo[oldNameFns];
        _subdomainInfo[fns] = Subdomain(
            _name,
            oldSubdomain.subdomain,
            true,
            oldSubdomain.index
        );
        _ownedFNS[msg.sender][oldSubdomain.index] = fns;
        delete _subdomainInfo[oldNameFns];
        emit NameChange(_name, msg.sender);
    }

    function subdomainInfo(string calldata _name)
        external
        view
        returns (Subdomain memory)
    {
        require(validateName(_name), "FileverseRegistry: name is not valid");
        return _subdomainInfo[keccak256(abi.encodePacked(_name))];
    }

    function allFNS() external view returns (Subdomain[] memory) {
        Subdomain[] memory viewFns = new Subdomain[](_allFNS.length);
        for (uint256 i = 0; i < _allFNS.length; i++) {
            viewFns[i] = _subdomainInfo[_allFNS[i]];
        }
        return viewFns;
    }

    function balancesOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function ownedFNS(address _owner)
        external
        view
        returns (Subdomain[] memory)
    {
        Subdomain[] memory subdomain = new Subdomain[](balancesOf(_owner));
        for (uint256 i = 0; i < subdomain.length; i++) {
            subdomain[i] = _subdomainInfo[_ownedFNS[_owner][i]];
        }
        return subdomain;
    }
}
