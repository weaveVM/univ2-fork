#!/bin/bash

# Define the output file
OUTPUT_FILE="../logs/redeploy_output.txt"

directory=$(dirname "$OUTPUT_FILE")
filename=$(basename "$OUTPUT_FILE")

if [ ! -d "$directory" ]; then
    mkdir -p "$directory"
    echo "Directory $directory created."
fi

if [ ! -f $OUTPUT_FILE ]; then
    touch "$OUTPUT_FILE"
    echo "File $OUTPUT_FILE created."
fi


# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$OUTPUT_FILE"
}

# Prompt for RPC URL
printf "Enter RPC URL (default: https://testnet-rpc.wvm.dev): "
read RPC_URL
RPC_URL=${RPC_URL:-https://testnet-rpc.wvm.dev}
log_message "Using RPC URL: $RPC_URL"

# printf "Enter your public ethereum address: "
# read PUBLIC_KEY

# if [ -z "$PUBLIC_KEY" ]; then
#     log_message "Error: Ethereum address is required.\n"
#     exit 1
# fi

# Prompt for private key (hidden input)
printf "Enter your private key associated with the address (make sure it's funded): "
# Disable terminal echo
stty -echo
read PRIVATE_KEY
# Re-enable terminal echo
stty echo
echo ""  # Add a newline after the input to separate subsequent outputs

if [ -z "$PRIVATE_KEY" ]; then
    log_message "Error: Private key is required.\n"
    exit 1
fi

log_message "Private key received (hidden for security)"

# Export the private key as an environment variable
export PRIVATE_KEY
log_message "Private key exported as environment variable."

PUBLIC_KEY=$(python3 ../helpers/private_key_to_address.py --private_key $PRIVATE_KEY --rpc_url $RPC_URL)
export PUBLIC_KEY
echo "Ethereum Address: $PUBLIC_KEY"

# Navigate to contracts directory
log_message "Changing directory to ../../contracts"
cd ../../contracts || { log_message "Failed to change directory to ../../contracts"; exit 1; }

# Update the output file path after navigating to the contracts directory
OUTPUT_FILE="../scripts/logs/redeploy_output.txt"
log_message "Current directory: $(pwd)"

# Function to get current gas price and add a premium

log_message "Deploying WETH (WtWVM)..."
GAS_PRICE=1000000007
WETH_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/WtWVM.sol:WtWVM --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "WETH (WtWVM) deployed to: $WETH_ADDRESS"

log_message "Deploying UniswapV2Factory..."

FEE_TO_SETTER="$PUBLIC_KEY"
FACTORY_ADDRESS=$(forge create --rpc-url $RPC_URL  lib/v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory --constructor-args $FEE_TO_SETTER --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "UniswapV2Factory deployed to: $FACTORY_ADDRESS"

# Update the constants.ts file
sed -i "s/export const FACTORY_ADDRESS = '\(0x[a-fA-F0-9]\{40\}\|''\)'/export const FACTORY_ADDRESS = '$FACTORY_ADDRESS'/" ../interface/v2-sdk/src/constants.ts

if [ $? -eq 0 ]; then
    log_message "Updated TypeScript constants.ts file const FACTORY_ADDRESS to $FACTORY_ADDRESS"
else
    log_message "Failed to update FACTORY_ADDRESS"
fi

sed -i "s/\[ChainId\.WEAVE\]: new Token(ChainId\.WEAVE, '\(0x[a-fA-F0-9]\{40\}\|''\)', 18, 'WtWVM', 'Wrapped tWVM')/[ChainId.WEAVE]: new Token(ChainId.WEAVE, '$WETH_ADDRESS', 18, 'WtWVM', 'Wrapped tWVM')/" "../interface/v2-sdk/src/entities/token.ts"

if [ $? -eq 0 ]; then
    echo "Updated token.ts file with new WETH_ADDRESS: $WETH_ADDRESS"
else
    echo "Failed to update WETH_ADDRESS in token.ts"
fi

log_message "Deploying Multicall..."

MULTICALL_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/Multicall.sol:Multicall3 --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "Multicall deployed to: $MULTICALL_ADDRESS"

log_message "Deploying UniswapV2Router02..."

ROUTER_ADDRESS=$(forge create --rpc-url $RPC_URL  lib/v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02 --constructor-args $FACTORY_ADDRESS $WETH_ADDRESS --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "UniswapV2Router02 deployed to: $ROUTER_ADDRESS"

log_message "Deploying Token0..."

TOKEN0_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "Token0" "TKN0" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "Token0 deployed to: $TOKEN0_ADDRESS"

log_message "Deploying Token1..."

TOKEN1_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "Token1" "TKN1" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "Token1 deployed to: $TOKEN1_ADDRESS"

TOKEN_A_ADDRESS="$TOKEN0_ADDRESS"
TOKEN_B_ADDRESS="$TOKEN1_ADDRESS"

# # rewrite to get address from running the test suite
# DEFAULT_PAIR_ADDRESS="0x3A52e781CDf306DA5643Bf8e5FEb7403d352B3b1" # random non-working address
# output=$(python3 ../scripts/helpers/deploy_and_add_liquidity.py --rpc_url "$RPC_URL" --private_key "$PRIVATE_KEY" --token_a "$TOKEN_A_ADDRESS" --token_b "$TOKEN_B_ADDRESS" --factory_address "$FACTORY_ADDRESS")

# # Extract the pair address from the output
# PAIR_ADDRESS=$(echo "$output" | grep "Pair address is:" | awk '{print $4}')
# log $PAIR_ADDRESS
# # If PAIR_ADDRESS is empty, use the default address
# if [ -z "$PAIR_ADDRESS" ]; then
#     PAIR_ADDRESS=$DEFAULT_PAIR_ADDRESS
# fi

# Update the Solidity test file with the new pair address
# log_message "Updating Solidity test file with the new pair address $PAIR_ADDRESS"
# sed -i "s/assertEq(pairAddress, 0x[a-fA-F0-9]\{40\});/assertEq(pairAddress, $PAIR_ADDRESS);/" test/UniswapV2RouterTest.sol

log_message "Deploying Token C..."

TOKEN_C_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "Token C" "TKNC" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "Token C deployed to: $TOKEN_C_ADDRESS"

THINKPAD_TOKEN_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "ThinkPad" "THNKPD" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
log_message "ThinkPad deployed to: $THINKPAD_TOKEN_ADDRESS"

# After deploying contracts and before running tests, mint 1 billion ThinkPad tokens
log_message "Minting 1 billion ThinkPad tokens using mint_tokens.py..."

MINT_TO_ADDRESS="$PUBLIC_KEY"
MINT_AMOUNT=1000000000000000000000000000  # 1 billion tokens in wei

# Run the mint_tokens.py script
python3 mint_tokens.py --rpc_url "$RPC_URL" --private_key "$PRIVATE_KEY" --token_address "$THINKPAD_TOKEN_ADDRESS" --mint_to_address "$MINT_TO_ADDRESS" --mint_amount "$MINT_AMOUNT"

if [ $? -eq 0 ]; then
    log_message "1 billion ThinkPad tokens minted successfully."
else
    log_message "Failed to mint ThinkPad tokens."
fi

# Mint 1 million Bayeux tokens
log_message "Minting 1 million Bayeux tokens using mint_tokens.py..."
MINT_TO_ADDRESS="$PUBLIC_KEY"
MINT_AMOUNT=1000000000000000000000000  # 1 million tokens in wei
BAYEUX_TOKEN_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "Bayeux" "BYX" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
python3 mint_tokens.py --rpc_url "$RPC_URL" --private_key "$PRIVATE_KEY" --token_address "$BAYEUX_TOKEN_ADDRESS" --mint_to_address "$MINT_TO_ADDRESS" --mint_amount "$MINT_AMOUNT"

if [ $? -eq 0 ]; then
    log_message "1 million Bayeux tokens minted successfully."
else
    log_message "Failed to mint Bayeux tokens."
fi

# Mint 100k Tapestry Test Token tokens
log_message "Minting 100k Tapestry Test Token tokens using mint_tokens.py..."
MINT_AMOUNT=100000000000000000000000  # 100k tokens in wei
TAPESTRY_TOKEN_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "Tapestry Test Token" "TPSTY" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
python3 mint_tokens.py --rpc_url "$RPC_URL" --private_key "$PRIVATE_KEY" --token_address "$TAPESTRY_TOKEN_ADDRESS" --mint_to_address "$MINT_TO_ADDRESS" --mint_amount "$MINT_AMOUNT"

if [ $? -eq 0 ]; then
    log_message "100k Tapestry Test Token tokens minted successfully."
else
    log_message "Failed to mint Tapestry Test Token tokens."
fi

# Mint 650k Needle tokens
log_message "Minting 650k Needle tokens using mint_tokens.py..."
MINT_AMOUNT=650000000000000000000000  # 650k tokens in wei
NEEDLE_TOKEN_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "Needle" "NDL" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
python3 mint_tokens.py --rpc_url "$RPC_URL" --private_key "$PRIVATE_KEY" --token_address "$NEEDLE_TOKEN_ADDRESS" --mint_to_address "$MINT_TO_ADDRESS" --mint_amount "$MINT_AMOUNT"

if [ $? -eq 0 ]; then
    log_message "650k Needle tokens minted successfully."
else
    log_message "Failed to mint Needle tokens."
fi

# Mint 10 billion Faucet tokens
log_message "Minting 10 billion Faucet tokens using mint_tokens.py..."
MINT_AMOUNT=10000000000000000000000000000  # 10 billion tokens in wei
FAUCET_TOKEN_ADDRESS=$(forge create --rpc-url $RPC_URL  test/mocks/ERC20Mintable.sol:ERC20Mintable --constructor-args "Faucet" "FAUCET" --private-key $PRIVATE_KEY | grep "Deployed to" | awk '{print $3}')
python3 mint_tokens.py --rpc_url "$RPC_URL" --private_key "$PRIVATE_KEY" --token_address "$FAUCET_TOKEN_ADDRESS" --mint_to_address "$MINT_TO_ADDRESS" --mint_amount "$MINT_AMOUNT"

if [ $? -eq 0 ]; then
    log_message "10 billion Faucet tokens minted successfully."
else
    log_message "Failed to mint Faucet tokens."
fi


# Update addresses in UniswapV2FactoryTest.sol to include new addresses, handling cases where addresses may or may not be present
sed -i "s/IUniswapV2Factory(payable(\(0x[a-fA-F0-9]\{40\}\|''\)))/IUniswapV2Factory(payable($FACTORY_ADDRESS))/" test/UniswapV2FactoryTest.sol
sed -i "s/WETH(payable(\(0x[a-fA-F0-9]\{40\}\|''\)))/WETH(payable($WETH_ADDRESS))/" test/UniswapV2FactoryTest.sol
sed -i "s/IUniswapV2Router02(\(0x[a-fA-F0-9]\{40\}\|''\))/IUniswapV2Router02($ROUTER_ADDRESS)/" test/UniswapV2FactoryTest.sol
sed -i "s/\(ERC20Mintable token0 = ERC20Mintable(\)[^)]*\()\)/\1$TOKEN0_ADDRESS\2/" test/UniswapV2FactoryTest.sol
sed -i "s/\(ERC20Mintable token1 = ERC20Mintable(\)[^)]*\()\)/\1$TOKEN1_ADDRESS\2/" test/UniswapV2FactoryTest.sol
log_message "Updated UniswapV2FactoryTest.sol with newly deployed addresses"

# Update the RPC URL in the test file
sed -i "s|vm.createSelectFork(.*);|vm.createSelectFork(\"$RPC_URL\");|" test/UniswapV2FactoryTest.sol
log_message "Updated RPC URL in UniswapV2FactoryTest.sol to $RPC_URL"

# Update addresses in UniswapV2RouterTest.sol
sed -i "s/IUniswapV2Factory(payable(\(0x[a-fA-F0-9]\{40\}\|''\)))/IUniswapV2Factory(payable($FACTORY_ADDRESS))/" test/UniswapV2RouterTest.sol
sed -i "s/WETH(payable(\(0x[a-fA-F0-9]\{40\}\|''\)))/WETH(payable($WETH_ADDRESS))/" test/UniswapV2RouterTest.sol
sed -i "s/IUniswapV2Router02(\(0x[a-fA-F0-9]\{40\}\|''\))/IUniswapV2Router02($ROUTER_ADDRESS)/" test/UniswapV2RouterTest.sol
sed -i "s/\(ERC20Mintable tokenA = ERC20Mintable(\)[^)]*\()\)/\1$TOKEN_A_ADDRESS\2/" test/UniswapV2RouterTest.sol
sed -i "s/\(ERC20Mintable tokenB = ERC20Mintable(\)[^)]*\()\)/\1$TOKEN_B_ADDRESS\2/" test/UniswapV2RouterTest.sol
sed -i "s/\(ERC20Mintable tokenC = ERC20Mintable(\)[^)]*\()\)/\1$TOKEN_C_ADDRESS\2/" test/UniswapV2RouterTest.sol

# Update the JSON file with the new addresses
sed -i "s/\"address\": \"0x[a-fA-F0-9]\{40\}\"/\"address\": \"$WETH_ADDRESS\"/" "../interface/interface-2.6.4/src/constants/testnet-tokenlist.json"
sed -i "0,/\"address\": \"0x[a-fA-F0-9]\{40\}\"/s//\"address\": \"$THINKPAD_TOKEN_ADDRESS\"/" "../interface/interface-2.6.4/src/constants/testnet-tokenlist.json"
sed -i "0,/\"address\": \"0x[a-fA-F0-9]\{40\}\"/s//\"address\": \"$BAYEUX_TOKEN_ADDRESS\"/" "../interface/interface-2.6.4/src/constants/testnet-tokenlist.json"
sed -i "0,/\"address\": \"0x[a-fA-F0-9]\{40\}\"/s//\"address\": \"$TAPESTRY_TOKEN_ADDRESS\"/" "../interface/interface-2.6.4/src/constants/testnet-tokenlist.json"
sed -i "0,/\"address\": \"0x[a-fA-F0-9]\{40\}\"/s//\"address\": \"$NEEDLE_TOKEN_ADDRESS\"/" "../interface/interface-2.6.4/src/constants/testnet-tokenlist.json"

# Handling multiple ERC20Mintable address replacements with specific variables
awk -v tokenA="$TOKEN_A_ADDRESS" -v tokenB="$TOKEN_B_ADDRESS" -v tokenC="$TOKEN_C_ADDRESS" 'BEGIN{count=0;} /ERC20Mintable(\(0x[a-fA-F0-9]{40}\|()\))/ {count++; if(count==1){sub(/ERC20Mintable(\(0x[a-fA-F0-9]{40}\|()\))/, "ERC20Mintable(" tokenA ")");} else if(count==2){sub(/ERC20Mintable(\(0x[a-fA-F0-9]{40}\|()\))/, "ERC20Mintable(" tokenB ")");} else if(count==3){sub(/ERC20Mintable(\(0x[a-fA-F0-9]{40}\|()\))/, "ERC20Mintable(" tokenC ")");}} {print}' test/UniswapV2RouterTest.sol > test/temp.sol && mv test/temp.sol test/UniswapV2RouterTest.sol

# Update the RPC URL in another test file
sed -i "s|vm.createSelectFork(.*);|vm.createSelectFork(\"$RPC_URL\");|" test/UniswapV2RouterTest.sol

sed -i "s/export const ROUTER_ADDRESS = '\(0x[a-fA-F0-9]\{40\}\|''\)'/export const ROUTER_ADDRESS = '$ROUTER_ADDRESS'/" "../interface/interface-2.6.4/src/constants/index.ts"

if [ $? -eq 0 ]; then
    echo "Updated index.ts file with new ROUTER_ADDRESS: $ROUTER_ADDRESS"
else
    echo "Failed to update ROUTER_ADDRESS in index.ts"
fi

sed -i "s/\[ChainId\.WEAVE\]: '\(0x[a-fA-F0-9]\{40\}\|''\)'/[ChainId.WEAVE]: '$MULTICALL_ADDRESS'/" "../interface/interface-2.6.4/src/constants/multicall/index.ts"

if [ $? -eq 0 ]; then
    echo "Updated multicall index.ts file with new MULTICALL_ADDRESS: $MULTICALL_ADDRESS"
else
    echo "Failed to update MULTICALL_ADDRESS in multicall index.ts"
fi

# Log the changes
log_message "Updated UniswapV2RouterTest.sol with newly deployed addresses"
log_message "Updated RPC URL in UniswapV2RouterTest.sol to $RPC_URL"

log_message "Running tests..."
forge test
unset PUBLIC_KEY
unset PRIVATE_KEY

log_message "Deployment and tests completed. Check $OUTPUT_FILE for details."

# Prompt the user for consent to deploy contracts
printf "Would you like to build the interface and run it locally? (yes/no): "
read CONSENT

# Check the user's input and act accordingly
if [ "$CONSENT" = "yes" ] || [ "$CONSENT" = "y" ]; then
    echo "Beginning to build..."
    cd ../scripts/interface/
    sh build.sh
    sh start-local-interface.sh
else
    # Exit the script if the user does not consent
    echo "Deployment canceled."
    exit 0
fi

