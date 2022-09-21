const RootChainManager = artifacts.require('RootChainManager')

const ERC20Predicate = artifacts.require('ERC20Predicate')

const DummyMintableERC20 = artifacts.require('DummyMintableERC20')

const utils = require('../migrations/utils')
const config = require('../migrations/config')

module.exports = async (deployer) => {
  const contractAddresses = utils.getContractAddresses()

  const RootChainManagerInstance = await RootChainManager.at(contractAddresses.root.RootChainManagerProxy)

  const ERC20PredicateInstance = await ERC20Predicate.at(contractAddresses.root.ERC20PredicateProxy)

  const DummyMintableERC20Instance = await DummyMintableERC20.at(contractAddresses.root.DummyMintableERC20)

  console.log('Setting StateSender')
  await RootChainManagerInstance.setStateSender(contractAddresses.root.DummyStateSender)

  console.log('Setting ChildChainManager')
  await RootChainManagerInstance.setChildChainManagerAddress(contractAddresses.child.ChildChainManagerProxy)

  console.log('Setting CheckpointManager')
  await RootChainManagerInstance.setCheckpointManager(config.plasmaRootChain)

  console.log('Granting manager role on ERC20Predicate')
  const MANAGER_ROLE = await ERC20PredicateInstance.MANAGER_ROLE()
  await ERC20PredicateInstance.grantRole(MANAGER_ROLE, RootChainManagerInstance.address)

  const PREDICATE_ROLE = await DummyMintableERC20Instance.PREDICATE_ROLE()

  console.log('Registering ERC20Predicate')
  const ERC20Type = await ERC20PredicateInstance.TOKEN_TYPE()
  await RootChainManagerInstance.registerPredicate(ERC20Type, ERC20PredicateInstance.address)

  console.log('Mapping DummyERC20')
  await RootChainManagerInstance.mapToken(contractAddresses.root.DummyERC20, contractAddresses.child.DummyERC20, ERC20Type)
}