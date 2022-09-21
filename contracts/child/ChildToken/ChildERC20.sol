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
        address childChainManager
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

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        only(DEPOSITOR_ROLE)
    {
        uint256 amount = abi.decode(depositData, (uint256));
        //_mint(user, amount);
        _transfer(address(this), user, amount);
    }

    // function transfer(address user, bytes calldata depositData)
    //     external
    //     only(DEPOSITOR_ROLE)
    // {
    //     uint256 amount = abi.decode(depositData, (uint256));
    //     _transfer(address(this), user, amount);
    // }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}
