// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Schema record stored in registry
struct SchemaRecord {
    bytes32 uid;
    address resolver;
    bool revocable;
    string schema;
}

/// @title ISchemaRegistry
/// @notice Interface for EAS Schema Registry
interface ISchemaRegistry {
    /// @notice Register a new schema
    /// @param schema The schema string (e.g., "string name,uint256 age")
    /// @param resolver Optional resolver contract address
    /// @param revocable Whether attestations using this schema can be revoked
    /// @return The UID of the registered schema
    function register(string calldata schema, address resolver, bool revocable) external returns (bytes32);

    /// @notice Get a schema record by UID
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
}
