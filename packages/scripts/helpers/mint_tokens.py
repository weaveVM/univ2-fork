import argparse
from web3 import Web3
from web3.middleware import geth_poa_middleware

ERC20_ABI = '''[
    {
        "constant": false,
        "inputs": [
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "mint",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    }
]
'''

# Argument parsing
parser = argparse.ArgumentParser(description="Mint tokens using ERC20 contract")
parser.add_argument('--rpc_url', type=str, required=True, help='RPC URL of the Ethereum node')
parser.add_argument('--private_key', type=str, required=True, help='Private key to sign transactions')
parser.add_argument('--token_address', type=str, required=True, help='Address of the ERC20 token contract')
parser.add_argument('--mint_to_address', type=str, required=True, help='Address to mint tokens to')
parser.add_argument('--mint_amount', type=int, required=True, help='Amount of tokens to mint (in token smallest unit)')

args = parser.parse_args()

# Connect to the Ethereum node
web3 = Web3(Web3.HTTPProvider(args.rpc_url))

# Get account from private key
account = web3.eth.account.from_key(args.private_key)
wallet_address = account.address

# Function to send transactions
def send_transaction(txn):
    signed_txn = web3.eth.account.sign_transaction(txn, private_key=args.private_key)
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    return receipt

# Mint Tokens
token_contract = web3.eth.contract(address=args.token_address, abi=ERC20_ABI)
mint_txn = token_contract.functions.mint(args.mint_amount, args.mint_to_address).build_transaction({
    'from': wallet_address,
    'nonce': web3.eth.get_transaction_count(wallet_address),
    'gasPrice': web3.to_wei('5', 'gwei')
})

# Estimate gas required for the transaction
gas_estimate = web3.eth.estimate_gas(mint_txn)
mint_txn['gas'] = gas_estimate + 10000  # Adding a buffer
receipt = send_transaction(mint_txn)
print(f"Transaction receipt: {receipt}")
