pragma solidity 0.6.6;

interface IChildChainManager {
    event TokenMapped(address indexed rootToken, address indexed childToken);
    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function mapToken(address rootToken, address childToken) external;

    function cleanMapToken(address rootToken, address childToken) external;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData,
        address childERC20Predicate
    ) external;
}
