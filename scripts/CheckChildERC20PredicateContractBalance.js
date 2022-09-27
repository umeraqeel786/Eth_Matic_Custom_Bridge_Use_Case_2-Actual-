require('dotenv').config();
const ethers = require('ethers');

//const ALCHEMY_API_URL_POLYGON = process.env.ALCHEMY_API_URL_POLYGON;
const LOCALHOST_URL_CHILD = process.env.LOCALHOST_URL_CHILD;
const PRIVATE_KEY_CHILD = process.env.PRIVATE_KEY_CHILD;
const childERC20PredicateAddress = process.env.CHILD_PREDICATE_CONTRACT_ADDRESS;
const childERC20PredicateBuild = require('../build/contracts/ChildERC20Predicate.json');

console.log("childERC20PredicateBuild:", childERC20PredicateBuild.abi);
console.log("childERC20PredicateAddress:", childERC20PredicateAddress);

const customHttpProviderChild = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_CHILD);


async function checkBalance() {

    try {
        const walletChild = new ethers.Wallet(PRIVATE_KEY_CHILD, customHttpProviderChild);
        const childERC20PredicateContract = new ethers.Contract(childERC20PredicateAddress, childERC20PredicateBuild.abi, walletChild);

        console.log("Checking Child ERC20 Predicate Contract Token Balance!...");
        const balance = await childERC20PredicateContract.balanceOf(childERC20PredicateAddress);
        console.log("This is childERC20PredicateContractBalance:", balance.toString());
        console.log("Transaction Successfully Done.");
    }
    catch (err) {
        console.log(err);
    }
}


checkBalance();
