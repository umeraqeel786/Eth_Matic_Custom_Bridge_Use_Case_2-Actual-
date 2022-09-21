pragma solidity 0.6.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IRootChainManager} from "./IRootChainManager.sol";
import {RootChainManagerStorage} from "./RootChainManagerStorage.sol";
import {IStateSender} from "../StateSender/IStateSender.sol";
import {ICheckpointManager} from "../ICheckpointManager.sol";
import {RLPReader} from "../../lib/RLPReader.sol";
import {ExitPayloadReader} from "../../lib/ExitPayloadReader.sol";
import {MerklePatriciaProof} from "../../lib/MerklePatriciaProof.sol";
import {Merkle} from "../../lib/Merkle.sol";
import {ITokenPredicate} from "../TokenPredicates/ITokenPredicate.sol";
import {Initializable} from "../../common/Initializable.sol";
import {NativeMetaTransaction} from "../../common/NativeMetaTransaction.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";

contract RootChainManager is
    IRootChainManager,
    Initializable,
    AccessControl, // included to match old storage layout while upgrading
    RootChainManagerStorage, // created to match old storage layout while upgrading
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    using Merkle for bytes32;
    using SafeMath for uint256;

    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");
    address public constant ETHER_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bytes32 public constant MAPPER_ROLE = keccak256("MAPPER_ROLE");

    function _msgSender()
        internal
        view
        override
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @notice Deposit ether by directly sending to the contract
     * The account sending ether receives WETH on child chain
     */
    receive() external payable {
        _depositEtherFor(_msgSender());
    }

    /**
     * @notice Initialize the contract after it has been proxified
     * @dev meant to be called once immediately after deployment
     * @param _owner the account that should be granted admin role
     */
    function initialize(address _owner) external initializer {
        _initializeEIP712("RootChainManager");
        _setupContractId("RootChainManager");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MAPPER_ROLE, _owner);
    }

    // adding seperate function setupContractId since initialize is already called with old implementation
    function setupContractId() external only(DEFAULT_ADMIN_ROLE) {
        _setupContractId("RootChainManager");
    }

    // adding seperate function initializeEIP712 since initialize is already called with old implementation
    function initializeEIP712() external only(DEFAULT_ADMIN_ROLE) {
        _setDomainSeperator("RootChainManager");
    }

    /**
     * @notice Set the state sender, callable only by admins
     * @dev This should be the state sender from plasma contracts
     * It is used to send bytes from root to child chain
     * @param newStateSender address of state sender contract
     */
    function setStateSender(address newStateSender)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        require(
            newStateSender != address(0),
            "RootChainManager: BAD_NEW_STATE_SENDER"
        );
        _stateSender = IStateSender(newStateSender);
    }

    /**
     * @notice Get the address of contract set as state sender
     * @return The address of state sender contract
     */
    function stateSenderAddress() external view returns (address) {
        return address(_stateSender);
    }

    /**
     * @notice Set the checkpoint manager, callable only by admins
     * @dev This should be the plasma contract responsible for keeping track of checkpoints
     * @param newCheckpointManager address of checkpoint manager contract
     */
    function setCheckpointManager(address newCheckpointManager)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        require(
            newCheckpointManager != address(0),
            "RootChainManager: BAD_NEW_CHECKPOINT_MANAGER"
        );
        _checkpointManager = ICheckpointManager(newCheckpointManager);
    }

    /**
     * @notice Get the address of contract set as checkpoint manager
     * @return The address of checkpoint manager contract
     */
    function checkpointManagerAddress() external view returns (address) {
        return address(_checkpointManager);
    }

    /**
     * @notice Set the child chain manager, callable only by admins
     * @dev This should be the contract responsible to receive deposit bytes on child chain
     * @param newChildChainManager address of child chain manager contract
     */
    function setChildChainManagerAddress(address newChildChainManager)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        require(
            newChildChainManager != address(0x0),
            "RootChainManager: INVALID_CHILD_CHAIN_ADDRESS"
        );
        childChainManagerAddress = newChildChainManager;
    }

    /**
     * @notice Register a token predicate address against its type, callable only by ADMIN
     * @dev A predicate is a contract responsible to process the token specific logic while locking or exiting tokens
     * @param tokenType bytes32 unique identifier for the token type
     * @param predicateAddress address of token predicate address
     */
    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external
        override
        only(DEFAULT_ADMIN_ROLE)
    {
        typeToPredicate[tokenType] = predicateAddress;
        emit PredicateRegistered(tokenType, predicateAddress);
    }

    /**
     * @notice Map a token to enable its movement via the PoS Portal, callable only by mappers
     * @param rootToken address of token on root chain
     * @param childToken address of token on child chain
     * @param tokenType bytes32 unique identifier for the token type
     */
    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external override only(MAPPER_ROLE) {
        // explicit check if token is already mapped to avoid accidental remaps
        require(
            rootToChildToken[rootToken] == address(0) &&
                childToRootToken[childToken] == address(0),
            "RootChainManager: ALREADY_MAPPED"
        );
        _mapToken(rootToken, childToken, tokenType);
    }

    /**
     * @notice Clean polluted token mapping
     * @param rootToken address of token on root chain. Since rename token was introduced later stage,
     * clean method is used to clean pollulated mapping
     */
    function cleanMapToken(address rootToken, address childToken)
        external
        override
        only(DEFAULT_ADMIN_ROLE)
    {
        rootToChildToken[rootToken] = address(0);
        childToRootToken[childToken] = address(0);
        tokenToType[rootToken] = bytes32(0);

        emit TokenMapped(rootToken, childToken, tokenToType[rootToken]);
    }

    /**
     * @notice Remap a token that has already been mapped, properly cleans up old mapping
     * Callable only by ADMIN
     * @param rootToken address of token on root chain
     * @param childToken address of token on child chain
     * @param tokenType bytes32 unique identifier for the token type
     */
    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external override only(DEFAULT_ADMIN_ROLE) {
        // cleanup old mapping
        address oldChildToken = rootToChildToken[rootToken];
        address oldRootToken = childToRootToken[childToken];

        if (rootToChildToken[oldRootToken] != address(0)) {
            rootToChildToken[oldRootToken] = address(0);
            tokenToType[oldRootToken] = bytes32(0);
        }

        if (childToRootToken[oldChildToken] != address(0)) {
            childToRootToken[oldChildToken] = address(0);
        }

        _mapToken(rootToken, childToken, tokenType);
    }

    function _mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) private {
        require(
            typeToPredicate[tokenType] != address(0x0),
            "RootChainManager: TOKEN_TYPE_NOT_SUPPORTED"
        );

        rootToChildToken[rootToken] = childToken;
        childToRootToken[childToken] = rootToken;
        tokenToType[rootToken] = tokenType;

        emit TokenMapped(rootToken, childToken, tokenType);

        bytes memory syncData = abi.encode(rootToken, childToken, tokenType);
        _stateSender.syncState(
            childChainManagerAddress,
            abi.encode(MAP_TOKEN, syncData)
        );
    }

    /**
     * @notice Move ether from root to child chain, accepts ether transfer
     * Keep in mind this ether cannot be used to pay gas on child chain
     * Use Matic tokens deposited using plasma mechanism for that
     * @param user address of account that should receive WETH on child chain
     */
    function depositEtherFor(address user) external payable override {
        _depositEtherFor(user);
    }

    /**
     * @notice Move tokens from root to child chain
     * @dev This mechanism supports arbitrary tokens as long as its predicate has been registered and the token is mapped
     * @param user address of account that should receive this deposit on child chain
     * @param rootToken address of token that is being deposited
     * @param depositData bytes data that is sent to predicate and child token contracts to handle deposit
     */
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external override {
        require(
            rootToken != ETHER_ADDRESS,
            "RootChainManager: INVALID_ROOT_TOKEN"
        );
        _depositFor(user, rootToken, depositData);
    }

    function _depositEtherFor(address user) private {
        bytes memory depositData = abi.encode(msg.value);
        _depositFor(user, ETHER_ADDRESS, depositData);

        // payable(typeToPredicate[tokenToType[ETHER_ADDRESS]]).transfer(msg.value);
        // transfer doesn't work as expected when receiving contract is proxified so using call
        (
            bool success, /* bytes memory data */

        ) = typeToPredicate[tokenToType[ETHER_ADDRESS]].call{value: msg.value}(
                ""
            );
        if (!success) {
            revert("RootChainManager: ETHER_TRANSFER_FAILED");
        }
    }

    function _depositFor(
        address user,
        address rootToken,
        bytes memory depositData
    ) private {
        bytes32 tokenType = tokenToType[rootToken];
        require(
            rootToChildToken[rootToken] != address(0x0) && tokenType != 0,
            "RootChainManager: TOKEN_NOT_MAPPED"
        );
        address predicateAddress = typeToPredicate[tokenType];
        require(
            predicateAddress != address(0),
            "RootChainManager: INVALID_TOKEN_TYPE"
        );
        require(user != address(0), "RootChainManager: INVALID_USER");

        ITokenPredicate(predicateAddress).lockTokens(
            _msgSender(),
            user,
            rootToken,
            depositData
        );
        bytes memory syncData = abi.encode(user, rootToken, depositData);
        _stateSender.syncState(
            childChainManagerAddress,
            abi.encode(DEPOSIT, syncData)
        );
    }

    /**
     * @notice exit tokens by providing ERC20Predicate address,Root Token address and ERC20Token Amount which needs to be released by the ERC20Predicate
     * @dev This function releases the ERC20 Tokens that where locked in by ERC20Predicate contract when RootchainManagers depositFor() was called.
     * callable only by default admin
     * @param _predicateAddress: ERC20Predicate address which locked the tokens
     * @param _rootTokenAddress: Root Token address  on Ethereum Chain.
     * @param _tokenAmount: ERC20 Tokens Amount which needs to be unlocked and refunded on the root chain
     */

    function exit(
        address _predicateAddress,
        address _rootTokenAddress,
        uint256 _tokenAmount
    ) external override only(DEFAULT_ADMIN_ROLE) {
        // address rootToken = childToRootToken[log.getEmitter()];
        // require(rootToken != address(0), "RootChainManager: TOKEN_NOT_MAPPED");
        // address predicateAddress = typeToPredicate[tokenToType[rootToken]];

        ITokenPredicate(_predicateAddress).exitTokens(
            _msgSender(),
            _rootTokenAddress,
            _tokenAmount
        );
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view returns (uint256) {
        (
            bytes32 headerRoot,
            uint256 startBlock,
            ,
            uint256 createdAt,

        ) = _checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(
                abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)
            ).checkMembership(
                    blockNumber.sub(startBlock),
                    headerRoot,
                    blockProof
                ),
            "RootChainManager: INVALID_HEADER"
        );
        return createdAt;
    }
}
