// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library PortalKeyVerifiers {
    struct KeyVerifier {
        string portalEncryptionKeyVerifier;
        string portalDecryptionKeyVerifier;
        string memberEncryptionKeyVerifier;
        string memberDecryptionKeyVerifier;
    }
}
