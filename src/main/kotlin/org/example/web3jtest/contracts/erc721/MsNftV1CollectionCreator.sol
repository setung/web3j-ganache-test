// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../openzeppelin/contracts/access/Ownable.sol";
import "./MsNftV1Collection.sol";

contract MsNftV1CollectionCreator is Ownable{

    event DeployContract(address from, address contractAddress);
    
    constructor() Ownable(msg.sender){} 
 
    function deployContract(string memory name, string memory symbol) public onlyOwner returns(address) {
        address contractAddress = address(new MsNftV1Collection(owner(), name, symbol));
        emit DeployContract(owner(), contractAddress);
        return contractAddress;
    }
    
}
