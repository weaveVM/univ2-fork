pragma solidity >=0.8.5;

import {Test, console2} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import {ERC20Mintable} from "./mocks/ERC20Mintable.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract UniswapV2RouterTest is Test {
    IUniswapV2Factory public factory =
        IUniswapV2Factory(0xB4CC3075b1B77b5A7AB6154C78E8aC69c4Fd2B2a);

    WETH public weth = WETH(payable(0x1a3Dd576467eAb8189796da67e4AE1df8afF6422));

    IUniswapV2Router02 public router =
        IUniswapV2Router02(0x120040D577Bc571B07A646536f40a7398A886461);

    ERC20Mintable tokenA =
        ERC20Mintable(0x56367cCC752DaAb2194040814343f331941C5C4a);
    ERC20Mintable tokenB =
        ERC20Mintable(0x7c14665dA42a3c694D6320ac80ad37Bf3b39d855);
    ERC20Mintable tokenC =
        ERC20Mintable(0x605Fd139C10abc88aEa6d8Db720C63bE62802bbe);
    function setUp() public {
        // Fork the blockchain
        console2.log("Forking the blockchain...");
        vm.createSelectFork("https://testnet-rpc.wvm.dev");

        // Mint tokenA
        console2.log("Minting tokenA...");
        try tokenA.mint(20 ether, address(this)) {
            console2.log("Minted tokenA successfully");
        } catch Error(string memory reason) {
            console2.log(reason);
        } catch (bytes memory reason) {
            console2.logBytes(reason);
        }

        // Mint tokenB
        console2.log("Minting tokenB...");
        try tokenB.mint(20 ether, address(this)) {
            console2.log("Minted tokenB successfully");
        } catch Error(string memory reason) {
            console2.log(reason);
        } catch (bytes memory reason) {
            console2.logBytes(reason);
        }

        // Mint tokenC
        console2.log("Minting tokenC...");
        try tokenC.mint(20 ether, address(this)) {
            console2.log("Minted tokenC successfully");
        } catch Error(string memory reason) {
            console2.log(reason);
        } catch (bytes memory reason) {
            console2.logBytes(reason);
        }
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

 function testAddLiquidityCreatesPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this),
            block.timestamp
        );

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        assertEq(pairAddress, 0x3A52e781CDf306DA5643Bf8e5FEb7403d352B3b1);
    }
    function testAddLiquidityNoPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                1 ether,
                1 ether,
                1 ether,
                1 ether,
                address(this),
                block.timestamp
            );

        assertEq(amountA, 1 ether);
        assertEq(amountB, 1 ether);
        assertEq(liquidity, 1 ether - 1000);

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));

        assertEq(tokenA.balanceOf(pairAddress), 1 ether);
        assertEq(tokenB.balanceOf(pairAddress), 1 ether);

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenA));
        assertEq(pair.token1(), address(tokenB));
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);

        assertEq(tokenA.balanceOf(address(this)), 19 ether);
        assertEq(tokenB.balanceOf(address(this)), 19 ether);
    }

    function testAddLiquidityAmountBOptimalIsTooLow() public {
        address pairAddress = factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        assertEq(pair.token0(), address(tokenA));
        assertEq(pair.token1(), address(tokenB));

        tokenA.transfer(pairAddress, 5 ether);
        tokenB.transfer(pairAddress, 10 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);

        vm.expectRevert("UniswapV2Router: INSUFFICIENT_B_AMOUNT");
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            2 ether,
            1.5 ether,
            2.5 ether,
            address(this),
            block.timestamp
        );
    }

    function testAddLiquidityAmountBOptimalTooHighAmountATooLow() public {
        address pairAddress = factory.createPair(
            address(tokenA),
            address(tokenB)
        );
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenA));
        assertEq(pair.token1(), address(tokenB));

        tokenA.transfer(pairAddress, 10 ether);
        tokenB.transfer(pairAddress, 5 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 1 ether);

        vm.expectRevert("UniswapV2Router: INSUFFICIENT_A_AMOUNT");
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            2 ether,
            0.9 ether,
            2 ether,
            1 ether,
            address(this),
            block.timestamp
        );
    }

    function testRemoveLiquidity() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this),
            block.timestamp
        );

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        pair.approve(address(router), liquidity);

        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            1 ether - 1000,
            1 ether - 1000,
            address(this),
            block.timestamp
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        assertEq(reserve0, 1000);
        assertEq(reserve1, 1000);
        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 1000);
        assertEq(tokenA.balanceOf(address(this)), 20 ether - 1000);
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 1000);
    }

    function testRemoveLiquidityPartially() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this),
            block.timestamp
        );

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        liquidity = (liquidity * 3) / 10;
        pair.approve(address(router), liquidity);

        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0.3 ether - 300,
            0.3 ether - 300,
            address(this),
            block.timestamp
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        assertEq(reserve0, 0.7 ether + 300);
        assertEq(reserve1, 0.7 ether + 300);
        assertEq(pair.balanceOf(address(this)), 0.7 ether - 700);
        assertEq(pair.totalSupply(), 0.7 ether + 300);
        assertEq(tokenA.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
    }

    function testSwapExactTokensForTokens() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);
        tokenC.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this),
            block.timestamp
        );

        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this),
            block.timestamp
        );

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        tokenA.approve(address(router), 0.3 ether);
        router.swapExactTokensForTokens(
            0.3 ether,
            0.1 ether,
            path,
            address(this),
            block.timestamp
        );

        // Swap 0.3 TKNA for ~0.186 TKNB
        assertEq(
            tokenA.balanceOf(address(this)),
            20 ether - 1 ether - 0.3 ether
        );
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 2 ether);
        assertEq(
            tokenC.balanceOf(address(this)),
            20 ether - 1 ether + 0.186691414219734305 ether
        );
    }
}
