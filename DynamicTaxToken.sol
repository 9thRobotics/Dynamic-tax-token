// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicTaxToken is ReentrancyGuard {
    string public name = "DynamicTaxToken";
    string public symbol = "DTT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**uint256(decimals);
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public isExcludedFromLimits;

    uint256 public buyTax = 3; // 3% for buys
    uint256 public sellTax = 5; // 5% for sells
    address public taxWallet;

    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier dynamicTax(address sender, address recipient, uint256 amount) {
        uint256 tax = 0;
        if (!isExcludedFromLimits[sender] && !isExcludedFromLimits[recipient]) {
            if (recipient == address(this)) {
                tax = (amount * sellTax) / 100;
            } else {
                tax = (amount * buyTax) / 100;
            }
            balanceOf[taxWallet] += tax;
            amount -= tax;
        }
        _;
    }

    constructor(address _taxWallet) {
        owner = msg.sender;
        taxWallet = _taxWallet;
        balanceOf[owner] = totalSupply;
        isExcludedFromLimits[owner] = true;
        isExcludedFromLimits[_taxWallet] = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        dynamicTax(msg.sender, recipient, amount)
        nonReentrant
        returns (bool)
    {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function setBuyTax(uint256 _buyTax) external onlyOwner {
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        sellTax = _sellTax;
    }

    function setTaxWallet(address _taxWallet) external onlyOwner {
        taxWallet = _taxWallet;
    }

    function excludeFromLimits(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
    }
}
