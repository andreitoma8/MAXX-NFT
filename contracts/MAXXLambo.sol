// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Contract for NFT tickets that get you a riding experience in MAXX Lambo
/// @author Andrei Toma
/// @notice NFTs from this collection can be used to ride around in the MAXX Lambo in Miami and to do this you need to make a reservation in the LamboLock contract
contract MAXXLambo is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private supply;

    IERC20 public usdc;

    // Minting state
    bool public paused = true;

    // Cost of one NFT
    uint256 public cost = 100 * 10**18;

    // The maximum supply
    uint256 public constant MAX_SUPPLY = 3000;

    // The maximum mint amount allowed per transaction
    uint256 public maxMintAmountPerTx = 3;

    // The address of the Lambo Lock contract
    address public lamboLock;

    // Mapping of token id to how many reservations the NFT was used for
    mapping(uint256 => uint256) public timesUsed;

    // Mapping of times used to metadata uri to be returned
    mapping(uint256 => string) public uriMapping;

    /// @notice initialize the ERC20 interface for USDT and the URI for the first and second cycles of reservations
    /// @param _usdc the address of the USDT Token Contract
    /// @param _uriZero the URI for metadta to be returned for unused NFTs
    /// @param _uriOne the URI for metadata to be returned for NFTs with one use
    constructor(IERC20 _usdc, string memory _uriZero, string memory _uriOne) ERC721("MAXX Lambo", "LAMBO") {
        usdc = _usdc;
        uriMapping[0] = _uriZero;
        uriMapping[1] = _uriOne;
    }

    /// @notice modifier that ensures the maximum supply and the maximum amount to mint per transaction are respected
    /// @param _mintAmount the amount of NFTs to mint
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount <= MAX_SUPPLY,
            "Max supply exceeded!"
        );
        require(!paused, "Minting is not live!");
        _;
    }

    /// @notice returns the current supply of the collection
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    /// @notice the mint function
    /// @param _mintAmount the amount of NFTs to mint
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        usdc.safeTransferFrom(msg.sender, address(this), cost * _mintAmount);
        _mintLoop(msg.sender, _mintAmount);
    }

    /// @notice returns the Token IDs for Tokens owned by the specified address
    /// @param _owner the address of the user
    /// @return ownedTokenIds Token IDs owned by the address
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

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
    /// @return uri The URI for the Token ID
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
        return uriMapping[timesUsed[_tokenId]];
    }

    /// @notice set the Lambo Lock contract
    /// @param _address the address of the Lambo Lock contract
    function setLamboLock(address _address) external onlyOwner {
        lamboLock = _address;
    }

    /// @notice set the maximum mint amount per transaction
    /// @param _maxMintAmountPerTx the new maximum amount to set
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /// @notice function for the Lambo Lock contract to set an NFT as used once the reservation is complete
    /// @param _tokenId the token id to be set as used
    function setUsed(uint256 _tokenId) external {
        require(msg.sender == lamboLock);
        timesUsed[_tokenId]++;
    }

    /// @notice set the URI for a selected cycle
    /// @param cycle the cycle to set the URI for
    /// @param uri the URI for the NFT Metadata
    function setUri(uint256 cycle, string memory uri) external onlyOwner {
        uriMapping[cycle] = uri;
    }

    /// @notice pause and unpause the minting
    /// @param _state bool for paused state
    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    /// @notice withdraw the USDT accumulated form minting
    function withdraw() public onlyOwner {
        uint256 balance = usdc.balanceOf(address(this));
        usdc.safeTransferFrom(address(this), msg.sender, balance);
    }

    /// @notice helper loop function for multiple mints in one call
    /// @param _receiver the address to mint to
    /// @param _mintAmount the amount of NFTs to mint
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }
}
