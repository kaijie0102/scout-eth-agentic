// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISignatureUtils} from "eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol"; // methods for signing
import {IAVSDirectory} from "eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol"; // manage operators
import {ECDSA} from "solady/utils/ECDSA.sol"; // algo for signing
import {console} from "forge-std/console.sol";

contract ScoutServiceManager {
    using ECDSA for bytes32;

    // attributes
    address public immutable avsDirectory; // manage operators
    mapping(address => bool) public operatorRegistered;
    uint32 public latestTaskNum;
    mapping(uint32 => bytes32) public allTasksHashes;
    mapping(address => mapping(uint32 => bytes)) public allTaskResponses;

    // events
    event NewTaskCreated(uint32 indexed taskIndex, Task task);
    event TaskResponded(uint32 indexed taskIndex, Task task, bool isSafe, address operator);

    struct Task {
        string contents;
        uint32 taskCreatedBlock;
    }
    
    constructor(address _avsDirectory) {
        avsDirectory = _avsDirectory;
    }

    // modifier
    modifier onlyOperator() {
        // ensure that only operators can use
        console.log("hi");
        _;
    }

    // Registering operators
    function registerOperatorToAVS(
        address operator,
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature
    ) external {
        IAVSDirectory(avsDirectory).registerOperatorToAVS(operator, operatorSignature);
        operatorRegistered[operator] = true;
    }
    // Deregistering operators
    function deregisterOperatorFromAVS(address operator) external onlyOperator {
        // make sure sender is operator
        require(msg.sender==operator);
        IAVSDirectory(avsDirectory).deregisterOperatorFromAVS(operator);
        operatorRegistered[operator] = false;
    }
    // Create Task
    // emit is to log events
    // memory are for temporary variable


    // Respond to Task - call agentKit our defi agent
    // check task is valid and in contract
    // check task has been responded to
    // check that response has been signed by a valid operator


}