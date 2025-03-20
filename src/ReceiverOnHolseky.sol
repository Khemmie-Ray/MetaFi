// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ILido {
    function submit(address _referral) external payable returns (uint256);
    function withdraw(uint256 stETHAmount) external returns (uint256 ethReceived);
}

interface IEigenLayer {
    function deposit(address token, uint256 amount) external;
    function stakedBalance(address staker) external view returns (uint256);
    function withdraw(address token, uint256 shares) external;
    function claimRewards(address token) external returns (uint256 rewardsClaimed);
    function getTotalStaked(address staker) external view returns (uint256);
}

contract HoleskyStaker is CCIPReceiver {
    // mapping(address => uint256) public userBalances;
    ILido public immutable lido;
    IEigenLayer public immutable eigenLayer;
    IWETH public immutable WETH;
    ERC20 public lstToken;

    // Tracks user deposits (ETH → stETH)
    mapping(address => uint256) public userEthDeposit;
    // Tracks user’s shares in stETH (Lido)
    mapping(address => uint256) public userStETHShares;
    // Tracks user’s shares in EigenLayer rewards
    mapping(address => uint256) public userEigenShares;
    // Total shares for Lido staking
    uint256 public totalStETHShares;
    // Total shares for EigenLayer staking
    uint256 public totalEigenShares;

    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, bytes data);

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    // 0xb9531b46fE8808fB3659e39704953c2B1112DD43 router
    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.

    constructor(address router, address _weth, address _lido, address _eigenLayer, address _lstToken)
        CCIPReceiver(router)
    {
        WETH = IWETH(_weth);
        lido = ILido(_lido);
        eigenLayer = IEigenLayer(_eigenLayer);
        lstToken = ERC20(_lstToken);
    }

    /// handle a received message
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        // address sender = abi.decode(any2EvmMessage.data, (address)); // abi-decoding of the sent text
        (address user, uint256 wethAmount) = abi.decode(any2EvmMessage.data, (address, uint256));
        WETH.withdraw(wethAmount);
        uint256 stETHAmount = lido.submit{value: wethAmount}(address(0));

        uint256 stShares =
            (totalStETHShares == 0) ? stETHAmount : (stETHAmount * totalStETHShares) / lstToken.balanceOf(address(this));
        userStETHShares[user] += stShares;
        totalStETHShares += stShares;
        // Stake stETH on EigenLayer
        eigenLayer.deposit(address(lido), stETHAmount);

        uint256 eigenShares = (totalEigenShares == 0)
            ? stETHAmount
            : (stETHAmount * totalEigenShares) / eigenLayer.stakedBalance(address(this));
        userEigenShares[user] += eigenShares;
        totalEigenShares += eigenShares;

        userEthDeposit[user] += stShares;
        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            any2EvmMessage.data
        );
    }

    function withdrawLido(uint256 amount) public {
        require(userEthDeposit[msg.sender] >= amount, "Insufficient deposit");

        uint256 userShares = userStETHShares[msg.sender];
        uint256 totalShares = totalStETHShares;

        uint256 withdrawableStETH = (amount * totalShares) / userShares;

        require(withdrawableStETH > 0, "Nothing to withdraw");

        // Unstake stETH and convert back to ETH
        uint256 ethReceived = lido.withdraw(withdrawableStETH);

        // Update user balances
        userEthDeposit[msg.sender] -= amount;
        userStETHShares[msg.sender] -= withdrawableStETH;
        totalStETHShares -= withdrawableStETH;

        // Send ETH back to user
        payable(msg.sender).transfer(ethReceived);
    }

    function withdrawLidoRewards() public {
        uint256 rewards = getUserLidoRewards(msg.sender);
        require(rewards > 0, "No rewards available");

        userStETHShares[msg.sender] -= rewards;
        totalStETHShares -= rewards;

        // Transfer rewards as stETH
        lstToken.transfer(msg.sender, rewards);
    }

    function withdrawEigen(uint256 shares) public {
        require(userEigenShares[msg.sender] >= shares, "Insufficient shares");

        uint256 withdrawableStETH = (shares * totalEigenShares) / userEigenShares[msg.sender];

        require(withdrawableStETH > 0, "Nothing to withdraw");

        // Withdraw stETH from EigenLayer
        eigenLayer.withdraw(address(lstToken), shares);

        // Convert stETH to ETH
        uint256 ethReceived = lido.withdraw(withdrawableStETH);

        // Update balances
        userEigenShares[msg.sender] -= shares;
        totalEigenShares -= shares;

        // Send ETH to user
        payable(msg.sender).transfer(ethReceived);
    }

    function withdrawEigenRewards() public {
        uint256 rewards = getUserEigenRewards(msg.sender);
        require(rewards > 0, "No rewards available");

        // Claim rewards from EigenLayer as stETH
        uint256 stETHRewards = eigenLayer.claimRewards(address(lstToken));

        userEigenShares[msg.sender] -= stETHRewards;
        totalEigenShares -= stETHRewards;

        // Transfer rewards as stETH
        lstToken.transfer(msg.sender, stETHRewards);
    }

    function withdrawFromEigenAndLido() public {
        withdrawEigenRewards();
        withdrawLidoRewards();
    }

    function getUserLidoRewards(address user) public view returns (uint256) {
        uint256 totalStETH = lstToken.balanceOf(address(this));
        uint256 userShares = userStETHShares[user];

        return (userShares * totalStETH) / totalStETHShares;
    }

    function getUserEigenRewards(address user) public view returns (uint256) {
        uint256 totalEigenAssets = eigenLayer.getTotalStaked(address(this)); // Contract's total assets
        uint256 userShares = userEigenShares[user];

        if (totalEigenShares == 0 || userShares == 0) {
            return 0; // Avoid division by zero
        }

        return (userShares * totalEigenAssets) / totalEigenShares;
    }
}
