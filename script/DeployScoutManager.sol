// Used to deploy service manager
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {ScoutServiceManager} from "../src/ScoutServiceManager.sol";
import {IDelegationManager} from "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import {AVSDirectory} from "eigenlayer-contracts/src/contracts/core/AVSDirectory.sol";
import {ISignatureUtils} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol";

contract DeployScoutServiceManager is Script {

    // Eigen Core Contracts
    address internal constant AVS_DIRECTORY = 0x135DDa560e946695d6f155dACaFC6f1F25C1F5AF; 
    address internal constant DELEGATION_MANAGER = 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A;

    
    address internal deployer;
    address internal operator;
    ScoutServiceManager serviceManager;

    // setup
    function setUp() public virtual {
        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY")); // derive deployers address from private key created by Anvil
        operator = vm.rememberKey(vm.envUint("OPERATOR_PRIVATE_KEY")); // derive operators address from private key created by Anvil
        vm.label(deployer, "Deployer");
        vm.label(operator, "Operator");
    }

    // Deploy contract
    function run() public {
        vm.startBroadcast(deployer);
        serviceManager = new ScoutServiceManager(AVS_DIRECTORY);
        vm.stopBroadcast();

        // Register operator to eigenlayer
        IDelegationManager delegationManager = IDelegationManager(DELEGATION_MANAGER);
        // IDelegationManager.OperatorDetails memory operatorDetails = IDelegationManager.OperatorDetails({
        //     __deprecated_earningsReceiver: operator,
        //     delgationApprover: address(0), // no need for now 
        //     stakerOptOutWindowBlocks: 0 // no need for now 
        // });

        vm.startBroadcast(operator);
        delegationManager.registerAsOperator(operatorDetails, 0, "");
        // delegationManager.registerAsOperator(operator, 0, "");
        vm.stopBroadcast();

        
    }
}