// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library PortalKeyVerifiers {
    struct KeyVerifier {
        bytes32 portalEncryptionKeyVerifier;
        bytes32 portalDecryptionKeyVerifier;
        bytes32 memberEncryptionKeyVerifier;
        bytes32 memberDecryptionKeyVerifier;
    }
}
