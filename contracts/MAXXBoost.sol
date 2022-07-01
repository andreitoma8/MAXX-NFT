// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MAXX NFT Collection
/// @author Andrei Toma
/// @notice Using an NFT from this collection when you stake your MAXX Tokens will give you APR bonuses. NFTs can be only used one
contract MAXXBoost is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    // Token URI for the NFTs available to use for Staking APR Bonus
    string internal constant AVAILABLE_URI = "";

    // Token URI for used NFTs
    string internal constant USED_URI = "";

    // The maximum supply of the collection
    uint256 public constant MAX_SUPPLY = 120;

    // The address of the MAXX Liquidity Amplifier Smart Contract
    address public immutable amplifierContract;

    // The address of the MAXX Staking Smart Contract
    address public immutable stakingContract;

    // Mapping of Token ID to used state
    mapping(uint256 => bool) private usedState;

    /// @notice Sets the MAXX Amplify Smart Contract Address, Name and Token for the Collection
    /// @param  _amplifierContract the address of the Amplify Smart Contract
    /// @param  _stakingContract the address of the Amplify Smart Contract
    constructor(address _amplifierContract, address _stakingContract)
        ERC721("MAXXBoost", "MAXXB")
    {
        amplifierContract = _amplifierContract;
        stakingContract = _stakingContract;
    }

    /// @notice Mint NFTs function for the owner to airdrop NFTs if there are enough NFTs left
    /// @param _receiver the wallet address to mint to
    function mintForAddress(address _receiver) external {
        require(
            msg.sender == amplifierContract || msg.sender == stakingContract,
            "Only the Amplify Contract can mint NFTs"
        );
        require(supply.current() + 1 <= MAX_SUPPLY, "Max supply exceeded!");
        supply.increment();
        _safeMint(_receiver, supply.current());
    }

    /// @notice Marks NFT as used after it has been used in the MAXX Amplifier or Staking Contract
    /// @param _tokenId the Token ID of the NFT to be marked as used
    /// @dev This function is only callable by the MAXX Amplify Contract
    function setUsed(uint256 _tokenId) external {
        require(
            msg.sender == amplifierContract || msg.sender == stakingContract,
            "Only the Amplify Contract can set a token as used"
        );
        usedState[_tokenId] = true;
    }

    /// @notice Verifies if a NFT is used or not
    /// @param _tokenId the Token ID that is verified
    /// @return Bool for the used state of the NFT
    function getUsedState(uint256 _tokenId) external view returns (bool) {
        return usedState[_tokenId];
    }

    /// @notice Returns the Token IDs of the NFTs owner by a user
    /// @param _owner the address of the user
    /// @return The Token IDs owned by the address
    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    /// @notice Returns the URI used to access the IPFS file containing the NFT Metadata
    /// @param _tokenId the Token ID of the NFT
    /// @return The URI for the Token ID
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (usedState[_tokenId]) {
            return USED_URI;
        } else {
            return AVAILABLE_URI;
        }
    }

    /// @notice Returns the total supply of the collection
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }
}
