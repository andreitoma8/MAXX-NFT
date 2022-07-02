// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ILiquidityAmplifier {
    function getParticipants() external view returns (address[] memory);
}
