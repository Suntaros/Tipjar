// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.31;

contract tips {

    address owner;

    // 3.1 Structure for a Waitress
    struct Waitress {
        address payable walletAddress;
        string name;
        uint percent;
    }

    // List of all waitresses
    Waitress[] public waitress;

    constructor() {
        owner = msg.sender;
    }

    // 1. Put fund in smart contract
    function addtips() payable public {}

    // 2. View balance
    function viewtips() public view returns(uint) {
        return address(this).balance;
    }

    // 5. View waitress
    function viewWaitress() public view returns (Waitress[] memory) {
        return waitress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    function addWaitress(
        address payable walletAddress,
        string memory name,
        uint percent
    ) public onlyOwner {

        bool waitressExist = false;

        if (waitress.length >= 1) {
            // Check Logic
             for(uint i=0; i<waitress.length; i++){
               if(waitress[i].walletAddress == walletAddress){
                waitressExist = true;
               } 
            }
        }

        if (!waitressExist) {
            waitress.push(
                Waitress(walletAddress, name, percent)
            );
        }
    }
}