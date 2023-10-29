// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract UnfuckGPT is IWormholeReceiver, Ownable {
    event MembershipChanged(address indexed from, address indexed to);

    IWormholeRelayer public immutable wormholeRelayer;

    mapping(bytes32 => bool) public seenDeliveryVaaHashes;
    mapping(address => bool) public members;

    mapping(uint256 => address) public nftContracts;

    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    function setNftContractAddressOnChain(
        uint256 _chainId,
        address _contract
    ) external onlyOwner {
        nftContracts[_chainId] = _contract;
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory /* additionalVaas */,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");

        require(
            !seenDeliveryVaaHashes[deliveryHash],
            "Message already processed"
        );
        seenDeliveryVaaHashes[deliveryHash] = true;

        require(
            bytes32ToAddress(sourceAddress) ==
                nftContracts[uint256(sourceChain)],
            "Only the configured NFT contract can send msgs"
        );

        (address from, address to) = abi.decode(payload, (address, address));

        changeMembership(from, to);
    }

    function membershipChangeOnHostChain(address _from, address _to) external {
        require(block.chainid == 80001, "Host chain is polygon mumbai");

        require(
            msg.sender == nftContracts[5],
            "Not from host chain nft"
        );
        changeMembership(_from, _to);
    }

    function changeMembership(address _from, address _to) internal {
        members[_from] = false;
        members[_to] = true;

        emit MembershipChanged(_from, _to);
    }

    function bytes32ToAddress(bytes32 _address) private pure returns (address) {
        return address(uint160(uint256(_address)));
    }
}
