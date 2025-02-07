// Used to deploy service manager
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ScoutServiceManager} from "../src/ScoutServiceManager.sol";
import {IDelegationManager} from "lib/eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {AVSDirectory} from "lib/eigenlayer-contracts/src/contracts/core/AVSDirectory.sol";
import {ISignatureUtils} from "lib/eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol";
import "forge-std/Test.sol";

contract DeployScoutServiceManager is Script {

    // Eigen Core Contracts
    address internal constant AVS_DIRECTORY = 0x055733000064333CaDDbC92763c58BF0192fFeBf;
    address internal constant DELEGATION_MANAGER = 0xA44151489861Fe9e3055d95adC98FbD462B948e7;
    address internal deployer;
    address internal operator;
    ScoutServiceManager scoutServiceManager;

    // setup
    function setUp() public virtual {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY")); // derive deployers address from private key created by Anvil
        operator = vm.rememberKey(vm.envUint("OPERATOR_PRIVATE_KEY")); // derive operators address from private key created by Anvil
        vm.label(deployer, "Deployer");
        vm.label(operator, "Operator");
    }

    // Deploy contract
    function run() public virtual {
        vm.startBroadcast(deployer);
        scoutServiceManager = new ScoutServiceManager(AVS_DIRECTORY);
        vm.stopBroadcast();

        IDelegationManager delegationManager = IDelegationManager(DELEGATION_MANAGER);
        vm.startBroadcast(operator);
        delegationManager.registerAsOperator(operator, 0, "");
        vm.stopBroadcast();

        // Register operator to AVS
        AVSDirectory avsDirectory = AVSDirectory(AVS_DIRECTORY);
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, operator)); // concat timestamp n operator
        uint256 expiry = block.timestamp + 1 hours; // signature expiry

        // create hash for signing
        bytes32 operatorRegistrationDigestHash = avsDirectory 
            .calculateOperatorAVSRegistrationDigestHash(
                operator,
                address(scoutServiceManager),
                salt,
                expiry
            );

        // sign and bundle into 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            vm.envUint("OPERATOR_PRIVATE_KEY"),
            operatorRegistrationDigestHash
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        // passed to service manager during registration  
        ISignatureUtils.SignatureWithSaltAndExpiry
            memory operatorSignature = ISignatureUtils.SignatureWithSaltAndExpiry({
                    signature: signature,
                    salt: salt,
                    expiry: expiry
                });

        vm.startBroadcast(operator);
        scoutServiceManager.registerOperatorToAVS(operator, operatorSignature);
        vm.stopBroadcast();
    }
}