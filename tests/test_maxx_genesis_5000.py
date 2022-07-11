from brownie import MAXXGenesis, accounts, config
from Crypto.Hash import keccak
import brownie
import csv


def test_main():
    # Set up account
    # owner = accounts[0]
    owner = accounts.add(config["wallets"]["from_key"])
    # Deploy
    genesis = MAXXGenesis.deploy({"from": owner})
    # Inport codes from CSV
    with open("codes.txt", newline="") as csvfile:
        rows = csv.reader(csvfile, delimiter=",")
        data = []
        for row in rows:
            data.append(row)
    # Encrypt codes
    codes = []
    for code in data:
        byte_code = code[0].encode("utf8")
        hashed_code = keccak.new(digest_bits=256)
        hashed_code.update(byte_code)
        value_to_append = hashed_code.hexdigest()
        codes.append(value_to_append)
    codes = [codes[x : x + 250] for x in range(0, len(codes), 250)]
    # Upload hash of codes in the SC
    for sublist in codes:
        genesis.setCodes(sublist, {"from": owner})
    # Check if contract reverts with wrong code
    with brownie.reverts():
        genesis.mint("code-103", {"from": owner})
    # Check if contract mints with right code
    genesis.mint("U8YdLMPL", {"from": owner})
    assert genesis.balanceOf(owner.address) == 1
    # Check if contract reverts with same code used the second time
    with brownie.reverts():
        genesis.mint("U8YdLMPL", {"from": owner})
