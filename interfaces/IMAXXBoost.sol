// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMAXXBoost is IERC721 {
    function setUsed(uint256 _tokenId) external;

    function getUsedState(uint256 _tokenId) external view returns (bool);

    function mint(uint256 _randomNumber) external;
}
