import argparse
from web3 import Web3

# Set up argument parser
parser = argparse.ArgumentParser(description="Query INIT_CODE_HASH from a smart contract")
parser.add_argument('--rpc_url', type=str, required=True, help='RPC URL of the Ethereum node')
parser.add_argument('--contract_address', type=str, required=True, help='Address of the smart contract')

# Parse arguments
args = parser.parse_args()

# Connect to the Ethereum node
web3 = Web3(Web3.HTTPProvider(args.rpc_url))

# Contract details
# ABI definition
abi = [
    {
        "constant": True,
        "inputs": [],
        "name": "INIT_CODE_HASH",
        "outputs": [
            {
                "name": "",
                "type": "bytes32"
            }
        ],
        "payable": False,
        "stateMutability": "view",
        "type": "function"
    }
]
print(args.contract_address)
# Initialize contract
contract = web3.eth.contract(address=args.contract_address, abi=abi)

# Query INIT_CODE_HASH
# in contracts/lib/v2-core/contracts/UniswapV2Factory.sol
# bytes32 public constant INIT_CODE_HASH = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));

init_code_hash = contract.functions.INIT_CODE_HASH().call()
print(init_code_hash.hex())
