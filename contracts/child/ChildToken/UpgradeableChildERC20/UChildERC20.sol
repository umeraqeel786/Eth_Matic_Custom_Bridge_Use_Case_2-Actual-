pragma solidity 0.6.6;

import {ERC20} from "./ERC20.sol";
import {AccessControlMixin} from "../../../common/AccessControlMixin.sol";
import {IChildToken} from "../IChildToken.sol";
import {NativeMetaTransaction} from "../../../common/NativeMetaTransaction.sol";
import {ContextMixin} from "../../../common/ContextMixin.sol";

contract UChildERC20 is
    ERC20,
    IChildToken,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor() public ERC20("", "") {}

    /**
     * @notice Initialize the contract after it has been proxified
     * @dev meant to be called once immediately after deployment
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_,
        address childChainManager
    ) external initializer {
        setName(name_);
        setSymbol(symbol_);
        setDecimals(decimals_);
        _setupContractId(string(abi.encodePacked("Child", symbol_)));
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, childChainManager);
        _initializeEIP712(name_);
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        view
        override
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }

    function changeName(string calldata name_)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        setName(name_);
        _setDomainSeperator(name_);
    }

    function transfer(
        address user,
        bytes calldata depositData,
        address childERC20Predicate
    ) external override only(DEPOSITOR_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _transfer(childERC20Predicate, user, amount);
    }
}
