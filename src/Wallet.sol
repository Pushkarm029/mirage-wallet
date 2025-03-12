// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EnhancedWallet
 * @dev A wallet contract that can receive, store, and send ETH and ERC20 tokens
 * with additional security features
 */
contract EnhancedWallet is ReentrancyGuard, Ownable {
    // Events for tracking wallet activity
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event Withdrawal(address indexed recipient, uint256 amount, uint256 balance);
    event TokenWithdrawal(address indexed token, address indexed recipient, uint256 amount);
    event EmergencyShutdown(bool active);
    
    // State variables
    bool public paused;
    uint256 public dailyLimit;
    uint256 public withdrawnToday;
    uint256 public lastWithdrawalDay;
    
    constructor(uint256 _dailyLimit) Ownable(msg.sender) {
        dailyLimit = _dailyLimit;
        lastWithdrawalDay = block.timestamp / 1 days;
    }
    
    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    // Function to receive ETH
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    // Fallback function
    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    /**
     * @dev Reset daily withdrawal limit if it's a new day
     */
    function _resetDailyLimitIfNeeded() internal {
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > lastWithdrawalDay) {
            withdrawnToday = 0;
            lastWithdrawalDay = currentDay;
        }
    }
    
    /**
     * @dev Withdraw ETH from the wallet with daily limit check
     * @param _amount Amount of ETH to withdraw
     * @param _recipient Address to send ETH to
     */
    function withdraw(uint256 _amount, address payable _recipient) 
        external 
        onlyOwner 
        notPaused 
        nonReentrant 
    {
        require(_amount <= address(this).balance, "Insufficient funds");
        require(_recipient != address(0), "Invalid recipient");
        
        // Check daily limit
        _resetDailyLimitIfNeeded();
        require(withdrawnToday + _amount <= dailyLimit, "Daily limit exceeded");
        
        withdrawnToday += _amount;
        
        // Use call instead of transfer for better compatibility
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(_recipient, _amount, address(this).balance);
    }
    
    /**
     * @dev Withdraw ERC20 tokens from the wallet
     * @param _token Address of the ERC20 token
     * @param _amount Amount of tokens to withdraw
     * @param _recipient Address to send tokens to
     */
    function withdrawToken(address _token, uint256 _amount, address _recipient) 
        external 
        onlyOwner 
        notPaused 
        nonReentrant 
    {
        require(_token != address(0), "Invalid token address");
        require(_recipient != address(0), "Invalid recipient");
        
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient token balance");
        
        bool success = token.transfer(_recipient, _amount);
        require(success, "Token transfer failed");
        
        emit TokenWithdrawal(_token, _recipient, _amount);
    }
    
    /**
     * @dev Get the ETH balance of the wallet
     * @return The wallet's ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get the token balance of the wallet
     * @param _token Address of the ERC20 token
     * @return The wallet's token balance
     */
    function getTokenBalance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
    
    /**
     * @dev Set the daily withdrawal limit
     * @param _newLimit New daily withdrawal limit
     */
    function setDailyLimit(uint256 _newLimit) external onlyOwner {
        dailyLimit = _newLimit;
    }
    
    /**
     * @dev Pause or unpause the contract
     * @param _paused New paused state
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit EmergencyShutdown(_paused);
    }
    
    /**
     * @dev Emergency function to recover any ERC20 tokens accidentally sent to the contract
     * @param _token Address of the ERC20 token
     */
    function recoverERC20(address _token) external onlyOwner nonReentrant {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to recover");
        
        bool success = token.transfer(owner(), balance);
        require(success, "Token recovery failed");
    }
} 