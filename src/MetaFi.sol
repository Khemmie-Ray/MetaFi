// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";

import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency} from "v4-core/types/Currency.sol";

import {CurrencySettler} from "v4-periphery/lib/v4-core/test/utils/CurrencySettler.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IWETH9} from "v4-periphery/src/interfaces/external/IWETH9.sol";

import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

import {console2} from "forge-std/console2.sol";

contract MetaFi is BaseHook {
    event MessageID(bytes32 data);

    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencySettler for Currency;
    // Use CurrencyLibrary and BalanceDeltaLibrary
    // to add some helper functions over the Currency and BalanceDelta
    // data types
    using CurrencyLibrary for Currency;
    using BalanceDeltaLibrary for BalanceDelta;

    uint64 destinationChainSelector;
    IRouterClient private s_router;
    IERC20 private s_linkToken;
    address payable weth;
    address public receiverContract;

    struct SwapInfo {
        address token;
        uint256 amount;
    }

    struct CallbackData {
        address metaFi;
        PoolKey key;
        IPoolManager.SwapParams params;
        bytes hookData;
    }

    mapping(address => SwapInfo) public pendingTransfers;

    // Initialize BaseHook and ERC20
    constructor(IPoolManager _manager) BaseHook(_manager) {}

    function setters(
        address _router,
        address _link,
        address _weth,
        address _receiverContract,
        uint64 _destinationChainSelector
    ) public {
        s_router = IRouterClient(_router);
        s_linkToken = IERC20(_link);
        weth = payable(_weth);
        receiverContract = _receiverContract;
        destinationChainSelector = _destinationChainSelector;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata swapParams,
        BalanceDelta delta,
        bytes calldata extraData
    ) internal override returns (bytes4, int128) {
        bool stakeOnEigen = abi.decode(extraData, (bool));
        console2.log("maybe");
        if (stakeOnEigen) {
            int256 wethDelta = (Currency.unwrap(key.currency1)) == address(weth) ? delta.amount1() : delta.amount0();
            // if (wethDelta <= 0) return bytes4(0);
            // ccip and stake on Eigen...
            console2.log("wethdelta", IERC20(weth).balanceOf(address(this)));
            Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
                receiverContract,
                address(weth), // native eth....
                uint256(wethDelta),
                abi.encode(msg.sender, wethDelta), // hopefully owner here
                address(0)
            );

            uint256 fees = s_router.getFee(destinationChainSelector, evm2AnyMessage);

            // require(fees > address(this).balance, "NotEnoughBalance(address(this).balance, fees");
            // //    s_linkToken.approve(address(s_router), fees);

            // // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
            IERC20(weth).approve(address(s_router), uint256(wethDelta));
            // IWETH9(weth).withdraw(uint256(wethDelta));
            // // Send the message through the router and store the returned message ID
            // bytes32 messageId = s_router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage);

            // emit MessageID(messageId);
        }
        return (this.afterSwap.selector, 0);
    }

    // function metaFiSwap(PoolKey memory key, IPoolManager.SwapParams memory params, bytes calldata hookData)
    //     external
    //     returns (BalanceDelta swapDelta)
    // {
    //     swapDelta = poolManager.swap(key, params, hookData);

    //     // bool stakeOnEigen = abi.decode(hookData, (bool));
    //     // if (!stakeOnEigen) {
    //     //     if (swapDelta.amount0() > 0) {
    //     //         IERC20(Currency.unwrap(key.currency0)).transfer(msg.sender, uint256(int256(swapDelta.amount0())));
    //     //     }
    //     //     if (swapDelta.amount1() > 0) {
    //     //         IERC20(Currency.unwrap(key.currency1)).transfer(msg.sender, uint256(int256(swapDelta.amount1())));
    //     //     }
    //     // } else {
    //     //     ccip(key);
    //     // }
    // }

    function metaFiSwap(PoolKey memory key, IPoolManager.SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta swapDelta)
    {
        IERC20(Currency.unwrap(params.zeroForOne ? key.currency0 : key.currency1)).transferFrom(
            msg.sender, address(this), uint256(params.amountSpecified)
        );
        // Encode callback data
        bytes memory callbackData = abi.encode(CallbackData(address(this), key, params, hookData));

        // Call `unlock()`, which triggers `unlockCallback()`
        swapDelta = abi.decode(poolManager.unlock(callbackData), (BalanceDelta));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(poolManager), "Only PoolManager can call");

        // Decode the callback data
        CallbackData memory callbackData = abi.decode(data, (CallbackData));

        // Execute the swap inside the callback
        BalanceDelta swapDelta = poolManager.swap(callbackData.key, callbackData.params, callbackData.hookData);
        int256 delta0 = swapDelta.amount0();
        int256 delta1 = swapDelta.amount1();

        if (delta0 < 0) {
            callbackData.key.currency0.settle(poolManager, address(this), uint256(-delta0), false);
        }
        if (delta1 < 0) {
            callbackData.key.currency1.settle(poolManager, address(this), uint256(-delta1), false);
        }

        if (delta0 > 0) {
            callbackData.key.currency0.take(poolManager, address(this), uint256(delta0), false);
        }

        if (delta1 > 0) {
            callbackData.key.currency1.take(poolManager, address(this), uint256(delta1), false);
        }

        return abi.encode(swapDelta);
    }

    // function ccip(PoolKey memory key) internal {
    //     SwapInfo memory info = pendingTransfers[msg.sender];
    //     //   int256 wethDelta = (Currency.unwrap(key.currency1)) == address(weth) ? delta.amount1() : delta.amount0();
    //     // if (wethDelta <= 0) return bytes4(0);
    //     // ccip and stake on Eigen...
    //     console2.log("wethdelta", IERC20(weth).balanceOf(address(this)));
    //     Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
    //         receiverContract,
    //         address(weth), // native eth....
    //         uint256(info.amount),
    //         abi.encode(msg.sender, info.amount), // hopefully owner here
    //         address(0)
    //     );

    //     uint256 fees = s_router.getFee(destinationChainSelector, evm2AnyMessage);

    //     // require(fees > address(this).balance, "NotEnoughBalance(address(this).balance, fees");
    //     // //    s_linkToken.approve(address(s_router), fees);

    //     // // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
    //     IERC20(weth).approve(address(s_router), uint256(info.amount));
    //     // IWETH9(weth).withdraw(uint256(wethDelta));
    //     // // Send the message through the router and store the returned message ID
    //     // bytes32 messageId = s_router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage); uncomment later

    //     // emit MessageID(messageId);
    // }

    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        bytes memory _user_info,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: _token, amount: _amount});

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _user_info, // No data
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and allowing out-of-order execution.
                // Best Practice: For simplicity, the values are hardcoded. It is advisable to use a more dynamic approach
                // where you set the extra arguments off-chain. This allows adaptation depending on the lanes, messages,
                // and ensures compatibility with future CCIP upgrades. Read more about it here: https://docs.chain.link/ccip/best-practices#using-extraargs
                Client.EVMExtraArgsV2({
                    gasLimit: 0, // Gas limit for the callback on the destination chain
                    allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages from the same sender
                })
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
    }

    receive() external payable {}
}
