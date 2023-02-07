//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@opengsn/contracts/src/BasePaymaster.sol";

import {IFileversePortalRegistry, Portal} from "./IFileversePortalRegistry.sol";

contract FileversePaymaster is BasePaymaster {
    IFileversePortalRegistry immutable registry;

    constructor(address _registry) {
        registry = IFileversePortalRegistry(_registry);
    }

    function versionPaymaster()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "3.0.0-beta.3+opengsn.whitelist.ipaymaster";
    }

    function _preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
        internal
        virtual
        override
        returns (bytes memory context, bool revertOnRecipientRevert)
    {
        (signature, maxPossibleGas);
        require(approvalData.length == 0, "approvalData: invalid length");
        require(
            relayRequest.relayData.paymasterData.length == 0,
            "paymasterData: invalid length"
        );
        Portal memory portalData = registry.portalInfo(relayRequest.request.to);
        require(portalData.portal != address(0), "FV210");
        return ("", true);
    }

    function _postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) internal virtual override {
        (context, success, gasUseWithoutPost, relayData);
    }
}
