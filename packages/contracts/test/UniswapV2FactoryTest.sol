pragma solidity >=0.8.5;

import {Test, console2} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import {ERC20Mintable} from "test/mocks/ERC20Mintable.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract UniswapV2FactoryTest is Test {
    IUniswapV2Factory public factory = IUniswapV2Factory(0x41edf1bdAA3EC70cD8E8a25f76b3F5a9A7284D9B);
        // IUniswapV2Factory(makeAddr("UniswapV2Factory"));

    WETH public weth;
        //WETH(payable(0x40877681D53921DA8cF3c919B64aa8A56D2178aD));

    IUniswapV2Router02 public router = //IUniswapV2Router02(0xffC15e84Ab6604fC0DC7edCC361C7653EB616211);
        IUniswapV2Router02(makeAddr("UniswapV2Router02"));

    ERC20Mintable token0 = ERC20Mintable(0x6F4b9c4D1d98D077DF40ECA9a52ad674ba89A466);
    ERC20Mintable token1 = ERC20Mintable(0x83f6e61a32b4b4bB4b894823B99e9F18b91167Ff);

    function setUp() public {
        vm.createSelectFork("https://testnet-rpc.wvm.dev"); // WVM RPC Endpoint
    }

    //#################################################### UniswapV2Factory Tests ############################################

    function testCreatePair() public {
        address pairAddress = factory.createPair(
            address(token1),
            address(token0)
        );

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(token1));
    }

    function testCreatePairZeroAddress() public {
        vm.expectRevert("UniswapV2: ZERO_ADDRESS");
        factory.createPair(address(0), address(token0));

        vm.expectRevert("UniswapV2: ZERO_ADDRESS");
        factory.createPair(address(token1), address(0));
    }

    function testCreatePairPairExists() public {
        factory.createPair(address(token1), address(token0));

        vm.expectRevert("UniswapV2: PAIR_EXISTS");
        factory.createPair(address(token1), address(token0));
    }

    function testCreatePairIdenticalTokens() public {
        vm.expectRevert("UniswapV2: IDENTICAL_ADDRESSES");
        factory.createPair(address(token0), address(token0));
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }
}