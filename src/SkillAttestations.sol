// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IEAS, AttestationRequest, AttestationRequestData} from "./interfaces/IEAS.sol";
import {ISchemaRegistry, SchemaRecord} from "./interfaces/ISchemaRegistry.sol";

/// @title SkillAttestations
/// @author Dragon Bot Z 🐉
/// @notice EAS-based skill attestation registry for AI agent skills
/// @dev Creates attestations for skill safety, audits, and permissions on Base
contract SkillAttestations {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Skill attestation data
    struct SkillData {
        bytes32 skillHash;      // IPFS CID as bytes32 (keccak256 of CID)
        string skillName;       // Human-readable name
        string skillUrl;        // Repository URL
        string version;         // Version string
        uint8 rating;           // 1-5 rating
        bool safe;              // Is skill safe?
        string findings;        // Audit findings summary
        string permissions;     // Required permissions
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice EAS contract on Base
    IEAS public constant EAS = IEAS(0x4200000000000000000000000000000000000021);
    
    /// @notice Schema Registry on Base
    ISchemaRegistry public constant SCHEMA_REGISTRY = ISchemaRegistry(0x4200000000000000000000000000000000000020);

    /// @notice Schema string for skill attestations
    string public constant SKILL_SCHEMA = 
        "bytes32 skillHash,string skillName,string skillUrl,string version,uint8 rating,bool safe,string findings,string permissions";

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Schema UID (set on deployment)
    bytes32 public schemaUID;

    /// @notice Contract owner
    address public owner;

    /// @notice Registered auditors
    mapping(address => bool) public auditors;

    /// @notice Auditor stake amounts
    mapping(address => uint256) public auditorStakes;

    /// @notice Minimum stake to become auditor
    uint256 public constant MIN_STAKE = 0.01 ether;

    /// @notice Attestation UIDs per skill
    mapping(bytes32 => bytes32[]) public skillAttestations;

    /// @notice Attestation count per auditor
    mapping(address => uint256) public auditorAttestationCount;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event SchemaRegistered(bytes32 indexed schemaUID);
    event AuditorRegistered(address indexed auditor, uint256 stake);
    event AuditorRemoved(address indexed auditor);
    event SkillAttested(bytes32 indexed skillHash, bytes32 indexed attestationUID, address indexed auditor);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOwner();
    error NotAuditor();
    error InsufficientStake();
    error InvalidRating();
    error SchemaAlreadyRegistered();
    error TransferFailed();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        auditors[msg.sender] = true;
    }

    /*//////////////////////////////////////////////////////////////
                            SCHEMA REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Register the skill attestation schema on EAS
    function registerSchema() external returns (bytes32 uid) {
        if (schemaUID != bytes32(0)) revert SchemaAlreadyRegistered();
        
        uid = SCHEMA_REGISTRY.register(SKILL_SCHEMA, address(0), true);
        schemaUID = uid;
        
        emit SchemaRegistered(uid);
    }

    /*//////////////////////////////////////////////////////////////
                            AUDITOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Register as auditor with stake
    function registerAuditor() external payable {
        if (msg.value < MIN_STAKE) revert InsufficientStake();
        
        auditors[msg.sender] = true;
        auditorStakes[msg.sender] += msg.value;
        
        emit AuditorRegistered(msg.sender, msg.value);
    }

    /// @notice Remove auditor and return stake (owner only)
    function removeAuditor(address auditor) external {
        if (msg.sender != owner) revert NotOwner();
        
        uint256 stake = auditorStakes[auditor];
        auditors[auditor] = false;
        auditorStakes[auditor] = 0;
        
        if (stake > 0) {
            (bool ok, ) = auditor.call{value: stake}("");
            if (!ok) revert TransferFailed();
        }
        
        emit AuditorRemoved(auditor);
    }

    /*//////////////////////////////////////////////////////////////
                              ATTESTATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Attest to a skill's safety and quality
    /// @param skill Skill data struct
    /// @return attestationUID The UID of the created attestation
    function attestSkill(SkillData calldata skill) external returns (bytes32 attestationUID) {
        if (!auditors[msg.sender]) revert NotAuditor();
        if (skill.rating < 1 || skill.rating > 5) revert InvalidRating();

        // Encode attestation data
        bytes memory data = abi.encode(
            skill.skillHash,
            skill.skillName,
            skill.skillUrl,
            skill.version,
            skill.rating,
            skill.safe,
            skill.findings,
            skill.permissions
        );

        // Create attestation via EAS
        attestationUID = EAS.attest(
            AttestationRequest({
                schema: schemaUID,
                data: AttestationRequestData({
                    recipient: address(0),
                    expirationTime: 0,
                    revocable: true,
                    refUID: bytes32(0),
                    data: data,
                    value: 0
                })
            })
        );
        
        // Track attestation
        skillAttestations[skill.skillHash].push(attestationUID);
        unchecked { auditorAttestationCount[msg.sender]++; }
        
        emit SkillAttested(skill.skillHash, attestationUID, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get all attestation UIDs for a skill
    function getSkillAttestations(bytes32 skillHash) external view returns (bytes32[] memory) {
        return skillAttestations[skillHash];
    }

    /// @notice Get attestation count for a skill
    function getAttestationCount(bytes32 skillHash) external view returns (uint256) {
        return skillAttestations[skillHash].length;
    }

    /// @notice Check if address is registered auditor
    function isAuditor(address account) external view returns (bool) {
        return auditors[account];
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer ownership
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
