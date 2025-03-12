// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MirageWallet
 * @dev A fully decentralized wallet contract that can receive, store, and send ETH and ERC20 tokens
 * without withdrawal limits
 */
contract MirageWallet is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Events for tracking wallet activity
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event Withdrawal(address indexed recipient, uint256 amount, uint256 balance);
    event TokenDeposit(address indexed token, address indexed sender, uint256 amount);
    event TokenWithdrawal(address indexed token, address indexed recipient, uint256 amount);
    event EmergencyShutdown(bool active);
    event TokensAdded(address[] tokens);
    event TokenRemoved(address indexed token);

    // State variables
    bool public paused;

    // Track supported tokens
    mapping(address => bool) public supportedTokens;
    address[] public tokenList;

    constructor() Ownable(msg.sender) {}

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
     * @dev Withdraw ETH from the wallet
     * @param _amount Amount of ETH to withdraw
     * @param _recipient Address to send ETH to
     */
    function withdraw(uint256 _amount, address payable _recipient) external onlyOwner notPaused nonReentrant {
        require(_amount <= address(this).balance, "Insufficient funds");
        require(_recipient != address(0), "Invalid recipient");

        // Use call instead of transfer for better compatibility
        (bool success,) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(_recipient, _amount, address(this).balance);
    }

    /**
     * @dev Add support for multiple ERC20 tokens
     * @param _tokens Array of ERC20 token addresses to support
     */
    function addSupportedTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(token != address(0), "Invalid token address");

            if (!supportedTokens[token]) {
                supportedTokens[token] = true;
                tokenList.push(token);
            }
        }

        emit TokensAdded(_tokens);
    }

    /**
     * @dev Remove support for an ERC20 token
     * @param _token Address of the ERC20 token to remove
     */
    function removeSupportedToken(address _token) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");

        supportedTokens[_token] = false;

        // Remove from tokenList
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == _token) {
                // Replace with the last element and pop
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                break;
            }
        }

        emit TokenRemoved(_token);
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

        token.safeTransfer(_recipient, _amount);

        emit TokenWithdrawal(_token, _recipient, _amount);
    }

    /**
     * @dev Batch withdraw multiple ERC20 tokens at once
     * @param _tokens Array of ERC20 token addresses
     * @param _amounts Array of amounts to withdraw
     * @param _recipient Address to send tokens to
     */
    function batchWithdrawTokens(address[] calldata _tokens, uint256[] calldata _amounts, address _recipient)
        external
        onlyOwner
        notPaused
        nonReentrant
    {
        require(_tokens.length == _amounts.length, "Arrays length mismatch");
        require(_recipient != address(0), "Invalid recipient");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address tokenAddress = _tokens[i];
            uint256 amount = _amounts[i];

            require(tokenAddress != address(0), "Invalid token address");

            IERC20 token = IERC20(tokenAddress);
            require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");

            token.safeTransfer(_recipient, amount);

            emit TokenWithdrawal(tokenAddress, _recipient, amount);
        }
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
     * @dev Get all supported tokens
     * @return Array of supported token addresses
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return tokenList;
    }

    /**
     * @dev Get balances for all supported tokens
     * @return tokens Array of token addresses
     * @return balances Array of token balances
     */
    function getAllTokenBalances() external view returns (address[] memory tokens, uint256[] memory balances) {
        uint256 length = tokenList.length;
        tokens = new address[](length);
        balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address tokenAddress = tokenList[i];
            tokens[i] = tokenAddress;
            balances[i] = IERC20(tokenAddress).balanceOf(address(this));
        }

        return (tokens, balances);
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

        token.safeTransfer(owner(), balance);
    }
}
