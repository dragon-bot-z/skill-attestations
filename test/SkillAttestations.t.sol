// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {SkillAttestations} from "../src/SkillAttestations.sol";
import {IEAS, AttestationRequest, AttestationRequestData, Attestation, RevocationRequest} from "../src/interfaces/IEAS.sol";
import {ISchemaRegistry, SchemaRecord} from "../src/interfaces/ISchemaRegistry.sol";

/// @notice Mock EAS for testing
contract MockEAS is IEAS {
    uint256 private _attestationCounter;
    mapping(bytes32 => Attestation) private _attestations;
    
    function attest(AttestationRequest calldata request) external payable returns (bytes32) {
        _attestationCounter++;
        bytes32 uid = keccak256(abi.encodePacked(_attestationCounter, block.timestamp));
        
        _attestations[uid] = Attestation({
            uid: uid,
            schema: request.schema,
            time: uint64(block.timestamp),
            expirationTime: request.data.expirationTime,
            revocationTime: 0,
            refUID: request.data.refUID,
            recipient: request.data.recipient,
            attester: msg.sender,
            revocable: request.data.revocable,
            data: request.data.data
        });
        
        return uid;
    }
    
    function revoke(RevocationRequest calldata) external payable {}
    
    function getAttestation(bytes32 uid) external view returns (Attestation memory) {
        return _attestations[uid];
    }
    
    function isAttestationValid(bytes32 uid) external view returns (bool) {
        return _attestations[uid].uid != bytes32(0);
    }
}

/// @notice Mock Schema Registry for testing
contract MockSchemaRegistry is ISchemaRegistry {
    uint256 private _schemaCounter;
    mapping(bytes32 => SchemaRecord) private _schemas;
    
    function register(
        string calldata schema,
        address resolver,
        bool revocable
    ) external returns (bytes32) {
        _schemaCounter++;
        bytes32 uid = keccak256(abi.encodePacked(_schemaCounter, schema));
        
        _schemas[uid] = SchemaRecord({
            uid: uid,
            resolver: resolver,
            revocable: revocable,
            schema: schema
        });
        
        return uid;
    }
    
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory) {
        return _schemas[uid];
    }
}

/// @notice Test harness that allows us to set mock contracts
contract TestableSkillAttestations is SkillAttestations {
    IEAS private _mockEAS;
    ISchemaRegistry private _mockRegistry;
    
    constructor(IEAS mockEAS_, ISchemaRegistry mockRegistry_) {
        _mockEAS = mockEAS_;
        _mockRegistry = mockRegistry_;
    }
    
    // Override to use mocks (unfortunately we can't override constants, so we need a different approach)
}

contract SkillAttestationsTest is Test {
    SkillAttestations public attestations;
    MockEAS public mockEAS;
    MockSchemaRegistry public mockRegistry;
    
    address public owner = address(1);
    address public auditor = address(2);
    address public randomUser = address(3);
    
    function setUp() public {
        vm.prank(owner);
        attestations = new SkillAttestations();
    }
    
    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    
    function test_Constructor_SetsOwner() public view {
        assertEq(attestations.owner(), owner);
    }
    
    function test_Constructor_OwnerIsAuditor() public view {
        assertTrue(attestations.auditors(owner));
    }
    
    /*//////////////////////////////////////////////////////////////
                         AUDITOR REGISTRATION
    //////////////////////////////////////////////////////////////*/
    
    function test_RegisterAuditor_Success() public {
        vm.deal(auditor, 1 ether);
        vm.prank(auditor);
        attestations.registerAuditor{value: 0.01 ether}();
        
        assertTrue(attestations.auditors(auditor));
        assertEq(attestations.auditorStakes(auditor), 0.01 ether);
    }
    
    function test_RegisterAuditor_AccumulatesStake() public {
        vm.deal(auditor, 1 ether);
        
        vm.prank(auditor);
        attestations.registerAuditor{value: 0.01 ether}();
        
        vm.prank(auditor);
        attestations.registerAuditor{value: 0.05 ether}();
        
        assertEq(attestations.auditorStakes(auditor), 0.06 ether);
    }
    
    function test_RegisterAuditor_RevertsIfInsufficientStake() public {
        vm.deal(auditor, 1 ether);
        vm.prank(auditor);
        
        vm.expectRevert(SkillAttestations.InsufficientStake.selector);
        attestations.registerAuditor{value: 0.005 ether}();
    }
    
    /*//////////////////////////////////////////////////////////////
                           AUDITOR REMOVAL
    //////////////////////////////////////////////////////////////*/
    
    function test_RemoveAuditor_Success() public {
        // Setup auditor
        vm.deal(auditor, 1 ether);
        vm.prank(auditor);
        attestations.registerAuditor{value: 0.01 ether}();
        
        uint256 auditorBalanceBefore = auditor.balance;
        
        // Remove as owner
        vm.prank(owner);
        attestations.removeAuditor(auditor);
        
        assertFalse(attestations.auditors(auditor));
        assertEq(attestations.auditorStakes(auditor), 0);
        assertEq(auditor.balance, auditorBalanceBefore + 0.01 ether);
    }
    
    function test_RemoveAuditor_RevertsIfNotOwner() public {
        vm.prank(randomUser);
        
        vm.expectRevert(SkillAttestations.NotOwner.selector);
        attestations.removeAuditor(auditor);
    }
    
    /*//////////////////////////////////////////////////////////////
                               VIEWS
    //////////////////////////////////////////////////////////////*/
    
    function test_IsAuditor_ReturnsTrue() public view {
        assertTrue(attestations.isAuditor(owner));
    }
    
    function test_IsAuditor_ReturnsFalse() public view {
        assertFalse(attestations.isAuditor(randomUser));
    }
    
    /*//////////////////////////////////////////////////////////////
                           OWNERSHIP
    //////////////////////////////////////////////////////////////*/
    
    function test_TransferOwnership_Success() public {
        address newOwner = address(4);
        
        vm.prank(owner);
        attestations.transferOwnership(newOwner);
        
        assertEq(attestations.owner(), newOwner);
    }
    
    function test_TransferOwnership_RevertsIfNotOwner() public {
        vm.prank(randomUser);
        
        vm.expectRevert(SkillAttestations.NotOwner.selector);
        attestations.transferOwnership(randomUser);
    }
    
    /*//////////////////////////////////////////////////////////////
                           SCHEMA
    //////////////////////////////////////////////////////////////*/
    
    function test_SchemaString_IsCorrect() public view {
        assertEq(
            attestations.SKILL_SCHEMA(),
            "bytes32 skillHash,string skillName,string skillUrl,string version,uint8 rating,bool safe,string findings,string permissions"
        );
    }
}
