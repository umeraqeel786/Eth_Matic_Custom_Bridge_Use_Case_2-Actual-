pragma solidity 0.6.6;

import {RLPReader} from "../../lib/RLPReader.sol";

/// @title Token predicate interface for all pos portal predicates
/// @notice Abstract interface that defines methods for custom predicates
interface ITokenPredicate {
    /**
     * @notice Deposit tokens into pos portal
     * @dev When `depositor` deposits tokens into pos portal, tokens get locked into predicate contract.
     * @param depositor Address who wants to deposit tokens
     * @param depositReceiver Address (address) who wants to receive tokens on side chain
     * @param rootToken Token which gets deposited
     * @param depositData Extra data for deposit (amount for ERC20, token id for ERC721 etc.) [ABI encoded]
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external;

    /**
     * @notice processes exit while withdraw process
     * @dev This function releases the ERC20 Tokens that where locked in by ERC20Predicate contract when RootchainManagers depositFor() was called.
     *
     * @param _withdrawer: Root chain Address whose ERC20Tokens were deposited and locked.
     * @param _rootTokenAddress: Root Token address  on Ethereum Chain.
     * @param _tokenAmount: ERC20 Tokens Amount which needs to be unlocked and refunded on the root chain
     */
    function exitTokens(
        address _withdrawer,
        address _rootTokenAddress,
        uint256 _tokenAmount
    ) external;

    function contractBalance() external view returns (uint256);
}
