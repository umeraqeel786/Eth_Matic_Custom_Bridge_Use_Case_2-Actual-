require('dotenv').config();
const ethers = require('ethers');


// const ALCHEMY_API_URL_POLYGON = process.env.ALCHEMY_API_URL_POLYGON;
const LOCALHOST_URL_CHILD = process.env.LOCALHOST_URL_CHILD;
const PRIVATE_KEY_CHILD = process.env.PRIVATE_KEY_CHILD;
const childTokenAddress = process.env.CHILD_TOKEN_CONTRACT_ADDRESS;
const childTokenBuild = require('../build/contracts/ChildERC20.json');

const customHttpProviderChild = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_CHILD);

async function approve(childERC20Predicate, tokenAmount) {

    try {
        const walletChild = new ethers.Wallet(PRIVATE_KEY_CHILD, customHttpProviderChild);
        const childTokenContract = new ethers.Contract(childTokenAddress, childTokenBuild.abi, walletChild);

        console.log("Approving ChildERC20Predicate Contract...");
        const result = await childTokenContract.approve(childERC20Predicate, tokenAmount);
        console.log("Transaction Successfully Done");
        console.log("Tx Hash :", result.hash);
    }

    catch (err) {
        console.log(err);
    }
}

let weiAmount = ethers.utils.parseEther('10');

approve(
    "0xFc1bbE999C75C862FfBdA5Dba77730E54f5db24B",
    weiAmount
);
