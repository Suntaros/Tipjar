// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.31;

contract Tips {
    address public owner;
    uint256 public totalShares; // Tracks total percentage (must not exceed 100)

    struct Waitress {
        address payable walletAddress;
        string name;
        uint256 percent;
    }

    // Array to keep the list of waitresses
    Waitress[] public waitresses;

    // Mapping for quick lookup (Gas Saver)
    mapping(address => bool) public isWaitress;
    mapping(address => uint256) private waitressIndex;

    // Events for transparency
    event TipAdded(address indexed from, uint256 amount);
    event WaitressAdded(address indexed wallet, string name, uint256 percent);
    event WaitressRemoved(address indexed wallet);
    event TipsDistributed(uint256 totalAmount, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    // 1. Put fund in smart contract
    function addtips() public payable {
        require(msg.value > 0, "Tip must be greater than 0");
        emit TipAdded(msg.sender, msg.value);
    }

    // 2. View balance
    function viewtips() public view returns (uint256) {
        return address(this).balance;
    }

    // 3. View all waitresses
    function viewWaitress() public view returns (Waitress[] memory) {
        return waitresses;
    }

    // 4. Add Waitress with 100% Limit Logic
    function addWaitress(
        address payable _walletAddress,
        string memory _name,
        uint256 _percent
    ) public onlyOwner {
        require(_walletAddress != address(0), "Invalid address");
        require(_percent > 0, "Percent must be > 0");
        require(!isWaitress[_walletAddress], "Waitress already exists");

        // CHECK: Ensure total never exceeds 100
        require(
            totalShares + _percent <= 100,
            "Total shares cannot exceed 100%"
        );

        waitresses.push(Waitress(_walletAddress, _name, _percent));
        isWaitress[_walletAddress] = true;
        waitressIndex[_walletAddress] = waitresses.length - 1;

        totalShares += _percent;

        emit WaitressAdded(_walletAddress, _name, _percent);
    }

    // 5. Remove Waitress
    function removeWaitress(address _walletAddress) public onlyOwner {
        require(isWaitress[_walletAddress], "Waitress not found");

        uint256 indexToDelete = waitressIndex[_walletAddress];
        uint256 percentToRemove = waitresses[indexToDelete].percent;

        // Update total shares
        if (totalShares >= percentToRemove) {
            totalShares -= percentToRemove;
        }

        // Efficient Array Removal (Swap and Pop)
        // Move the last element into the place of the one to delete
        uint256 lastIndex = waitresses.length - 1;
        Waitress memory lastWaitress = waitresses[lastIndex];

        waitresses[indexToDelete] = lastWaitress;
        waitressIndex[lastWaitress.walletAddress] = indexToDelete;

        // Remove the last element
        waitresses.pop();

        // Clean up mapping
        delete isWaitress[_walletAddress];
        delete waitressIndex[_walletAddress];

        emit WaitressRemoved(_walletAddress);
    }

    // 6. Distribute Balance safely
    function distributeBalance() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        require(currentBalance > 0, "No Money to distribute");
        require(waitresses.length > 0, "No waitresses to pay");

        // Optional: Require strictly 100% allocation before distributing?
        // require(totalShares == 100, "Allocation must equal 100% before distributing");

        for (uint256 i = 0; i < waitresses.length; i++) {
            // Calculate share based on the SNAPSHOT balance (currentBalance)
            // NOT address(this).balance which changes during the loop
            uint256 distributeAmount = (currentBalance *
                waitresses[i].percent) / 100;

            if (distributeAmount > 0) {
                _transferFunds(waitresses[i].walletAddress, distributeAmount);
            }
        }

        emit TipsDistributed(currentBalance, block.timestamp);
    }

    function _transferFunds(
        address payable recipient,
        uint256 amount
    ) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
    }
}
