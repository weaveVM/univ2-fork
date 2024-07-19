#!/bin/bash

# Define the output file for build process
OUTPUT_FILE="../logs/build_output.txt"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$OUTPUT_FILE"
}

# Change directory to contracts
cd ../../contracts
OUTPUT_FILE="../scripts/logs/build_output.txt"
log_message "Changed directory to $(pwd)"

# Updating and installing dependencies using Foundry
log_message "Updating Foundry and installing project dependencies"
forge update
forge install

# Locate the UniswapV2Pair.sol JSON file
log_message "Locating UniswapV2Pair.sol JSON file"
FILE_PATH=$(find out/ -name "UniswapV2Pair.json")
if [ -z "$FILE_PATH" ]; then
    log_message "Error: UniswapV2Pair.json not found"
    exit 1
else
    log_message "Found UniswapV2Pair.json at $FILE_PATH"
fi

# Extract the bytecode object using grep and sed for the specific pattern
log_message "Extracting bytecode hash"
BYTECODE_HASH=$(grep -Po '"bytecode":{"object":"\K(0x[a-fA-F0-9]+)' "$FILE_PATH")
if [ -z "$BYTECODE_HASH" ]; then
    log_message "Error: Bytecode hash not found"
    exit 1
else
    log_message "Extracted bytecode hash"
fi

# Calculate INIT_CODE_HASH using Python
log_message "Calculating INIT_CODE_HASH using Keccak-256"
INIT_CODE_HASH=$(python3 -c "import hashlib; print(hashlib.new('sha3_256', '$BYTECODE_HASH'.encode()).hexdigest())")
log_message "Calculated INIT_CODE_HASH: $INIT_CODE_HASH"

# Update INIT_CODE_HASH in UniswapV2Library.sol
#TODO doesn't work
log_message "Updating INIT_CODE_HASH in UniswapV2Library.sol"
sed -i "s/hex'\([a-f0-9]\{64\}\)'/hex'$INIT_CODE_HASH'/" lib/v2-periphery/contracts/libraries/UniswapV2Library.sol
log_message "Updated UniswapV2Library.sol with new INIT_CODE_HASH"

# Build the contracts using Forge
log_message "Building contracts with Forge"
forge build script/Imports.s.sol
log_message "Contracts built successfully"

# Update the INIT_CODE_HASH in the TypeScript constants file
log_message "Updating TypeScript constants file with new INIT_CODE_HASH"
sed -i "s/\(export const INIT_CODE_HASH = '\)[a-f0-9]\{64\}\('\)/\1$INIT_CODE_HASH\2/" ../interface/v2-sdk/src/constants.ts
log_message "Updated TypeScript constants.ts file const INIT_CODE_HASH to $INIT_CODE_HASH"

log_message "Script completed successfully"

# Prompt the user for consent to deploy contracts
printf "Would you like to deploy the contracts? (yes/no): "
read CONSENT

# Check the user's input and act accordingly
if [ "$CONSENT" = "yes" ] || [ "$CONSENT" = "y" ]; then
    # Call the function or script to deploy contracts
    echo "Starting deploy..."
    cd ../scripts/contracts/
    sh redeploy-v2-tests.sh
else
    # Exit the script if the user does not consent
    echo "Deployment canceled."
    exit 0
fi