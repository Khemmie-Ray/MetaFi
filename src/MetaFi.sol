// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";

contract MetaFi is BaseHook, ERC20 {
    // Use CurrencyLibrary and BalanceDeltaLibrary
    // to add some helper functions over the Currency and BalanceDelta
    // data types
    using CurrencyLibrary for Currency;
    using BalanceDeltaLibrary for BalanceDelta;

    // Initialize BaseHook and ERC20
    constructor(IPoolManager _manager, string memory _name, string memory _symbol)
        BaseHook(_manager)
        ERC20(_name, _symbol, 18)
    {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterAddLiquidity: true,
            afterRemoveLiquidity: true,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // function beforeAddLiquidity(
    //     address,
    //     PoolKey calldata key,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     bytes calldata
    // ) external override returns (bytes4) {
    //     // beforeAddLiquidityCount[key.toId()]++;
    //     return this.beforeAddLiquidity.selector;
    // }

    // function afterAddLiquidity(
    //     address,
    //     PoolKey calldata key,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     BalanceDelta delta,
    //     BalanceDelta,
    //     bytes calldata hookData
    // ) external override onlyPoolManager returns (bytes4, BalanceDelta) {
    //     // add your logic here
    //     return (this.afterAddLiquidity.selector, delta);
    // }

    // function beforeRemoveLiquidity(
    //     address,
    //     PoolKey calldata key,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     bytes calldata
    // ) external override returns (bytes4) {
    //     // beforeRemoveLiquidityCount[key.toId()]++;
    //     return this.beforeRemoveLiquidity.selector;
    // }

    // function afterRemoveLiquidity(
    //     address,
    //     PoolKey calldata,
    //     IPoolManager.ModifyLiquidityParams calldata,
    //     BalanceDelta delta,
    //     BalanceDelta,
    //     bytes calldata
    // ) external virtual returns (bytes4, BalanceDelta) {
    //     return (this.afterRemoveLiquidity.selector, delta);
    // }
}
