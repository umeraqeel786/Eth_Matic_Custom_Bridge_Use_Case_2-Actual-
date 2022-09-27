const ChildChainManager = artifacts.require('ChildChainManager')
const ChildERC20Predicate = artifacts.require('ChildERC20Predicate')

const utils = require('../migrations/utils')
const config = require('../migrations/config')

module.exports = async (deployer) => {
  const contractAddresses = utils.getContractAddresses()

  const ChildChainManagerInstance = await ChildChainManager.at(contractAddresses.child.ChildChainManagerProxy)

  const ChildERC20PredicateInstance = await ChildERC20Predicate.at(contractAddresses.child.ERC20PredicateProxy)



  console.log('Setting ChildStateSender')
  await ChildChainManagerInstance.setStateSender(contractAddresses.child.ChildDummyStateSender)

  console.log('Setting RootChainManager')
  await ChildChainManagerInstance.setRootChainManagerAddress(contractAddresses.root.RootChainManagerProxy)

  console.log('Setting CheckpointManager')
  await ChildChainManagerInstance.setCheckpointManager(config.plasmaRootChain)

  console.log('Granting manager role on ChildERC20Predicate')
  const MANAGER_ROLE = await ChildERC20PredicateInstance.MANAGER_ROLE()
  await ChildERC20PredicateInstance.grantRole(MANAGER_ROLE, ChildChainManagerInstance.address)


  console.log('Registering ChildERC20Predicate')
  const ERC20Type = await ChildERC20PredicateInstance.TOKEN_TYPE()
  await ChildChainManagerInstance.registerPredicate(ERC20Type, ChildERC20PredicateInstance.address)


  console.log('Mapping ChildERC20')
  await ChildChainManagerInstance.mapToken(contractAddresses.root.DummyERC20, contractAddresses.child.DummyERC20, ERC20Type)





  console.log('Granting STATE_SYNCER_ROLE on ChildChainManager')
  const STATE_SYNCER_ROLE = await ChildChainManagerInstance.STATE_SYNCER_ROLE()
  await ChildChainManagerInstance.grantRole(STATE_SYNCER_ROLE, config.stateReceiver)

  console.log('Mapping DummyERC20')
  await ChildChainManagerInstance.mapToken(contractAddresses.root.DummyERC20, contractAddresses.child.DummyERC20)


}