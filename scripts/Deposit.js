require('dotenv').config();
const ethers = require('ethers');
//const INFURA_API_URL_GOERLI = process.env.INFURA_API_URL_GOERLI;
const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
const PRIVATE_KEY_ROOT = process.env.PRIVATE_KEY_ROOT;
const rootChainManagerAddress = process.env.ROOT_CHAIN_MANAGER_CONTRACT_ADDRESS;
const rootChainManagerBuild = require('../build/contracts/RootChainManager.json');

const customHttpProviderRoot = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_ROOT);

async function deposit(receiverAddressPolygon, rootTokenContractAddress, childERC20PredicateAddress) {

    try {
        const walletRoot = new ethers.Wallet(PRIVATE_KEY_ROOT, customHttpProviderRoot);
        const rootChainManagerContract = new ethers.Contract(rootChainManagerAddress, rootChainManagerBuild.abi, walletRoot);

        const weiAmount = ethers.utils.parseEther('2');
        const depositData = ethers.utils.defaultAbiCoder.encode(['uint256'], [weiAmount])
        console.log("Depositing tokens.....");
        const result = await rootChainManagerContract.depositFor(receiverAddressPolygon, rootTokenContractAddress, depositData, childERC20PredicateAddress);


        console.log("Transaction Successfully Done, Tokens deposited.");
        console.log("Tx Hash :", result.hash);
    }

    catch (err) {
        console.log(err);
    }
}

deposit("0x2262375112F06f445ba155d90FF1a260d7De5269",
    "0x55FDDC8A0c5367d50682d76cd9674F5aB362A6Bf",
    "0xA36B49537996fE54986B019d8eF3138b8cfff1aC"
);
