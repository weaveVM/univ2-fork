pragma solidity >=0.8.5;

import {Test, console2} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract UniswapV2FactoryTest is Test {
    IUniswapV2Factory public factory =
        IUniswapV2Factory(0x1765dd6dC1CDDf3dc2a9A4337ec8b2b5CEfeb787);

    WETH public weth =
        WETH(payable(0x87801a016B7E2361C1Fad8f7E4e347Ae587c4a69));

    IUniswapV2Router02 public router =
        IUniswapV2Router02(0xc96bd3c500951b8dF5705e7FFc315416FC073F43);

    ERC20Mintable token0 = ERC20Mintable(0x0d44529D8dcF6734221936b0A986e70E475ac967);
    ERC20Mintable token1 = ERC20Mintable(0xe6Bc016D2621aDe926Bc566FB87Bc44dbd0A4Ae2);

    function setUp() public {
        vm.createSelectFork("https://testnet-rpc.wvm.dev"); // WVM RPC Endpoint
    }

    //#################################################### UniswapV2Factory Tests ############################################

    function testCreatePair() public {
        address pairAddress = factory.createPair(
            address(token1),
            address(weth)
        );

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(weth));
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
