// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoHeroes is ERC20, Ownable {
    constructor() ERC20("CryptoHeroes", "Heroes") {
        // _mint(msg.sender, 100000 * 10**decimals());
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
