from web3 import Web3

# RPC URL
rpc_url = "https://testnet-rpc.wvm.dev"

# Initialize a Web3 instance
w3 = Web3(Web3.HTTPProvider(rpc_url))

def check_rpc_methods():
    try:
        # Check for eth_chainId support
        try:
            chain_id = w3.eth.chain_id
            print(f"eth_chainId supported, chain ID: {chain_id}")
        except Exception as e:
            print(f"eth_chainId not supported: {e}")

        # Check for eth_networkId support
        try:
            network_id = w3.net.version
            print(f"eth_networkId supported, network ID: {network_id}")
        except Exception as e:
            print(f"eth_networkId not supported: {e}")

    except Exception as e:
        print(f"Error connecting to RPC: {e}")

if __name__ == "__main__":
    check_rpc_methods()

