require('dotenv').config();
const ethers = require('ethers');

const INFURA_API_URL_GOERLI = process.env.INFURA_API_URL_GOERLI;
const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
const PRIVATE_KEY_ROOT = process.env.PRIVATE_KEY_ROOT;
const rootChainManagerAddress = process.env.ROOT_CHAIN_MANAGER_CONTRACT_ADDRESS;
const rootChainManagerBuild = require('../build/contracts/RootChainManager.json');

const customHttpProviderRoot = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_ROOT);

async function Exit(_rootPredicateAddress, _rootTokenAddress, _tokenAmount) {

    try {
        const walletRoot = new ethers.Wallet(PRIVATE_KEY_ROOT, customHttpProviderRoot);
        const rootChainManagerContract = new ethers.Contract(rootChainManagerAddress, rootChainManagerBuild.abi, walletRoot);

        console.log("Releasing ERC20 Tokens Locked in root ERC20 Predicate on User account on Ethereum (Exiting process getting executed).");
        console.log("Exiting.......");
        const result = await rootChainManagerContract.exit(_rootPredicateAddress, _rootTokenAddress, _tokenAmount);
        console.log("Transaction Successfully Done, Tokens Released on the ROOT Chain (Ethereum) by the root ERC20Predicate.");
        console.log("Tx Hash :", result.hash);

    }
    catch (err) {
        console.log(err);
    }
}

let weiAmount = ethers.utils.parseEther('50');

Exit('0x1DAf03D5F32176049c4F7F6633ef4aCeb3d0C22C', '0x827C8765a8b354d9b1239F9e9117DA0Fab0F3168', weiAmount);
