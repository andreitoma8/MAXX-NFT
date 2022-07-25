// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../../interfaces/IMAXXBoost.sol";

contract MaxxStake {
    IMAXXBoost maxxBoost;

    function setMaxxBoost(IMAXXBoost _maxxBoost) external {
        maxxBoost = _maxxBoost;
    }

    function stake(uint256 _tokenId) external {
        require(
            maxxBoost.ownerOf(_tokenId) == msg.sender,
            "Must be the owner of the NFT!"
        );
        require(
            maxxBoost.getUsedState(_tokenId) == false,
            "NFT is already used!"
        );
        // give boost
        maxxBoost.setUsed(_tokenId);
    }
}
