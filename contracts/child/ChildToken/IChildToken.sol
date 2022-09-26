pragma solidity 0.6.6;

interface IChildToken {
    // function deposit(address user, bytes calldata depositData) external;

    function transfer(
        address user,
        bytes calldata depositData,
        address childERC20Predicate
    ) external;
}
