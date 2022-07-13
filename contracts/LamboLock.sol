// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract for reservations to drive the MAXX Lambo
/// @author Andrei Toma
/// @notice Lock your tokens to reserve an available date
contract LamboLock is Ownable {
    IERC721 maxxLambo;

    uint256 public cycle;

    struct Reservation {
        uint256 tokenId;
        uint256 date;
        string contact;
    }

    mapping(address => Reservation) addressReservations;
    mapping(uint256 => bool) reservedDates;
    mapping(uint256 => address) dateToAddress;
    mapping(uint256 => uint256) public timesUsed;

    event ReservationMade(
        uint256 indexed date,
        address indexed userAddress,
        string indexed contact
    );

    /// @notice set the MAXX Lambo address
    /// @param _maxxLambo the address of the Lambo NFT Contract
    constructor(IERC721 _maxxLambo) {
        maxxLambo = _maxxLambo;
    }

    /// @notice reserve a date to drive the Lambo by locking a MAXX Lambo NFT in this Contract
    /// @param tokenId the token ID of the NFT you want to lock in the contract
    /// @param date the date to make the reservation in UNIX format converted to days(UNIX / 60 /60 / 24)
    /// @param contact the contact information required to confirm the reservation(email or Telegram)
    function makeReservation(
        uint256 tokenId,
        uint256 date,
        string calldata contact
    ) external {
        require(date > getCurrentDate(), "Date out of bounce.");
        require(!reservedDates[date], "Date is not available.");
        require(
            addressReservations[msg.sender].tokenId == 0,
            "Can't have two or more reservations at a time."
        );
        require(
            timesUsed[tokenId] < cycle,
            "Token already used in this cycle."
        );
        addressReservations[msg.sender].tokenId = tokenId;
        addressReservations[msg.sender].date = date;
        addressReservations[msg.sender].contact = contact;
        dateToAddress[date] = msg.sender;
        reservedDates[date] = true;
        maxxLambo.transferFrom(msg.sender, address(this), tokenId);
        emit ReservationMade(date, msg.sender, contact);
    }

    /// @notice called by the admin after the driving experience is completed and the car is returned
    /// @param user the address of the user that completed the driving experience
    function fulfillReservation(address user) external onlyOwner {
        maxxLambo.transferFrom(
            address(this),
            user,
            addressReservations[user].tokenId
        );
        timesUsed[addressReservations[user].tokenId]++;
        reservedDates[addressReservations[user].date] = false;
        addressReservations[user].tokenId = 0;
        addressReservations[user].date = 0;
    }

    /// @notice get the reservation for a specific date
    /// @param date the date to query for in UNIX format converted to days
    function getReservation(uint256 date)
        external
        view
        returns (Reservation memory)
    {
        return addressReservations[dateToAddress[date]];
    }

    /// @notice allows the admin to set a date as reserved to not alow any other reservations for it
    /// @param date the date to be set as reserved in UNIX fromat converted to days
    function disableDate(uint256 date) external onlyOwner {
        require(!reservedDates[date], "Date is already reserved.");
        reservedDates[date] = true;
    }

    /// @notice allows the admin to set a date as free
    /// @param date the date to be set as free in UNIX fromat converted to days
    function enableDate(uint256 date) external onlyOwner {
        require(reservedDates[date], "Date is already reserved.");
        reservedDates[date] = false;
    }

    /// @notice after most or all the NFTs are used for a ride experience the Owner can move to the next cycle of reservations
    function nextCycle() external onlyOwner {
        cycle++;
    }

    /// @notice helper function to get the current date in UNIX fromat converted to days
    function getCurrentDate() internal view returns (uint256) {
        return block.timestamp / 60 / 60 / 24;
    }
}
