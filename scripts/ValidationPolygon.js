require('dotenv').config();
const ethers = require('ethers');

// const INFURA_API_URL_GOERLI = process.env.INFURA_API_URL_GOERLI;
// const ALCHEMY_API_URL_POLYGON = process.env.ALCHEMY_API_URL_POLYGON;
const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
const LOCALHOST_URL_CHILD = process.env.LOCALHOST_URL_CHILD;
const PRIVATE_KEY_ROOT = process.env.PRIVATE_KEY_ROOT;
const PRIVATE_KEY_CHILD = process.env.PRIVATE_KEY_CHILD;
const childDummyStateSenderAddress = process.env.CHILD_STATE_SENDER_CONTRACT_ADDRESS;
const rootChainManagerAddress = process.env.ROOT_CHAIN_MANAGER_CONTRACT_ADDRESS;

const childDummyStateSenderBuild = require('../build/contracts/ChildDummyStateSender.json');
const rootChainManagerBuild = require('../build/contracts/RootChainManager.json');


const customHttpProviderRoot = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_ROOT);
const customHttpProviderChild = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_CHILD);

async function Validation() {

  try {
    let walletRoot = new ethers.Wallet(PRIVATE_KEY_ROOT, customHttpProviderRoot);
    let walletChild = new ethers.Wallet(PRIVATE_KEY_CHILD, customHttpProviderChild);

    let childDummyStateSenderContract = new ethers.Contract(childDummyStateSenderAddress, childDummyStateSenderBuild.abi, walletChild);
    let rootChainManagerContract = new ethers.Contract(rootChainManagerAddress, rootChainManagerBuild.abi, walletRoot);

    console.log("Validating...");
    console.log("Reading storage values from ChildStateSenderContract...");

    const receiverContractAddressOnRootChain = await childDummyStateSenderContract.receiverContractAddressOnRootChain();
    console.log("This is the receiver contract address on root chain:", receiverContractAddressOnRootChain);

    const _data = await childDummyStateSenderContract._data();
    console.log("This is the data being send into the OnStateRecieve function in RootChainManager:", _data);

    const _rootERC20PredicateAddress = await childDummyStateSenderContract._rootERC20Predicate();
    console.log("This is the root ERC20 predicate address on root chain:", _rootERC20PredicateAddress);

    const result = await rootChainManagerContract.onStateReceive(1, _data, _rootERC20PredicateAddress)


    console.log("Transaction Successfully Done");
    console.log("Tx Hash :", result.hash);

  } catch (err) {
    console.log(err);
  }
}


Validation();
