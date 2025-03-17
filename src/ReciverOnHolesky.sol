import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

interface IEigenLayer {
    function deposit(address token, uint256 amount) external;
}

contract HoleskyStaker is CCIPReceiver {
    // mapping(address => uint256) public userBalances;
    address public immutable lido;
    address public immutable eigenLayer;
    IWETH public immutable WETH;

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

    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router, address _weth, address _lido, address _eigenLayer) CCIPReceiver(router) {
        WETH = IWETH(_weth);
        lido = _lido;
        eigenLayer = _eigenLayer;
    }

    /// handle a received message
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        // address sender = abi.decode(any2EvmMessage.data, (address)); // abi-decoding of the sent text
        (address user, uint256 wethAmount) = abi.decode(any2EvmMessage.data, (address, uint256));
        WETH.withdraw(wethAmount);
        uint256 stETHAmount = lido.submit{value: wethAmount}(address(0));

        uint256 stShares =
            (totalStETHShares == 0) ? stETHAmount : (stETHAmount * totalStETHShares) / lido.balanceOf(address(this));
        userStETHShares[user] += stShares;
        totalStETHShares += stShares;
        // Stake stETH on EigenLayer
        EigenLayer.deposit(address(Lido), stETHAmount);

        uint256 eigenShares = (totalEigenShares == 0)
            ? stETHAmount
            : (stETHAmount * totalEigenShares) / eigenLayer.getStakedAmount(address(this));
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

    function withdrawLidoRewards() external {
        uint256 rewards = getUserLidoRewards(msg.sender) - userEthDeposit[msg.sender];
        require(rewards > 0, "No rewards available");

        userStETHShares[msg.sender] -= rewards;
        totalStETHShares -= rewards;

        lido.transfer(msg.sender, rewards);
    }

    function withdrawEigenRewards() external {
        uint256 rewards = getUserEigenRewards(msg.sender);
        require(rewards > 0, "No rewards available");

        userEigenShares[msg.sender] -= rewards;
        totalEigenShares -= rewards;

        eigenLayer.withdrawRewards(msg.sender, rewards);
    }

    function withdrawFromEigenAndLido() {
        withdrawEigenRewards();
        withdrawLidoRewards();
    }

    function getUserLidoRewards(address user) public view returns (uint256) {
        uint256 totalStETH = lido.balanceOf(address(this));
        uint256 userShares = userStETHShares[user];

        return (userShares * totalStETH) / totalStETHShares;
    }

    function getUserEigenRewards(address user) public view returns (uint256) {
        uint256 totalEigenRewards = eigenLayer.getRewards(address(this));
        uint256 userShares = userEigenShares[user];

        return (userShares * totalEigenRewards) / totalEigenShares;
    }

    // function ccipReceive(bytes calldata message) external override {
    //     (address user, uint256 wethAmount) = abi.decode(message, (address, uint256));

    //     // Convert WETH to ETH
    //     WETH.withdraw(wethAmount);

    //     // Stake ETH on Lido
    //     uint256 stETHAmount = Lido.submit{value: wethAmount}(address(0));

    //     // Stake stETH on EigenLayer
    //     EigenLayer.deposit(address(Lido), stETHAmount);

    //     // Track user balance
    //     userBalances[user] += stETHAmount;
    // }
}
