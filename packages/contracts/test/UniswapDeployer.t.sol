// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity >=0.8.5;

// import {Test} from "forge-std/Test.sol";
// import {UniswapDeployer} from "../script/UniswapDeployer.s.sol";
// import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import {IUniswapV2Router01} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
// import {WETH} from "solmate/tokens/WETH.sol";

// import {Token} from "../src/Token.sol";

// contract UniswapTests is Test {
//     IUniswapV2Factory factory = IUniswapV2Factory(makeAddr("UniswapV2Factory"));

//     WETH deployedWeth = WETH(payable(makeAddr("WETH")));

//     IUniswapV2Router02 router =
//         IUniswapV2Router02(makeAddr("UniswapV2Router02"));

//     function setUp() public {
//         UniswapDeployer deployer = new UniswapDeployer();
//         deployer.run();
//     }

//     function test_uniswapFactory() public view {
//         assert(factory.feeToSetter() != address(0));
//     }
//     function test_wrappedEther() public view {
//         assert(abi.encode(deployedWeth.name()).length > 0);
//     }

//     function test_deployedRouter() public view {
//         assert(router.WETH() != address(0));
//     }
// }
