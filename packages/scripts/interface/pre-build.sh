[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # load nvm
nvm use 14
# Install and build v2-sdk
yarn --cwd ../../interface/v2-sdk install
yarn --cwd ../../interface/v2-sdk build
# Install interface-2.6.4
yarn --cwd ../../interface/interface-2.6.4 install --ignore-engines