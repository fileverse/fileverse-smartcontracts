// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct Portal {
    address portal;
    uint256 index;
    uint256 tokenId;
}

interface IFileversePortalRegistry {
    function portalInfo(address _portal) external view returns (Portal memory);
}
