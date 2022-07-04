from brownie import MAXXBoost, LiquidityAmplifier, MaxxStake, accounts
import brownie


def test_main():
    # Set up Contracts
    owner = accounts[0]
    amplify = LiquidityAmplifier.deploy({"from": owner})
    staking = MaxxStake.deploy({"from": owner})
    boost = MAXXBoost.deploy(amplify.address, staking.address, {"from": owner})
    staking.setMaxxBoost(boost.address, {"from": owner})

    # Participate in Liquidity Amplifier
    for i in range(0, 10):
        amplify.participate({"from": accounts[i]})

    # Mint NFTs
    boost.mint(123, {"from": owner})
    participants = amplify.getParticipants()
    assert boost.ownerOf(1) == participants[123 % len(participants)]
    boost.mint(7, {"from": owner})
    assert boost.ownerOf(2) == participants[7 % len(participants)]
    boost.mint(1, {"from": owner})
    assert boost.ownerOf(3) == accounts[1].address

    # Check if NFT is marked as used after Staking
    assert boost.getUsedState(1) == False
    staking.stake(1, {"from": accounts[3]})
    assert boost.getUsedState(1) == True

    # Check if staking with the used token is blocked
    with brownie.reverts():
        staking.stake(1, {"from": accounts[3]})

    # Check metadata change when token is used
    assert boost.tokenURI(2) == "available"
    staking.stake(2, {"from": accounts[7]})
    assert boost.tokenURI(2) == "used"
