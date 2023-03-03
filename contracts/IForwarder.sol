// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title The Forwarder Interface
 * @notice The contracts implementing this interface take a role of authorization, authentication and replay protection
 * for contracts that choose to trust a `Forwarder`, instead of relying on a mechanism built into the Ethereum protocol.
 *
 * @notice if the `Forwarder` contract decides that an incoming `ForwardRequest` is valid, it must append 20 bytes that
 * represent the caller to the `data` field of the request and send this new data to the target address (the `to` field)
 *
 * :warning: **Warning** :warning: The Forwarder can have a full control over a `Recipient` contract.
 * Any vulnerability in a `Forwarder` implementation can make all of its `Recipient` contracts susceptible!
 * Recipient contracts should only trust forwarders that passed through security audit,
 * otherwise they are susceptible to identity theft.
 */
interface IForwarder is IERC165 {
    /**
     * @notice A representation of a request for a `Forwarder` to send `data` on behalf of a `from` to a target (`to`).
     */
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntilTime;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    /**
     * @param from The address of a sender.
     * @return The nonce for this address.
     */
    function getNonce(address from) external view returns (uint256);

    /**
     * @notice Verify the transaction is valid and can be executed.
     * Implementations must validate the signature and the nonce of the request are correct.
     * Does not revert and returns successfully if the input is valid.
     * Reverts if any validation has failed. For instance, if either signature or nonce are incorrect.
     * Reverts if `domainSeparator` or `requestTypeHash` are not registered as well.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes calldata signature
    ) external view;

    /**
     * @notice Executes a transaction specified by the `ForwardRequest`.
     * The transaction is first verified and then executed.
     * The success flag and returned bytes array of the `CALL` are returned as-is.
     *
     * This method would revert only in case of a verification error.
     *
     * All the target errors are reported using the returned success flag and returned bytes array.
     *
     * @param forwardRequest All requested transaction parameters.
     * @param signature The client signature to be validated.
     *
     * @return success The success flag of the underlying `CALL` to the target address.
     * @return ret The byte array returned by the underlying `CALL` to the target address.
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes calldata signature
    ) external payable returns (bool success, bytes memory ret);
}
