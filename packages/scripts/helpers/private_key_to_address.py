# convert.py

import argparse
from web3 import Web3

parser = argparse.ArgumentParser(description="Convert Ethereum Private Key to Public Key")
# Set up argument parser
parser.add_argument('--rpc_url', type=str, required=True, help='RPC URL of the Ethereum node')
parser.add_argument('--private_key', type=str, required=True, help='Ethereum private key')

# Parse arguments
args = parser.parse_args()

# Connect to the Ethereum node
web3 = Web3(Web3.HTTPProvider(args.rpc_url))

# Convert private key to address
account = web3.eth.account.from_key(args.private_key)
print(f"{account.address}")
