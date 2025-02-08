// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISignatureUtils} from "lib/eigenlayer-contracts/src/contracts/interfaces/ISignatureUtils.sol"; // methods for signing
import {IAVSDirectory} from "lib/eigenlayer-contracts/src/contracts/interfaces/IAVSDirectory.sol"; // manage operators
import {ECDSA} from "lib/solady/src/utils/ECDSA.sol"; // algo for signing
import {console} from "forge-std/console.sol";

contract ScoutServiceManager {
    using ECDSA for bytes32;

    // attributes
    address public immutable avsDirectory; // manage operators
    mapping(address => bool) public operatorsRegistered;
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
        operatorsRegistered[operator] = true;
    }
    // Deregistering operators
    function deregisterOperatorFromAVS(address operator) external onlyOperator {
        // make sure sender is operator
        require(msg.sender==operator);
        IAVSDirectory(avsDirectory).deregisterOperatorFromAVS(operator);
        operatorsRegistered[operator] = false;
    }
    // Create Task
    function createNewTask(
        string memory contents
    ) external returns (Task memory) {
        // create a new task struct
        Task memory newTask;
        newTask.contents = contents;
        newTask.taskCreatedBlock = uint32(block.number);

        // store hash of task onchain, emit event, and increase taskNum
        allTaskHashes[latestTaskNum] = keccak256(abi.encode(newTask));
        emit NewTaskCreated(latestTaskNum, newTask);
        latestTaskNum = latestTaskNum + 1;

        return newTask;
    }

    // Respond to Task - call agentKit our defi agent
    // check task is valid and in contract
    // check task has been responded to
    // check that response has been signed by a valid operator


}