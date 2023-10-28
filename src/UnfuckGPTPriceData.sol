// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@flarenetwork/flare-periphery-contracts/coston2/util-contracts/userInterfaces/IFlareContractRegistry.sol";
import "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFtsoRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* 
Supported symbols: 
[( XRP), (LTC), (XLM), (DOGE), (ADA), (ALGO), (BTC), (ETH), (FIL), (FLR), (ARB), (AVAX), (BNB), (MATIC), (SOL), (USDC), (USDT), (XDC)]
 */
contract UnfuckGPTPriceData is Ownable {
    address private constant FLARE_CONTRACT_REGISTRY =
        0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019;

    IFlareContractRegistry contractRegistry =
        IFlareContractRegistry(FLARE_CONTRACT_REGISTRY);

    IFtsoRegistry.PriceInfo[] public currentPriceInfo;

    constructor() Ownable(msg.sender) {}

    function refreshPrices() external onlyOwner {
        IFtsoRegistry ftsoRegistry = IFtsoRegistry(
            contractRegistry.getContractAddressByName("FtsoRegistry")
        );

        IFtsoRegistry.PriceInfo[] memory _priceInfos = ftsoRegistry
            .getAllCurrentPrices();

        for (uint256 i = 0; i < _priceInfos.length; i++) {
            currentPriceInfo[i] = _priceInfos[i];
        }
    }

    function priceInfosLength() external view returns (uint256) {
        return currentPriceInfo.length;
    }

    function latestPriceForToken(
        string memory _symbol
    ) external view returns (IFtsoRegistry.PriceInfo memory) {
         IFtsoRegistry ftsoRegistry = IFtsoRegistry(
            contractRegistry.getContractAddressByName("FtsoRegistry")
        );
        uint256 _idx = ftsoRegistry.getFtsoIndex(_symbol);
        return currentPriceInfo[_idx];
    }
}
