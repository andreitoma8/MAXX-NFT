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
    # Mint
    boost.mint(123, {"from": owner})
    participants = amplify.getParticipants()
    winner_one = boost.ownerOf(1)
    assert boost.ownerOf(1) == participants[123 % len(participants)]
    boost.mint(7, {"from": owner})
    winner_two = boost.ownerOf(2)
    assert winner_two == participants[7 % len(participants)]
    boost.mint(1, {"from": owner})
    winner_three = boost.ownerOf(3)
    assert winner_three == accounts[1].address
    # Use NFTs
    assert boost.getUsedState(1) == False
    staking.stake(1, {"from": accounts[3]})
    assert boost.getUsedState(1) == True
    with brownie.reverts():
        staking.stake(1, {"from": accounts[3]})
    # NFT Metadata
    assert boost.tokenURI(2) == "available"
    staking.stake(2, {"from": accounts[7]})
    assert boost.tokenURI(2) == "used"
