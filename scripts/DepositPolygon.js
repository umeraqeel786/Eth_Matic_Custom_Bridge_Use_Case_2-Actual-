require('dotenv').config();
const ethers = require('ethers');

// const ALCHEMY_API_URL_POLYGON = process.env.ALCHEMY_API_URL_POLYGON;
const LOCALHOST_URL_CHILD = process.env.LOCALHOST_URL_CHILD;
const PRIVATE_KEY_CHILD = process.env.PRIVATE_KEY_CHILD;
const childChainManagerAddress = process.env.CHILD_CHAIN_MANAGER_CONTRACT_ADDRESS;
const childChainManagerBuild = require('../build/contracts/ChildChainManager.json');


const customHttpProviderChild = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_CHILD);

async function deposit(receiverAddressEthereum, childTokenContractAddress, rootERC20PredicateAddress) {

    try {
        const walletChild = new ethers.Wallet(PRIVATE_KEY_CHILD, customHttpProviderChild);
        const childChainManagerContract = new ethers.Contract(childChainManagerAddress, childChainManagerBuild.abi, walletChild);

        const weiAmount = ethers.utils.parseEther('2');
        const depositData = ethers.utils.defaultAbiCoder.encode(['uint256'], [weiAmount])
        console.log("Depositing tokens.....");
        const result = await childChainManagerContract.depositFor(receiverAddressEthereum, childTokenContractAddress, depositData, rootERC20PredicateAddress);


        console.log("Transaction Successfully Done, Tokens deposited.");
        console.log("Tx Hash :", result.hash);
    }

    catch (err) {
        console.log(err);
    }
}

deposit("0x2262375112F06f445ba155d90FF1a260d7De5269",
    "0xF6e609C16f2ce718a2D5Bce94Eb02b499438e104",
    "0x286459A7bad31D4F8a4E3B52F9B54C1E268a7cF6"
);
