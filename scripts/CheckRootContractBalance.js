require('dotenv').config();
const ethers = require('ethers');

//const INFURA_API_URL_GOERLI = process.env.INFURA_API_URL_GOERLI;
const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
const PRIVATE_KEY_ROOT = process.env.PRIVATE_KEY_ROOT;
const rootTokenAddress = process.env.ROOT_TOKEN_CONTRACT_ADDRESS;
const rootTokenBuild = require('../build/contracts/DummyERC20.json');

const customHttpProviderRoot = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_ROOT);


async function checkBalance() {

    try {
        const walletRoot = new ethers.Wallet(PRIVATE_KEY_ROOT, customHttpProviderRoot);
        const rootTokenContract = new ethers.Contract(rootTokenAddress, rootTokenBuild.abi, walletRoot);

        console.log("Checking Root ERC20 Contract Token Balance!...");
        const balance = await rootTokenContract.balanceOf(rootTokenAddress);
        console.log("This is RootERC20ContractBalance:", balance.toString());
        console.log("Transaction Successfully Done.");
    }
    catch (err) {
        console.log(err);
    }
}


checkBalance();
