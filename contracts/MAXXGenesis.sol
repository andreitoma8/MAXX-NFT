// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILiquidityAmplifier.sol";

/// @title MAXX Genesis NFT Collection
/// @author Andrei Toma
/// @notice Using an NFT from this collection when you stake your MAXX Tokens will give you APR bonuses. NFTs can be only used one time.
contract MAXXGenesis is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    // The maximum supply of the collection
    uint256 public constant MAX_SUPPLY = 5000;

    // Token URI for the NFTs available to use for Staking APR Bonus
    string internal uri = "ipfs://.../";

    // The address of the MAXX Liquidity Amplifier Smart Contract
    address public immutable amplifierContract;

    // Mapping of hashed codes to their availability
    mapping(bytes32 => bool) codes;

    /// @notice Sets the Name and Ticker for the Collection
    constructor(address _amplifierContract) ERC721("MAXX OG", "MAXXOG") {
        amplifierContract = _amplifierContract;
    }

    /// @notice Called by MAXX Staking SC to mint a reward NFT to user that stake >= 10.000.000 MAXX for 3.333 days.
    /// @param _code the code required to redeem the NFT
    /// @param _user the user address to mint to
    /// @dev supply.increment() is called before _safeMint() to start the collection at tokenId 1
    function mint(string memory _code, address _user) external {
        require(
            msg.sender == amplifierContract,
            "Only the Liquidity Amplifier contract can call this fuction!"
        );
        bytes32 hashedCode = keccak256(abi.encodePacked(_code));
        require(codes[hashedCode], "Wrong or used code!");
        codes[hashedCode] = false;
        require(
            supply.current() + 1 <= MAX_SUPPLY,
            "Maximum supply has been reached!"
        );
        supply.increment();
        _safeMint(_user, supply.current());
    }

    /// @notice Set the URI for metadata
    /// @param _uri The URI as a sting
    /// @dev use in the format: "ipfs://your_uri/"
    function setUri(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    /// @notice Set the hashed codes that can be used to mint an NFT
    /// @param _codes Array of hashed codes
    function setCodes(bytes32[] calldata _codes) external onlyOwner {
        uint256 _length = _codes.length;
        for (uint256 i; i < _length; i++) {
            codes[_codes[i]] = true;
        }
    }

    /// @notice Returns the Token IDs of the NFTs owner by a user
    /// @param _owner the address of the user
    /// @return ownedTokenIds The Token IDs owned by the address
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
