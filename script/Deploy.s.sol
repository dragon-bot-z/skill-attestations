// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {SkillAttestations} from "../src/SkillAttestations.sol";

contract DeployScript is Script {
    function run() public returns (SkillAttestations) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the registry
        SkillAttestations attestations = new SkillAttestations();
        console2.log("SkillAttestations deployed to:", address(attestations));
        
        // Register the schema
        bytes32 schemaUID = attestations.registerSchema();
        console2.log("Schema registered with UID:");
        console2.logBytes32(schemaUID);
        
        vm.stopBroadcast();
        
        return attestations;
    }
}
