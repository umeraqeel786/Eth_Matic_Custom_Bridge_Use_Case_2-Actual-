require('dotenv').config();
const ethers = require('ethers');

//const ALCHEMY_API_URL_POLYGON = process.env.ALCHEMY_API_URL_POLYGON;
const LOCALHOST_URL_CHILD = process.env.LOCALHOST_URL_CHILD;
const PRIVATE_KEY_CHILD = process.env.PRIVATE_KEY_CHILD;
const childChainManagerAddress = process.env.CHILD_CHAIN_MANAGER_CONTRACT_ADDRESS;
const childChainManagerBuild = require('../build/contracts/ChildChainManager.json');

const customHttpProviderChild = new ethers.providers.JsonRpcProvider(LOCALHOST_URL_CHILD);

async function Exit(_childPredicateAddress, _childTokenAddress, _tokenAmount) {

    try {
        const walletChild = new ethers.Wallet(PRIVATE_KEY_CHILD, customHttpProviderChild);
        const childChainManagerContract = new ethers.Contract(childChainManagerAddress, childChainManagerBuild.abi, walletChild);

        console.log("Releasing ERC20 Tokens Locked in child ERC20 Predicate on User account on Polygon (Exiting process getting executed).");
        console.log("Exiting.......");
        const result = await childChainManagerContract.exit(_childPredicateAddress, _childTokenAddress, _tokenAmount);
        console.log("Transaction Successfully Done, Tokens Released on the CHILD Chain (Ethereum) by the Child ERC20Predicate.");
        console.log("Tx Hash :", result.hash);

    }
    catch (err) {
        console.log(err);
    }
}

let weiAmount = ethers.utils.parseEther('50');

Exit('0x76C0B53249d50EE78CB96924a856371571Ea0C57', '0xa52d7F99f90f4CE1BcF2d904452C237AC82877B6', weiAmount);
