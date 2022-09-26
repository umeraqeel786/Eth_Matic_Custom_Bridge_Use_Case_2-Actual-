require('dotenv').config();
const ethers = require('ethers');

const ALCHEMY_API_URL_POLYGON = process.env.ALCHEMY_API_URL_POLYGON;
// const LOCALHOST_URL_ROOT = process.env.LOCALHOST_URL_ROOT;
const LOCALHOST_URL_CHILD = process.env.LOCALHOST_URL_CHILD;
const PRIVATE_KEY_CHILD = process.env.PRIVATE_KEY_CHILD;
const childTokenAddress = process.env.CHILD_TOKEN_CONTRACT_ADDRESS;
const childTokenBuild = require('../build/contracts/ChildERC20.json');

const customHttpProviderChild = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_CHILD);


async function checkBalance() {

    try {
        const walletChild = new ethers.Wallet(PRIVATE_KEY_CHILD, customHttpProviderChild);
        const childTokenContract = new ethers.Contract(childTokenAddress, childTokenBuild.abi, walletChild);

        console.log("Checking Child ERC20 Contract Token Balance!...");
        const balance = await childTokenContract.balanceOf(childTokenAddress);
        console.log("This is childERC20ContractBalance:", balance.toString());
        console.log("Transaction Successfully Done.");
    }
    catch (err) {
        console.log(err);
    }
}


checkBalance();
