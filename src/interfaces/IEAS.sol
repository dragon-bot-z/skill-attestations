// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Attestation request data
struct AttestationRequestData {
    address recipient;
    uint64 expirationTime;
    bool revocable;
    bytes32 refUID;
    bytes data;
    uint256 value;
}

/// @notice Full attestation request
struct AttestationRequest {
    bytes32 schema;
    AttestationRequestData data;
}

/// @notice Attestation data returned from EAS
struct Attestation {
    bytes32 uid;
    bytes32 schema;
    uint64 time;
    uint64 expirationTime;
    uint64 revocationTime;
    bytes32 refUID;
    address recipient;
    address attester;
    bool revocable;
    bytes data;
}

/// @notice Revocation request data
struct RevocationRequestData {
    bytes32 uid;
    uint256 value;
}

/// @notice Full revocation request
struct RevocationRequest {
    bytes32 schema;
    RevocationRequestData data;
}

/// @title IEAS
/// @notice Interface for the Ethereum Attestation Service
interface IEAS {
    /// @notice Create a new attestation
    function attest(AttestationRequest calldata request) external payable returns (bytes32);

    /// @notice Revoke an attestation
    function revoke(RevocationRequest calldata request) external payable;

    /// @notice Get an attestation by UID
    function getAttestation(bytes32 uid) external view returns (Attestation memory);

    /// @notice Check if attestation is valid (exists and not revoked)
    function isAttestationValid(bytes32 uid) external view returns (bool);
}
