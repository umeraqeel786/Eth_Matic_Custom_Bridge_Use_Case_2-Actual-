const bluebird = require('bluebird')

const Merkle = artifacts.require('Merkle')
const MerklePatriciaProof = artifacts.require('MerklePatriciaProof')
const RLPReader = artifacts.require('RLPReader')
const SafeERC20 = artifacts.require('SafeERC20')
const SafeMath = artifacts.require('SafeMath')

const RootChainManager = artifacts.require('RootChainManager')
const RootChainManagerProxy = artifacts.require('RootChainManagerProxy')
const DummyStateSender = artifacts.require('DummyStateSender')

const ERC20Predicate = artifacts.require('ERC20Predicate')
const ERC20PredicateProxy = artifacts.require('ERC20PredicateProxy')

const DummyERC20 = artifacts.require('DummyERC20')

const utils = require('./utils')

module.exports = async (deployer, network, accounts) => {
  await deployer

  console.log('deploying contracts...')
  const rootChainManager = await deployer.deploy(RootChainManager)
  const rootChainManagerProxy = await deployer.deploy(RootChainManagerProxy, '0x0000000000000000000000000000000000000000')
  await rootChainManagerProxy.updateAndCall(RootChainManager.address, rootChainManager.contract.methods.initialize(accounts[0]).encodeABI())

  // -- ERC20 Predicates Deployment, starting
  const erc20Predicate = await deployer.deploy(ERC20Predicate)
  const erc20PredicateProxy = await deployer.deploy(ERC20PredicateProxy, '0x0000000000000000000000000000000000000000')
  await erc20PredicateProxy.updateAndCall(erc20Predicate.address, erc20Predicate.contract.methods.initialize(accounts[0]).encodeABI())



  await deployer.deploy(DummyStateSender)

  // -- Dummy version of ERC20
  await deployer.deploy(DummyERC20, 'WRLDTest', 'WRLDERC20', RootChainManagerProxy.address, ERC20PredicateProxy.address)

  // -- ends

  const contractAddresses = utils.getContractAddresses()

  contractAddresses.root.RootChainManager = RootChainManager.address
  contractAddresses.root.RootChainManagerProxy = RootChainManagerProxy.address

  contractAddresses.root.DummyStateSender = DummyStateSender.address

  contractAddresses.root.ERC20Predicate = ERC20Predicate.address
  contractAddresses.root.ERC20PredicateProxy = ERC20PredicateProxy.address

  contractAddresses.root.DummyERC20 = DummyERC20.address


  utils.writeContractAddresses(contractAddresses)
}