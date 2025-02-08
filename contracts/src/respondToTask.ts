import { createPublicClient, createWalletClient, http, parseAbi, encodePacked, keccak256, parseAbiItem, AbiEvent } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { anvil } from 'viem/chains';
import 'dotenv';
import { Task } from "./createTask";

import * as Chatbot from "../../agentkit/typescript/examples/langchain-cdp-chatbot/chatbot"

if (!process.env.OPERATOR_PRIVATE_KEY) {
  throw new Error('OPERATOR_PRIVATE_KEY not found in environment variables');
}

const abi = parseAbi([
  'function respondToTask((string contents, uint32 taskCreatedBlock) task, uint32 referenceTaskIndex, string actionTaken, bytes memory signature) external',
  'event NewTaskCreated(uint32 indexed taskIndex, (string contents, uint32 taskCreatedBlock) task)'
]);

async function createSignature(account: any, actionTaken: string, contents: string) {
  // Recreate the same message hash that the contract uses
  const messageHash = keccak256(
    encodePacked(
      ['string', 'string'],
      [actionTaken, contents]
    )
  );

  // Sign the message hash
  const signature = await account.signMessage({
    message: { raw: messageHash }
  });

  return signature;
}

async function respondToTask(
  walletClient: any,
  publicClient: any,
  contractAddress: string,
  account: any,
  task: Task,
  taskIndex: number
) {
  try {
    let actionTaken = ""
    const response = ""
    const {agent, config} = Chatbot.initializeAgent();
    await runChatMode(agent,config) // run chat mode by default

    // let isSafe = true;
    // if (response.message.content.includes('unsafe')) {
    //   isSafe = false
    // }

    const signature = await createSignature(account, actionTaken, task.contents);

    const { request } = await publicClient.simulateContract({
      address: contractAddress,
      abi,
      functionName: 'respondToTask',
      args: [task, taskIndex, signature],
      account: account.address,
    });

    const hash = await walletClient.writeContract(request);
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log('Responded to task:', {
      taskIndex,
      task,
      transactionHash: hash
    });
  } catch (error) {
    console.error('Error responding to task:', error);
  }
}

async function main() {
  const contractAddress = '0x121f7e412A536D673DaB310F1448ce0e3843068a';

  const account = privateKeyToAccount(process.env.OPERATOR_PRIVATE_KEY as `0x${string}`);

  const publicClient = createPublicClient({
    chain: anvil,
    transport: http('http://localhost:8545'),
  });

  const walletClient = createWalletClient({
    chain: anvil,
    transport: http('http://localhost:8545'),
    account,
  });

  function isNewTaskCreatedArgs(args: unknown): args is {
    taskIndex: number;
    task: { contents: string; taskCreatedBlock: number };
  } {
    return (
      args !== null &&
      typeof args === 'object' &&
      'taskIndex' in args &&
      typeof args.taskIndex === 'number' &&
      'task' in args &&
      typeof args.task === 'object' &&
      args.task !== null &&
      'contents' in args.task &&
      'taskCreatedBlock' in args.task
    );
  }

  console.log('Starting to watch for new tasks...');
  publicClient.watchEvent({
    address: contractAddress,
    event: parseAbiItem('event NewTaskCreated(uint32 indexed taskIndex, (string contents, uint32 taskCreatedBlock) task)') as AbiEvent,
    onLogs: async (logs) => {
      for (const log of logs) {
        const { args } = log;
        if (!args) continue;

        let taskIndex, task;
        if (isNewTaskCreatedArgs(args)) {
            ({ taskIndex, task } = args);
            console.log('New task detected:', { taskIndex, task });
        }

        await respondToTask(
          walletClient,
          publicClient,
          contractAddress,
          account,
          task,
          taskIndex
        );
      }
    },
  });

  process.on('SIGINT', () => {
    console.log('Stopping task watcher...');
    process.exit();
  });

  await new Promise(() => { });
}

main().catch(console.error);