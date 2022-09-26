pragma solidity 0.6.6;

import {IStateSender} from "../StateSender/IStateSender.sol";

/**
 * @notice Dummy State Sender contract to simulate plasma state sender while testing
 */
contract ChildDummyStateSender is IStateSender {
    uint256 public idOfTheSync;
    address public receiverContractAddressOnRootChain;
    address public _rootERC20Predicate;
    bytes public _data;

    /**
     * @notice Event emitted when when syncState is called
     * @dev Heimdall bridge listens to this event and sends the data to receiver contract on child chain
     * @param id Id of the sync, increamented for each event in case of actual state sender contract
     * @param contractAddress the contract receiving data on child chain
     * @param data bytes data to be sent
     */

    event StateSynced(
        uint256 indexed id,
        address indexed contractAddress,
        bytes data
    );

    /**
     * @notice called to send data to child chain
     * @dev sender and receiver contracts need to be registered in case of actual state sender contract
     * @param receiver the contract receiving data on child chain
     * @param data bytes data to be sent
     */
    function syncState(address receiver, bytes calldata data)
        external
        override
    {
        receiverContractAddressOnRootChain = receiver;
        _data = data;

        emit StateSynced(1, receiver, data);
    }

    function syncStateU2(
        address receiver,
        address rootERC20Predicate,
        bytes calldata data
    ) external override {
        receiverContractAddressOnRootChain = receiver;
        _rootERC20Predicate = rootERC20Predicate;
        _data = data;

        emit StateSynced(1, receiver, data);
    }
}