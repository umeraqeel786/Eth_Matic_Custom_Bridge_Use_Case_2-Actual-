// This contract is not supposed to be used in production
// It's strictly for testing purpose

pragma solidity 0.6.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {NativeMetaTransaction} from "../../common/NativeMetaTransaction.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";

contract DummyERC20 is ERC20, NativeMetaTransaction, ContextMixin {
    uint256 private totalSupplyContract;

    constructor(string memory name_, string memory symbol_)
        public
        ERC20(name_, symbol_)
    {
        totalSupplyContract = 100 * (10**18);
        uint256 amount = 50 * (10**18);
        _mint(address(this), totalSupplyContract);
        _transfer(address(this), _msgSender(), amount);
        _initializeEIP712(name_);
    }

    function mint(uint256 amount) public {
        require(amount < totalSupplyContract, "Minting limit reached");
        _mint(_msgSender(), amount);
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
