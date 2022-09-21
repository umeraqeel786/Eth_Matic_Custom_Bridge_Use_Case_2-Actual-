const ChildChainManager = artifacts.require('ChildChainManager')

const utils = require('../migrations/utils')
const config = require('../migrations/config')

module.exports = async (deployer) => {
  const contractAddresses = utils.getContractAddresses()

  const ChildChainManagerInstance = await ChildChainManager.at(contractAddresses.child.ChildChainManagerProxy)

  console.log('Granting STATE_SYNCER_ROLE on ChildChainManager')
  const STATE_SYNCER_ROLE = await ChildChainManagerInstance.STATE_SYNCER_ROLE()
  await ChildChainManagerInstance.grantRole(STATE_SYNCER_ROLE, config.stateReceiver)

  console.log('Mapping DummyERC20')
  await ChildChainManagerInstance.mapToken(contractAddresses.root.DummyERC20, contractAddresses.child.DummyERC20)

  console.log('Mapping DummyMintableERC20')
  await ChildChainManagerInstance.mapToken(contractAddresses.root.DummyMintableERC20, contractAddresses.child.DummyMintableERC20)

  console.log('Mapping WETH')
  await ChildChainManagerInstance.mapToken('0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', contractAddresses.child.MaticWETH)
}