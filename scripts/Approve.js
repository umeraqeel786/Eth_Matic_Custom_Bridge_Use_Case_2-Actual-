require('dotenv').config();
const ethers = require('ethers');
//const INFURA_API_URL_GOERLI = process.env.INFURA_API_URL_GOERLI;
const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
const PRIVATE_KEY_ROOT = process.env.PRIVATE_KEY_ROOT;
const rootTokenAddress = process.env.ROOT_TOKEN_CONTRACT_ADDRESS;
const rootTokenBuild = require('../build/contracts/DummyERC20.json');

const customHttpProviderRoot = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_ROOT);

async function approve(rootERC20Predicate, tokenAmount) {

    try {
        const walletRoot = new ethers.Wallet(PRIVATE_KEY_ROOT, customHttpProviderRoot);
        const rootTokenContract = new ethers.Contract(rootTokenAddress, rootTokenBuild.abi, walletRoot);

        console.log("Approving RootERC20Predicate Contract...");
        const result = await rootTokenContract.approve(rootERC20Predicate, tokenAmount);
        console.log("Transaction Successfully Done");
        console.log("Tx Hash :", result.hash);
    }

    catch (err) {
        console.log(err);
    }
}

let weiAmount = ethers.utils.parseEther('10');

approve(
    "0x1DAf03D5F32176049c4F7F6633ef4aCeb3d0C22C",
    weiAmount
);
