pragma solidity 0.6.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";
import {IChildToken} from "./IChildToken.sol";
import {NativeMetaTransaction} from "../../common/NativeMetaTransaction.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";

contract ChildERC20 is
    ERC20,
    IChildToken,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    uint256 private totalSupplyContract;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address childChainManager,
        address childERC20predicate_
    ) public ERC20(name_, symbol_) {
        _setupContractId("ChildERC20");
        _setupDecimals(decimals_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, childChainManager);
        _initializeEIP712(name_);

        totalSupplyContract = 100 * (10**18);
        uint256 amount = 50 * (10**18);
        _mint(address(this), totalSupplyContract);
        _transfer(address(this), _msgSender(), amount);
        _transfer(address(this), childERC20predicate_, amount);
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

    function transfer(
        address user,
        bytes calldata depositData,
        address childERC20Predicate
    ) external override only(DEPOSITOR_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _transfer(childERC20Predicate, user, amount);
    }
}
