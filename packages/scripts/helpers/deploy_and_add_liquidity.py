#! WARNING ! #
# This file might not work

import argparse
from web3 import Web3
from web3.middleware import geth_poa_middleware

# ABI definitions for the ERC20 and Uniswap contracts
ERC20_ABI = '[{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}]'
UNISWAP_FACTORY_ABI = '[{"constant":false,"inputs":[{"name":"token0","type":"address"},{"name":"token1","type":"address"}],"name":"createPair","outputs":[{"name":"pair","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"token0","type":"address"},{"name":"token1","type":"address"}],"name":"getPair","outputs":[{"name":"pair","type":"address"}],"payable":false,"stateMutability":"view","type":"function"}]'

# Argument parsing
parser = argparse.ArgumentParser(description="Create a pair and add liquidity on Uniswap V2")
parser.add_argument('--rpc_url', type=str, required=True, help='RPC URL of the Ethereum node')
parser.add_argument('--private_key', type=str, required=True, help='Private key to sign transactions')
parser.add_argument('--token_a', type=str, required=True, help='Address of Token A')
parser.add_argument('--token_b', type=str, required=True, help='Address of Token B')
parser.add_argument('--factory_address', type=str, required=True, help='Address of the Uniswap V2 Factory')

args = parser.parse_args()

# Connect to the Ethereum node
web3 = Web3(Web3.HTTPProvider(args.rpc_url))

# If using a testnet like Rinkeby, inject the proof of authority middleware
web3.middleware_onion.inject(geth_poa_middleware, layer=0)

# Get account from private key
account = web3.eth.account.from_key(args.private_key)
wallet_address = account.address

# Function to send transactions
def send_transaction(txn):
    signed_txn = web3.eth.account.sign_transaction(txn, private_key=args.private_key)
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    return receipt

# Create Pair
factory = web3.eth.contract(address=args.factory_address, abi=UNISWAP_FACTORY_ABI)
create_pair_txn = factory.functions.createPair(args.token_a, args.token_b).build_transaction({
    'from': wallet_address,
    'nonce': web3.eth.get_transaction_count(wallet_address),
    'gas': 200000,
    'gasPrice': web3.to_wei('5', 'gwei')
})
receipt = send_transaction(create_pair_txn)
print(f"receipt: {receipt}")
