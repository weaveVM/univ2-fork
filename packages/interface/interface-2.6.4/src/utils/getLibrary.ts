import { Web3Provider } from '@ethersproject/providers';

// Define the network ID you want to check against
const TARGET_NETWORK_ID = 9496;

async function switchNetwork(library: Web3Provider) {
  if (!library?.provider || !library?.provider?.request) return;
  try {
    await library.provider.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: '0x2518' }], // 9496 in hexadecimal
    });
  } catch (switchError) {
    // This error code indicates that the chain has not been added to MetaMask
    // @ts-ignore
    if (switchError?.code === 4902) {
      try {
        await library.provider.request({
          method: 'wallet_addEthereumChain',
          params: [
            {
              chainId: '0x2518', // 9496 in hexadecimal
              chainName: 'Testnet WeaveVM',
              nativeCurrency: {
                name: 'Testnet WVM',
                symbol: 'tWVM', // 2-6 characters long
                decimals: 18,
              },
              rpcUrls: ['https://testnet-rpc.wvm.dev'],
              blockExplorerUrls: ['https://explorer.wvm.dev'],
            },
          ],
        });
      } catch (addError) {
        console.error('Failed to add network:', addError);
      }
    } else {
      console.error('Failed to switch network:', switchError);
    }
  }
}

export default function getLibrary(provider: any): Web3Provider {
  const library = new Web3Provider(provider);
  library.pollingInterval = 15000;

  library.getNetwork().then((network) => {
    if (network.chainId !== TARGET_NETWORK_ID) {
      switchNetwork(library);
    }
  }).catch((error) => {
    console.error('Failed to get network:', error);
  });

  return library;
}
