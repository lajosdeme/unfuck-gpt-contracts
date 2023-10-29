// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/* 
Chain ID 4: BSC Testnet 0x80aC94316391752A193C1c47E27D382b507c93F3
Chain ID 5: Polygon Testnet 0x0591C25ebd0580E0d4F27A82Fc2e24E7489CB5e0
Chain ID 6: Avalanche Testnet (Fuji) 0xA3cF45939bD6260bcFe3D66bc73d60f19e49a8BB
Chain ID 14: Celo Testnet: 0x306B68267Deb7c5DfCDa3619E22E9Ca39C374f84
Chain ID 16: Moonbeam Testnet 0x0591C25ebd0580E0d4F27A82Fc2e24E7489CB5e0
 */

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract UnfuckGPTMembership is ERC721, ReentrancyGuard, Ownable {
    uint256 constant GAS_LIMIT = 500_000;
    uint16 public HOST_CHAIN = 5;
    address public unfuckGPT;
    IWormholeRelayer public wormholeRelayer;

    uint256 public mintPrice = 0.001 ether;

    uint256 tokenCount;

    constructor(
        address _wormholeRelayer,
        address _unfuckGPT
    ) ERC721("Unfuck GPT Membership NFT", "!fck") {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        unfuckGPT = _unfuckGPT;
    }

    function mint() payable external nonReentrant {
        uint256 cost = getQuote();
        require(msg.value == mintPrice + cost, "not enough money sent");

        tokenCount++;
        _safeMint(msg.sender, tokenCount);
    }

 
 function _afterTokenTransfer(address from, address to, uint256 /* firstTokenId */, uint256 /* batchSize */) internal virtual override {
        sendMembershipChangeMsg(from, to);
     } 


    function getQuote() public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            HOST_CHAIN,
            0,
            GAS_LIMIT
        );
    }

    function sendMembershipChangeMsg(address from, address to) internal {
        uint256 cost = getQuote();

        bytes memory payload = abi.encode(from, to);
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            HOST_CHAIN,
            unfuckGPT,
            payload,
            0,
            GAS_LIMIT,
            HOST_CHAIN,
            to
        );
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}
