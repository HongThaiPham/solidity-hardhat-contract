//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

contract ContractV2 is Initializable {
    string private greeting;
    uint256 private updateTimestamp;

    function initialize(string memory _greeting) public initializer {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
        updateTimestamp = block.timestamp;
    }

    function greet() public view returns (string memory, uint256) {
        return (greeting, updateTimestamp);
    }

    function setGreeting(string memory _greeting) public {
        console.log(
            "Changing greeting from '%s' to '%s' at '%s'",
            greeting,
            _greeting,
            block.timestamp
        );
        greeting = _greeting;
        updateTimestamp = block.timestamp;
    }
}
