pragma solidity 0.6.6;

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;

    function syncStateU2(
        address receiver,
        address childERC20Predicate,
        bytes calldata data
    ) external;
}
