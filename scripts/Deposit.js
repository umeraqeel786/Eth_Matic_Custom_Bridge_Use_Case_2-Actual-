require('dotenv').config();
const ethers = require('ethers');
const INFURA_API_URL_GOERLI = process.env.INFURA_API_URL_GOERLI;
//const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
const PRIVATE_KEY_ROOT = process.env.PRIVATE_KEY_ROOT;
const rootChainManagerAddress = process.env.ROOT_CHAIN_MANAGER_CONTRACT_ADDRESS;
const rootChainManagerBuild = require('../build/contracts/RootChainManager.json');

const customHttpProviderRoot = new ethers.providers.JsonRpcProvider(INFURA_API_URL_GOERLI);

async function deposit(receiverAddressPolygon, rootTokenContractAddress) {

    try {
        const walletRoot = new ethers.Wallet(PRIVATE_KEY_ROOT, customHttpProviderRoot);
        const rootChainManagerContract = new ethers.Contract(rootChainManagerAddress, rootChainManagerBuild.abi, walletRoot);

        const weiAmount = ethers.utils.parseEther('2');
        const depositData = ethers.utils.defaultAbiCoder.encode(['uint256'], [weiAmount])
        console.log("Depositing tokens.....");
        const result = await rootChainManagerContract.depositFor(receiverAddressPolygon, rootTokenContractAddress, depositData);


        console.log("Transaction Successfully Done, Tokens deposited.");
        console.log("Tx Hash :", result.hash);
    }

    catch (err) {
        console.log(err);
    }
}

deposit("0xa864f883E78F67a005a94B1B32Bf3375dfd121E6",
    "0x1739826dc83243ce0BFAE579E9D045AdDe5B334D"
);
