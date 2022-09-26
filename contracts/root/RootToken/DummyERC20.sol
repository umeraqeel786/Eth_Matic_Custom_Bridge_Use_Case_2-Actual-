// This contract is not supposed to be used in production
// It's strictly for testing purpose

pragma solidity 0.6.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {NativeMetaTransaction} from "../../common/NativeMetaTransaction.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";
import {IRootToken} from "./IRootToken.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";

contract DummyERC20 is ERC20, NativeMetaTransaction, ContextMixin, IRootToken {
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    uint256 private totalSupplyContract;

    constructor(
        string memory name_,
        string memory symbol_,
        // address rootChainManager,
        address rootERC20Predicate_
    ) public ERC20(name_, symbol_) {
        // _setupRole(DEPOSITOR_ROLE, rootChainManager);
        _initializeEIP712(name_);

        totalSupplyContract = 100 * (10**18);
        uint256 amount = 50 * (10**18);
        _mint(address(this), totalSupplyContract);
        _transfer(address(this), _msgSender(), amount);
        _transfer(address(this), rootERC20Predicate_, amount);
    }

    // function mint(uint256 amount) public {
    //     require(amount < totalSupplyContract, "Minting limit reached");
    //     _mint(_msgSender(), amount);
    // }

    function transfer(
        address user,
        bytes calldata depositData,
        address rootERC20Predicate
    ) external override {
        uint256 amount = abi.decode(depositData, (uint256));
        _transfer(rootERC20Predicate, user, amount);
    }

    function _msgSender()
        internal
        view
        override
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
}
