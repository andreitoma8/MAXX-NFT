from brownie import MAXXLambo, LamboLock, Stablecoin, accounts, chain
import brownie


def test_main():
    # Set up accounts
    owner = accounts[0]
    user = accounts[1]
    # Deploy Contracts
    stablecoin = Stablecoin.deploy({"from": owner})
    collection = MAXXLambo.deploy(stablecoin.address, {"from": owner})
    lock = LamboLock.deploy(collection.address, {"from": owner})
    # Fund user with Stablecoins
    stablecoin.transfer(user.address, 10000 * 10**18, {"from": owner})
    # Unpause minting
    collection.setPaused(False, {"from": owner})
    # Try to mint without stablecoins
    with brownie.reverts():
        collection.mint(1, {"from": user})
    # Approve tokens
    stablecoin.approve(collection.address, 1000 * 10**18, {"from": user})
    stablecoin.approve(collection.address, 1000 * 10**18, {"from": owner})
    # Unpause minting
    collection.setPaused(False, {"from": owner})
    # Mint
    collection.mint(2, {"from": user})
    collection.mint(2, {"from": owner})
    assert collection.balanceOf(user.address) == 2
    # Try to mint more than 3 per tx
    with brownie.reverts():
        collection.mint(4, {"from": user})
    # Try to mint when contract is paused
    collection.setPaused(True, {"from": owner})
    with brownie.reverts():
        collection.mint(1, {"from": user})

    timestamp = chain.time()
    current_day = int(timestamp / 60 / 60 / 24)
    # Approve NFT for transfer
    collection.approve(lock.address, 1, {"from": user})
    collection.approve(lock.address, 2, {"from": user})
    # Make a reservation in one week
    lock.makeReservation(1, current_day + 7, "user@email.com", {"from": user})
    # Atempt to a second lock from the same user
    with brownie.reverts():
        lock.makeReservation(2, current_day + 3, "user@email.com", {"from": user})
    # Get reservation for user
    reservation = lock.getReservation(current_day + 7)
    assert reservation == [user.address, [1, current_day + 7, "user@email.com"]]
    # Fulfil reservation
    lock.fulfillReservation(user.address, {"from": owner})
    assert collection.balanceOf(user.address) == 2
    # Try to make reservation in the past
    with brownie.reverts():
        lock.makeReservation(2, current_day - 3, "user@email.com", {"from": user})
    # Try to make reservation with the same token
    collection.approve(lock.address, 1, {"from": user})
    with brownie.reverts():
        lock.makeReservation(1, current_day + 5, "user@email.com", {"from": user})
    # Make reservation from owner
    collection.approve(lock.address, 3, {"from": owner})
    lock.makeReservation(3, current_day + 10, "user@email.com", {"from": owner})
    # Try to make reservation on the same date from diferent user
    collection.approve(lock.address, 2, {"from": user})
    with brownie.reverts():
        lock.makeReservation(2, current_day + 10, "user@email.com", {"from": user})
    # See available dates
    available_dates = lock.getAvailableDates()
    print(available_dates)
