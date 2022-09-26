pragma solidity 0.6.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";
import {RLPReader} from "../../lib/RLPReader.sol";
import {ITokenPredicate} from "./ITokenPredicate.sol";
import {Initializable} from "../../common/Initializable.sol";

contract ChildERC20Predicate is
    ITokenPredicate,
    AccessControlMixin,
    Initializable,
    ERC20
{
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant TOKEN_TYPE = keccak256("ERC20");
    bytes32 public constant TRANSFER_EVENT_SIG =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    event LockedERC20(
        address indexed depositor,
        address indexed depositReceiver,
        address indexed rootToken,
        uint256 amount
    );

    event ExitedERC20(
        address indexed exitor,
        address indexed rootToken,
        uint256 amount
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public ERC20(name_, symbol_) {
        _setupDecimals(decimals_);
    }

    function initialize(address _owner) external initializer {
        _setupContractId("ERC20Predicate");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MANAGER_ROLE, _owner);
    }

    /**
     * @notice Lock ERC20 tokens for deposit, callable only by manager
     * @param depositor Address who wants to deposit tokens
     * @param depositReceiver Address (address) who wants to receive tokens on child chain
     * @param rootToken Token which gets deposited
     * @param depositData ABI encoded amount
     */
    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external override only(MANAGER_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        emit LockedERC20(depositor, depositReceiver, rootToken, amount);
        IERC20(rootToken).safeTransferFrom(depositor, address(this), amount);
    }

    /**
     * @notice Sends the correct amount of ERC20Tokens to withdrawer address that locked ERC20Tokens on the rootChain.
     * callable only by manager
     * @param _withdrawer: Root chain Address whose ERC20Tokens were deposited and locked.
     * @param _rootTokenAddress: Root Token address  on Ethereum Chain.
     * @param _tokenAmount: ERC20 Tokens Amount which needs to be unlocked and refunded on the root chain
     */

    function exitTokens(
        address _withdrawer,
        address _rootTokenAddress,
        uint256 _tokenAmount
    ) public override only(MANAGER_ROLE) {
        IERC20(_rootTokenAddress).safeTransfer(_withdrawer, _tokenAmount);

        emit ExitedERC20(_withdrawer, _rootTokenAddress, _tokenAmount);
    }

    function contractBalance() external view override returns (uint256) {
        return address(this).balance;
    }
}
