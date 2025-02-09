import { createPublicClient, createWalletClient, http, parseAbi } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { anvil } from 'viem/chains';
import 'dotenv/config';

if (!process.env.PRIVATE_KEY) {
    throw new Error('PRIVATE_KEY not found in environment variables');
  }
  
  export type Task = {
    contents: string;
    taskCreatedBlock: number;
  };
  
  // passing in signature of new task to interact with contracts
  const abi = parseAbi([
    'function createNewTask(string memory contents) external returns (string contents, uint32 taskCreatedBlock)'
  ]);

  async function main() {
    const contractAddress = '0x6d055A4babb2A0d1B3Abb32937DB437210be6161'
  
    // casting for viem
    const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
  
    const publicClient = createPublicClient({
      chain: anvil,
      transport: http('http://localhost:8545'),
    });
  
    // to create transactions on chain
    const walletClient = createWalletClient({
      chain: anvil,
      transport: http('http://localhost:8545'),
      account, // account to sign transactions
    });
  
    try {
      // simulate before actually sending
      const { request } = await publicClient.simulateContract({
        address: contractAddress,
        abi: abi,
        functionName: 'createNewTask',
        args: ['Hello World'],
        account: account.address,
      });
      console.log("Simulated Request:", request);
  
      // obtain hash using writeContract()
      const hash = await walletClient.writeContract(request);
      // wait for transaction to be mined
      const receipt = await publicClient.waitForTransactionReceipt({ hash });
      console.log('Transaction hash:', hash);
      console.log('Transaction receipt:', receipt);
    } catch (error) {
      console.error('Error:', error);
    }
  }
  
  main().catch(console.error);