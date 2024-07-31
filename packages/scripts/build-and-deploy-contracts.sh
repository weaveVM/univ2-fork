#!/bin/bash

# Define the output file
OUTPUT_FILE="logs/redeploy_output.txt"

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

cd ../contracts

sh ./build-tests.sh
