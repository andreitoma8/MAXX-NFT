// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MAXXOG NFT Collection
/// @author Andrei Toma
/// @notice Using an NFT from this collection when you stake your MAXX Tokens will give you APR bonuses. NFTs can be only used one
contract MAXXOG is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    // Token URI for the NFTs available to use for Staking APR Bonus
    string internal uri = "ipfs://.../";

    // The maximum supply of the collection
    uint256 public constant MAX_SUPPLY = 500;

    // The address of the MAXX Staking Smart Contract
    address public immutable stakingContract;

    /// @notice Sets the MAXX Amplify Smart Contract Address, Name and Token for the Collection
    /// @param  _stakingContract the address of the Amplify Smart Contract
    constructor(address _stakingContract) ERC721("MAXX OG", "MAXXOG") {
        stakingContract = _stakingContract;
    }

    /// @notice Called by MAXX Staking SC to mint a reward NFT to user that stake >= 10.000.000 MAXX for 3.333 days.
    /// @param _address the wallet address to mint to
    /// @dev supply.increment() is called before _safeMint() to start the collection at tokenId 1
    function mint(address _address) external {
        require(
            msg.sender == stakingContract,
            "Only the Staking contract can mint NFTs~"
        );
        require(
            supply.current() + 1 <= MAX_SUPPLY,
            "Maximum supply has been reached!"
        );
        supply.increment();
        _safeMint(_address, supply.current());
    }

    /// @notice Set the URI for metadata
    /// @param _uri The URI as a sting
    /// @dev use in the format: "ipfs://your_uri/"
    function setUri(string memory _uri) public onlyOwner {
        uri = _uri;
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
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    /// @notice Returns the total supply of the collection
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    // Helper function
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }
}
