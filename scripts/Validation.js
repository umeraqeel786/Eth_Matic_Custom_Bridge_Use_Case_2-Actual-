require('dotenv').config();
const ethers = require('ethers');

const INFURA_API_URL_GOERLI = process.env.INFURA_API_URL_GOERLI;
const ALCHEMY_API_URL_POLYGON = process.env.ALCHEMY_API_URL_POLYGON;
// const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
// const LOCALHOST_URL_CHILD = process.env.LOCALHOST_URL_CHILD;
const PRIVATE_KEY_ROOT = process.env.PRIVATE_KEY_ROOT;
const PRIVATE_KEY_CHILD = process.env.PRIVATE_KEY_CHILD;
const dummyStateSenderAddress = process.env.DUMMY_STATE_SENDER_CONTRACT_ADDRESS;
const childChainManagerAddress = process.env.CHILD_CHAIN_MANAGER_CONTRACT_ADDRESS;

const dummyStateSenderBuild = require('../build/contracts/DummyStateSender.json');
const childChainManagerBuild = require('../build/contracts/ChildChainManager.json');


const customHttpProviderRoot = new ethers.providers.JsonRpcProvider(INFURA_API_URL_GOERLI);
const customHttpProviderChild = new ethers.providers.JsonRpcProvider(ALCHEMY_API_URL_POLYGON);

async function Validation() {

  try {
    let walletRoot = new ethers.Wallet(PRIVATE_KEY_ROOT, customHttpProviderRoot);
    let walletChild = new ethers.Wallet(PRIVATE_KEY_CHILD, customHttpProviderChild);

    let dummyStateSenderContract = new ethers.Contract(dummyStateSenderAddress, dummyStateSenderBuild.abi, walletRoot);
    let childChainManagerContract = new ethers.Contract(childChainManagerAddress, childChainManagerBuild.abi, walletChild);

    console.log("Validating...");
    console.log("Reading storage values from StateSenderContract...");

    const receiverContractAddressOnChildChain = await dummyStateSenderContract.receiverContractAddressOnChildChain();
    console.log("This is the receiver contract address on child chain:", receiverContractAddressOnChildChain);

    const _data = await dummyStateSenderContract._data();
    console.log("This is the data being send into the OnStateRecieve function in ChildChainManager:", _data);

    const result = await childChainManagerContract.onStateReceive(1, _data)


    console.log("Transaction Successfully Done");
    console.log("Tx Hash :", result.hash);

  } catch (err) {
    console.log(err);
  }
}


Validation();
