pragma solidity >=0.8.5;

import {Test, console2} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import {ERC20Mintable} from "test/mocks/ERC20Mintable.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract UniswapV2FactoryTest is Test {
    IUniswapV2Factory public factory =
        IUniswapV2Factory(0x769342223Dd222099A0bEBcbF8Edab64fD339E61);

    WETH public weth =
        WETH(payable(0x40877681D53921DA8cF3c919B64aa8A56D2178aD));

    IUniswapV2Router02 public router =
        IUniswapV2Router02(0xffC15e84Ab6604fC0DC7edCC361C7653EB616211);

    ERC20Mintable token0;
    ERC20Mintable token1;
    ERC20Mintable token2;
    ERC20Mintable token3;

    function setUp() public {
        vm.createFork("https://testnet-rpc.wvm.dev");
        
        // //Deploy UniswapV2Factory
        // deployCodeTo(
        //     "UniswapV2Factory.sol:UniswapV2Factory",
        //     abi.encode(address(0x769342223dd222099a0bebcbf8edab64fd339e61)),
        //     makeAddr("UniswapV2Factory")
        // );

        // //Deploy UniswapV2Router02
        // deployCodeTo(
        //     "UniswapV2Router02.sol:UniswapV2Router02",
        //     abi.encode(
        //         makeAddr("UniswapV2Factory"),
        //         0xffc15e84ab6604fc0dc7edcc361c7653eb616211
        //     ),
        //     makeAddr("UniswapV2Router02")
        // );

        token0 = new ERC20Mintable("Token A", "TKNA");
        token1 = new ERC20Mintable("Token B", "TKNB");
        token2 = new ERC20Mintable("Token C", "TKNC");
        token3 = new ERC20Mintable("Token D", "TKND");
    }

    //#################################################### UniswapV2Factory Tests ############################################

    function testCreatePair() public {
        address pairAddress = factory.createPair(
            address(weth),
            address(token0)
        );

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(weth));
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
