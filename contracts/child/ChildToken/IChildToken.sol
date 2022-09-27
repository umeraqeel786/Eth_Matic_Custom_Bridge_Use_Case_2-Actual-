pragma solidity 0.6.6;

interface IChildToken {
    function transfer(
        address user,
        bytes calldata depositData,
        address childERC20Predicate
    ) external;
}
