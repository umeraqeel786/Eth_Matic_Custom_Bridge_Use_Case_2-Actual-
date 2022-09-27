pragma solidity 0.6.6;

interface IRootToken {
    function transfer(
        address user,
        bytes calldata depositData,
        address rootERC20Predicate
    ) external;
}
