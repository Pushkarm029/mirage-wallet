// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BasicWallet
 * @dev A simple wallet contract that can receive, store, and send ETH
 */
contract BasicWallet {
    address public owner;
    
    // Events for tracking wallet activity
    event Deposit(address indexed sender, uint amount, uint balance);
    event Withdrawal(address indexed recipient, uint amount, uint balance);
    event Transfer(address indexed recipient, uint amount);
    
    // Set the contract creator as the owner
    constructor() {
        owner = msg.sender;
    }
    
    // Modifier to restrict functions to the wallet owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    // Function to receive ETH
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    // Fallback function in case someone sends ETH to a non-existent function
    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    /**
     * @dev Withdraw ETH from the wallet
     * @param _amount Amount of ETH to withdraw
     * @param _recipient Address to send ETH to
     */
    function withdraw(uint _amount, address payable _recipient) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient funds");
        
        _recipient.transfer(_amount);
        emit Withdrawal(_recipient, _amount, address(this).balance);
    }
    
    /**
     * @dev Get the ETH balance of the wallet
     * @return The wallet's ETH balance
     */
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfer ownership of the wallet
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
    }
}