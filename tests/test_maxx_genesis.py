from brownie import MAXXGenesis, accounts, config
from Crypto.Hash import keccak
import brownie


def test_main():
    owner = accounts[0]
    genesis = MAXXGenesis.deploy({"from": owner})
    code = "code-104"
    bytes_code = b"code-104"
    print(code)
    hashed_code = keccak.new(digest_bits=256)
    hashed_code.update(bytes_code)
    print(hashed_code.hexdigest())
    genesis.setCodes([hashed_code.hexdigest()], {"from": owner})
    with brownie.reverts():
        genesis.mint("code-103", {"from": owner})
    genesis.mint("code-104", {"from": owner})
    assert genesis.balanceOf(owner.address) == 1
    with brownie.reverts():
        genesis.mint("code-104", {"from": owner})
