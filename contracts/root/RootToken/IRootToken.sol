pragma solidity 0.6.6;

interface IRootToken {
    //function deposit(address user, bytes calldata depositData) external;

    function transfer(
        address user,
        bytes calldata depositData,
        address rootERC20Predicate
    ) external;
}
