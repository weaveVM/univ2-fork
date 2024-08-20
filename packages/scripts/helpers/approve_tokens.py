import argparse
from web3 import Web3

# ERC20 ABI - only including the approve function
ERC20_ABI = '''[
    {
        "constant": false,
        "inputs": [
            {
                "name": "_spender",
                "type": "address"
            },
            {
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "approve",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "type": "function"
    }
]'''

def parse_arguments():
    parser = argparse.ArgumentParser(description="Approve ERC20 token spending")
    parser.add_argument('--rpc_url', type=str, required=True, help='RPC URL of the Ethereum node')
    parser.add_argument('--private_key', type=str, required=True, help='Private key of the token owner')
    parser.add_argument('--token_address', type=str, required=True, help='Address of the ERC20 token contract')
    parser.add_argument('--spender_address', type=str, required=True, help='Address to approve for spending tokens')
    parser.add_argument('--approve_amount', type=int, required=True, help='Amount of tokens to approve for spending')
    return parser.parse_args()

def connect_to_ethereum(rpc_url):
    web3 = Web3(Web3.HTTPProvider(rpc_url))
    if not web3.is_connected():
        raise Exception("Failed to connect to Ethereum node")
    return web3

def get_account(web3, private_key):
    account = web3.eth.account.from_key(private_key)
    return account

def approve_tokens(web3, account, token_contract, spender_address, approve_amount):
    nonce = web3.eth.get_transaction_count(account.address)
    
    approve_txn = token_contract.functions.approve(
        spender_address,
        approve_amount
    ).build_transaction({
        'from': account.address,
        'nonce': nonce,
        'gas': 100000,  # Set a default gas limit
        'gasPrice': web3.eth.gas_price
    })

    # Estimate gas and update the transaction
    try:
        gas_estimate = web3.eth.estimate_gas(approve_txn)
        approve_txn['gas'] = gas_estimate
    except Exception as e:
        print(f"Gas estimation failed: {e}. Using default gas limit.")

    # Sign and send the transaction
    signed_txn = account.sign_transaction(approve_txn)
    tx_hash = web3.eth.send_raw_transaction(signed_txn.rawTransaction)
    
    # Wait for transaction receipt
    tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt

def main():
    args = parse_arguments()
    
    web3 = connect_to_ethereum(args.rpc_url)
    account = get_account(web3, args.private_key)
    
    token_contract = web3.eth.contract(address=args.token_address, abi=ERC20_ABI)
    
    try:
        tx_receipt = approve_tokens(
            web3, 
            account, 
            token_contract, 
            args.spender_address, 
            args.approve_amount
        )
        print(f"Approval successful. Transaction hash: {tx_receipt.transactionHash.hex()}")
    except Exception as e:
        print(f"Approval failed: {e}")

if __name__ == "__main__":
    main()