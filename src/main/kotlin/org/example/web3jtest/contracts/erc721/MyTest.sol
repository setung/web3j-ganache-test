// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../openzeppelin/contracts/access/Ownable.sol";

contract MyTest is Ownable{

    constructor() Ownable(msg.sender){}

    string name;
    
    function getName() public view returns(string memory) {
        return name;
    }

    function setName(string memory _name) public {
        name = _name;
    }
    
}

