// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract LiquidityAmplifier {
    address[] public participants;

    function participate() external {
        participants.push(msg.sender);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }
}
