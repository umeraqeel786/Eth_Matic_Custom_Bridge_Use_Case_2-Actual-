pragma solidity 0.6.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IChildChainManager} from "./IChildChainManager.sol";
import {IChildToken} from "../ChildToken/IChildToken.sol";
import {Initializable} from "../../common/Initializable.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";
import {IStateReceiver} from "../IStateReceiver.sol";
import {ITokenPredicate} from "../TokenPredicates/ITokenPredicate.sol";
import {ChildChainManagerStorage} from "./ChildChainManagerStorage.sol";
import {IStateSender} from "../StateSender/IStateSender.sol";
import {ICheckpointManager} from "../ICheckpointManager.sol";

contract ChildChainManager is
    IChildChainManager,
    Initializable,
    AccessControlMixin,
    IStateReceiver,
    ChildChainManagerStorage
{
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");
    bytes32 public constant MAPPER_ROLE = keccak256("MAPPER_ROLE");
    bytes32 public constant STATE_SYNCER_ROLE = keccak256("STATE_SYNCER_ROLE");
    address public constant ETHER_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // mapping(address => address) public rootToChildToken;

    // mapping(address => address) public childToRootToken;

    function initialize(address _owner) external initializer {
        _setupContractId("ChildChainManager");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(MAPPER_ROLE, _owner);
        _setupRole(STATE_SYNCER_ROLE, _owner);
    }

    /**
     * @notice Map a token to enable its movement via the PoS Portal, callable only by mappers
     * Normally mapping should happen automatically using state sync
     * This function should be used only while initial deployment when state sync is not registrered or if it fails
     * @param rootToken address of token on root chain
     * @param childToken address of token on child chain
     */
    function mapToken(address rootToken, address childToken)
        external
        override
        only(MAPPER_ROLE)
    {
        _mapToken(rootToken, childToken);
    }

    /**
     * @notice Receive state sync data from root chain, only callable by state syncer
     * @dev state syncing mechanism is used for both depositing tokens and mapping them
     * @param data bytes data from RootChainManager contract
     * `data` is made up of bytes32 `syncType` and bytes `syncData`
     * `syncType` determines if it is deposit or token mapping
     * in case of token mapping, `syncData` is encoded address `rootToken`, address `childToken` and bytes32 `tokenType`
     * in case of deposit, `syncData` is encoded address `user`, address `rootToken` and bytes `depositData`
     * `depositData` is token specific data (amount in case of ERC20). It is passed as is to child token
     */
    function onStateReceive(
        uint256,
        bytes calldata data,
        address childERC20Predicate
    ) external override only(STATE_SYNCER_ROLE) {
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            data,
            (bytes32, bytes)
        );

        if (syncType == DEPOSIT) {
            _syncDeposit(syncData, childERC20Predicate);
        } else if (syncType == MAP_TOKEN) {
            (address rootToken, address childToken, ) = abi.decode(
                syncData,
                (address, address, bytes32)
            );
            _mapToken(rootToken, childToken);
        } else {
            revert("ChildChainManager: INVALID_SYNC_TYPE");
        }
    }

    /**
     * @notice Clean polluted token mapping
     * @param rootToken address of token on root chain. Since rename token was introduced later stage,
     * clean method is used to clean pollulated mapping
     */
    function cleanMapToken(address rootToken, address childToken)
        external
        override
        only(MAPPER_ROLE)
    {
        rootToChildToken[rootToken] = address(0);
        childToRootToken[childToken] = address(0);

        emit TokenMapped(rootToken, childToken);
    }

    function _mapToken(address rootToken, address childToken) private {
        address oldChildToken = rootToChildToken[rootToken];
        address oldRootToken = childToRootToken[childToken];

        if (rootToChildToken[oldRootToken] != address(0)) {
            rootToChildToken[oldRootToken] = address(0);
        }

        if (childToRootToken[oldChildToken] != address(0)) {
            childToRootToken[oldChildToken] = address(0);
        }

        rootToChildToken[rootToken] = childToken;
        childToRootToken[childToken] = rootToken;

        emit TokenMapped(rootToken, childToken);
    }

    function _syncDeposit(bytes memory syncData, address childERC20Predicate)
        private
    {
        (address user, address rootToken, bytes memory depositData) = abi
            .decode(syncData, (address, address, bytes));
        address childTokenAddress = rootToChildToken[rootToken];
        require(
            childTokenAddress != address(0x0),
            "ChildChainManager: TOKEN_NOT_MAPPED"
        );
        require(
            childERC20Predicate != address(0x0),
            "ChildChainManager: INVALID_CHILD_PREDICATE"
        );

        IChildToken childTokenContract = IChildToken(childTokenAddress);
        childTokenContract.transfer(user, depositData, childERC20Predicate);
    }

    function depositFor(
        address user,
        address childToken,
        bytes calldata depositData,
        address rootERC20Predicate
    ) external override {
        require(
            childToken != ETHER_ADDRESS,
            "ChildChainManager: INVALID_CHILD_TOKEN"
        );
        _depositFor(user, childToken, depositData, rootERC20Predicate);
    }

    function _depositFor(
        address user,
        address childToken,
        bytes memory depositData,
        address rootERC20Predicate
    ) private {
        bytes32 tokenType = tokenToType[childToken];
        require(
            childToRootToken[childToken] != address(0x0) && tokenType != 0,
            "ChildChainManager: TOKEN_NOT_MAPPED"
        );
        address predicateAddress = typeToPredicate[tokenType];
        require(
            predicateAddress != address(0),
            "ChildChainManager: INVALID_TOKEN_TYPE"
        );
        require(
            rootERC20Predicate != address(0),
            "ChildChainManager: INVALID_ROOT_PREDICATE"
        );
        require(user != address(0), "ChildChainManager: INVALID_USER");

        ITokenPredicate(predicateAddress).lockTokens(
            _msgSender(),
            user,
            childToken,
            depositData
        );
        bytes memory syncData = abi.encode(user, childToken, depositData);
        _stateSender.syncStateU2(
            rootChainManagerAddress,
            rootERC20Predicate,
            abi.encode(DEPOSIT, syncData)
        );
    }

    function setRootChainManagerAddress(address newRootChainManager)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        require(
            newRootChainManager != address(0x0),
            "ChildChainManager: INVALID_ROOT_CHAIN_ADDRESS"
        );
        rootChainManagerAddress = newRootChainManager;
    }

    function setStateSender(address newStateSender)
        external
        only(DEFAULT_ADMIN_ROLE)
    {
        require(
            newStateSender != address(0),
            "ChildChainManager: BAD_NEW_STATE_SENDER"
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
            "ChildChainManager: BAD_NEW_CHECKPOINT_MANAGER"
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

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external
        override
        only(DEFAULT_ADMIN_ROLE)
    {
        typeToPredicate[tokenType] = predicateAddress;
        emit PredicateRegistered(tokenType, predicateAddress);
    }

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external override only(MAPPER_ROLE) {
        // explicit check if token is already mapped to avoid accidental remaps
        require(
            rootToChildToken[rootToken] == address(0) &&
                childToRootToken[childToken] == address(0),
            "ChildChainManager: ALREADY_MAPPED"
        );
        _mapToken(rootToken, childToken, tokenType);
    }

    function _mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) private {
        require(
            typeToPredicate[tokenType] != address(0x0),
            "ChildChainManager: TOKEN_TYPE_NOT_SUPPORTED"
        );

        rootToChildToken[rootToken] = childToken;
        childToRootToken[childToken] = rootToken;
        tokenToType[childToken] = tokenType;

        emit TokenMapped(rootToken, childToken, tokenType);

        bytes memory syncData = abi.encode(rootToken, childToken, tokenType);
        _stateSender.syncState(
            rootChainManagerAddress,
            abi.encode(MAP_TOKEN, syncData)
        );
    }

    function exit(
        address _predicateAddress,
        address _childTokenAddress,
        uint256 _tokenAmount
    ) external override only(DEFAULT_ADMIN_ROLE) {
        // address rootToken = childToRootToken[log.getEmitter()];
        // require(rootToken != address(0), "RootChainManager: TOKEN_NOT_MAPPED");
        // address predicateAddress = typeToPredicate[tokenToType[rootToken]];

        ITokenPredicate(_predicateAddress).exitTokens(
            _msgSender(),
            _childTokenAddress,
            _tokenAmount
        );
    }
}
