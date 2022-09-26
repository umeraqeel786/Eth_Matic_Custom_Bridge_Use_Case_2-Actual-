const ChildChainManager = artifacts.require('ChildChainManager')
const ChildChainManagerProxy = artifacts.require('ChildChainManagerProxy')
const ChildDummyStateSender = artifacts.require('ChildDummyStateSender')

const ERC20Predicate = artifacts.require('ERC20Predicate')
const ERC20PredicateProxy = artifacts.require('ERC20PredicateProxy')

const ChildERC20 = artifacts.require('ChildERC20')
// const ChildMintableERC20 = artifacts.require('ChildMintableERC20')


// const MaticWETH = artifacts.require('MaticWETH')
const utils = require('./utils')

module.exports = async (deployer, network, accounts) => {
  deployer.then(async () => {
    const childChainManager = await deployer.deploy(ChildChainManager)
    const childChainManagerProxy = await deployer.deploy(ChildChainManagerProxy, '0x0000000000000000000000000000000000000000')
    await childChainManagerProxy.updateAndCall(childChainManager.address, childChainManager.contract.methods.initialize(accounts[0]).encodeABI())

    // -- ERC20 Predicates Deployment, starting
    const erc20Predicate = await deployer.deploy(ERC20Predicate)
    const erc20PredicateProxy = await deployer.deploy(ERC20PredicateProxy, '0x0000000000000000000000000000000000000000')
    await erc20PredicateProxy.updateAndCall(erc20Predicate.address, erc20Predicate.contract.methods.initialize(accounts[0]).encodeABI())

    await deployer.deploy(ChildDummyStateSender)


    await deployer.deploy(ChildERC20, 'WRLDTest', 'WRLDERC20', 18, ChildChainManagerProxy.address, ERC20PredicateProxy.address)
    // await deployer.deploy(ChildMintableERC20, 'WRLDTest Mintable ERC20', 'WRLDMERC20', 18, ChildChainManagerProxy.address)

    // await deployer.deploy(MaticWETH, ChildChainManagerProxy.address)

    const contractAddresses = utils.getContractAddresses()

    contractAddresses.child.ChildChainManager = ChildChainManager.address
    contractAddresses.child.ChildChainManagerProxy = ChildChainManagerProxy.address

    contractAddresses.child.ChildDummyStateSender = ChildDummyStateSender.address

    contractAddresses.child.ERC20Predicate = ERC20Predicate.address
    contractAddresses.child.ERC20PredicateProxy = ERC20PredicateProxy.address

    contractAddresses.child.DummyERC20 = ChildERC20.address
    // contractAddresses.child.DummyMintableERC20 = ChildMintableERC20.address

    // contractAddresses.child.MaticWETH = MaticWETH.address

    utils.writeContractAddresses(contractAddresses)
  })
}