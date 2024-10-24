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
        IUniswapV2Factory(0xB4CC3075b1B77b5A7AB6154C78E8aC69c4Fd2B2a);

    WETH public weth =
        WETH(payable(0x28aF5AcBD23B4A1AbD9F68b60427B2C3500021a3));

    IUniswapV2Router02 public router =
        IUniswapV2Router02(0xF94bFaC946600d37e19b63D308FEe3527BE0CC10);

    ERC20Mintable token0 =
        ERC20Mintable(0x56367cCC752DaAb2194040814343f331941C5C4a);
    ERC20Mintable token1 =
        ERC20Mintable(0x7c14665dA42a3c694D6320ac80ad37Bf3b39d855);

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
        address token0 = address(weth) < address(token1) ? address(weth) : address(token1);
        address token1 = address(weth) < address(token1) ? address(token1) : address(weth);

        assertEq(pair.token0(), token0);
        assertEq(pair.token1(), token1);
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
