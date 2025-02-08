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

    // Respond to Task
    function respondToTask(
        Task calldata task,
        uint32 referenceTaskIndex,
        bool isSafe,
        bytes memory signature
    ) external onlyOperator {
        // check task is valid and in contract
        require(
            keccak256(abi.encode(task)) == allTaskHashes[referenceTaskIndex],
            "supplied task does not match the one recorded in the contract"
        );
        // check task has been responded to
        require(
            allTaskResponses[msg.sender][referenceTaskIndex].length == 0,
            "Operator has already responded to the task"
        );

        // check that response has been signed by a valid operator
        bytes32 messageHash = keccak256(
            abi.encodePacked(isSafe, task.contents)
        );
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        if (ethSignedMessageHash.recover(signature) != msg.sender) {
            revert("Invalid Signature");
        }

        // Respond to Task - call agentKit our defi agent
        // updating the storage with task responses
        allTaskResponses[msg.sender][referenceTaskIndex] = signature;

        // emitting event
        emit TaskResponded(referenceTaskIndex, task, isSafe, msg.sender);
    }


}