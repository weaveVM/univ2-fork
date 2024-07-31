# meant for local running
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # load nvm
# nvm use 14

# Install packages for v2-sdk and build it
yarn --cwd ../../interface/v2-sdk install
yarn --cwd ../../interface/v2-sdk build

# Make this package locally-public, so v2-sdk could be used in interface-2.6.4
yarn link --cwd ../../interface/v2-sdk

# This will work locally, however, for next.js, we'll assume the package name is @uniswap/sdk
# package_name=$(node -e "console.log(require('../../interface/v2-sdk/package.json').name);")

package_name="@uniswap/sdk"

# Link the package in the interface
yarn link $package_name --cwd ../../interface/interface-2.6.4

# Install interface-2.6.4
yarn --cwd ../../interface/interface-2.6.4 install --ignore-engines
