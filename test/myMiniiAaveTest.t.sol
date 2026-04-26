// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MyMiniAave} from "src/active/myMiniAave.sol";
import {AToken} from "src/active/myTokens/aToken.sol";
import {DebtToken} from "src/active/myTokens/debtToken.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mocks/mockV3Aggregator.sol";

contract MyMiniAaveTest is Test {
    MyMiniAave aave;

    ERC20Mock weth;
    ERC20Mock usdc;

    AToken aWeth;
    AToken aUsdc;

    DebtToken dWeth;
    DebtToken dUsdc;

    MockV3Aggregator wethFeed;
    MockV3Aggregator usdcFeed;

    address owner = address(this);
    address user = address(1);
    address user2 = address(2);
    address liquidator = address(3);

    uint8 constant DECIMALS = 8;
    int256 constant ETH_PRICE = 2000e8;
    int256 constant USDC_PRICE = 1e8;

    function setUp() public {
        aave = new MyMiniAave(owner);

        weth = new ERC20Mock();
        usdc = new ERC20Mock();

        aWeth = new AToken("MiniAave WETH Deposit Token", "aWETH", address(aave));
        aUsdc = new AToken("MiniAave USDC Deposit Token", "aUSDC", address(aave));

        dWeth = new DebtToken("MiniAave WETH Debt Token", "debtWETH", address(aave));
        dUsdc = new DebtToken("MiniAave USDC Debt Token", "debtUSDC", address(aave));

        wethFeed = new MockV3Aggregator(DECIMALS, ETH_PRICE);
        usdcFeed = new MockV3Aggregator(DECIMALS, USDC_PRICE);

        aave.initReserve(address(weth), address(aWeth), address(dWeth), 8000, 8500, 500, address(wethFeed));

        aave.initReserve(address(usdc), address(aUsdc), address(dUsdc), 9000, 9200, 500, address(usdcFeed));

        weth.mint(user, 1000 ether);
        usdc.mint(user, 1_000_000 ether);

        weth.mint(user2, 1000 ether);
        usdc.mint(user2, 1_000_000 ether);

        weth.mint(liquidator, 1000 ether);
        usdc.mint(liquidator, 1_000_000 ether);

        vm.startPrank(user);
        weth.approve(address(aave), type(uint256).max);
        usdc.approve(address(aave), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        weth.approve(address(aave), type(uint256).max);
        usdc.approve(address(aave), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        aave.deposit(500000 ether, address(usdc));
        vm.stopPrank();

        vm.startPrank(liquidator);
        weth.approve(address(aave), type(uint256).max);
        usdc.approve(address(aave), type(uint256).max);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////
    // INIT RESERVE TESTS
    //////////////////////////////////////////////////////

    function testReserveInitialized() public view {
        uint256 price = aave.getAssetPrice(address(weth));
        assertEq(price, 2000 ether);
    }

    function testCannotInitTwice() public {
        vm.expectRevert();
        aave.initReserve(address(weth), address(aWeth), address(dWeth), 8000, 8500, 500, address(wethFeed));
    }

    //////////////////////////////////////////////////////
    // DEPOSIT TESTS
    //////////////////////////////////////////////////////

    function testDeposit() public {
        vm.prank(user);
        aave.deposit(10 ether, address(weth));

        assertEq(aave.getBalance(user, address(weth)), 10 ether);
        assertEq(aWeth.balanceOf(user), 10 ether);
    }

    function testCannotDepositZero() public {
        vm.prank(user);
        vm.expectRevert();
        aave.deposit(0, address(weth));
    }

    //////////////////////////////////////////////////////
    // WITHDRAW TESTS
    //////////////////////////////////////////////////////

    function testWithdraw() public {
        vm.startPrank(user);
        aave.deposit(10 ether, address(weth));
        aave.withdraw(5 ether, address(weth));
        vm.stopPrank();

        assertEq(aave.getBalance(user, address(weth)), 5 ether);
    }

    function testCannotWithdrawTooMuch() public {
        vm.startPrank(user);
        aave.deposit(10 ether, address(weth));

        vm.expectRevert();
        aave.withdraw(20 ether, address(weth));
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////
    // BORROW TESTS
    //////////////////////////////////////////////////////

    function testBorrow() public {
        vm.startPrank(user);
        aave.deposit(10 ether, address(weth)); // $20k collateral
        aave.borrow(address(usdc), 1000 ether);
        vm.stopPrank();

        assertEq(dUsdc.balanceOf(user), 1000 ether);
    }

    function testCannotBorrowTooMuch() public {
        vm.startPrank(user);
        aave.deposit(1 ether, address(weth));

        vm.expectRevert();
        aave.borrow(address(usdc), 5000 ether);
        vm.stopPrank();
    }

    //////////////////////////////////////////////////////
    // REPAY TESTS
    //////////////////////////////////////////////////////

    function testRepay() public {
        vm.startPrank(user);

        aave.deposit(10 ether, address(weth));
        aave.borrow(address(usdc), 1000 ether);

        aave.repay(address(usdc), 500 ether);

        vm.stopPrank();

        assertEq(dUsdc.balanceOf(user), 500 ether);
    }

    function testRepayMoreThanDebtTurnsExtraToDeposit() public {
        vm.startPrank(user);

        aave.deposit(10 ether, address(weth));
        aave.borrow(address(usdc), 1000 ether);

        aave.repay(address(usdc), 1500 ether);

        vm.stopPrank();

        assertEq(dUsdc.balanceOf(user), 0);
        assertEq(aUsdc.balanceOf(user), 500 ether);
    }

    //////////////////////////////////////////////////////
    // VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////

    function testGetTotalCollateral() public {
        vm.prank(user);
        aave.deposit(1 ether, address(weth));

        assertEq(aave.getTotalCollateral(user), 2000 ether);
    }

    function testHealthFactorNoDebt() public view {
        uint256 hf = aave.calculateHealthFactor(user);
        assertEq(hf, type(uint256).max);
    }

    function testHealthFactorWithDebt() public {
        vm.startPrank(user);
        aave.deposit(10 ether, address(weth));
        aave.borrow(address(usdc), 1000 ether);
        vm.stopPrank();

        uint256 hf = aave.calculateHealthFactor(user);
        assertGt(hf, 1e18);
    }

    //////////////////////////////////////////////////////
    // LIQUIDATION TESTS
    //////////////////////////////////////////////////////

    function testLiquidation() public {
        vm.startPrank(user);
        aave.deposit(1 ether, address(weth)); // $2000
        aave.borrow(address(usdc), 1500 ether);
        vm.stopPrank();

        // ETH crashes to $1000
        wethFeed.updateAnswer(1000e8);

        assertTrue(aave.isLiquidatable(user));

        vm.prank(liquidator);
        aave.liquidate(user, address(usdc), address(weth), 500 ether);

        assertGt(weth.balanceOf(liquidator), 0);
    }

    function testCannotLiquidateHealthyUser() public {
        vm.startPrank(user);
        aave.deposit(10 ether, address(weth));
        aave.borrow(address(usdc), 1000 ether);
        vm.stopPrank();

        vm.prank(liquidator);
        vm.expectRevert();
        aave.liquidate(user, address(usdc), address(weth), 100 ether);
    }

    //////////////////////////////////////////////////////
    // PRICE TESTS
    //////////////////////////////////////////////////////

    function testPriceUpdates() public {
        wethFeed.updateAnswer(3000e8);

        uint256 price = aave.getAssetPrice(address(weth));
        assertEq(price, 3000 ether);
    }

    //////////////////////////////////////////////////////
    // NEW TESTS TO PUSH COVERAGE HIGHER
    //////////////////////////////////////////////////////

    //////////////////////////////////////////////////////
    // INIT RESERVE VALIDATION TESTS
    //////////////////////////////////////////////////////

    function testInitReserveInvalidLtv() public {
        vm.expectRevert();
        aave.initReserve(address(11), address(aWeth), address(dWeth), 10001, 8500, 500, address(wethFeed));
    }

    function testInitReserveLtvGreaterThanThreshold() public {
        vm.expectRevert();
        aave.initReserve(address(11), address(aWeth), address(dWeth), 9000, 8500, 500, address(wethFeed));
    }

    function testInitReserveBonusTooHigh() public {
        vm.expectRevert();
        aave.initReserve(address(11), address(aWeth), address(dWeth), 8000, 8500, 3000, address(wethFeed));
    }

    function testInitReserveBonusTooLow() public {
        vm.expectRevert();
        aave.initReserve(address(11), address(aWeth), address(dWeth), 8000, 8500, 50, address(wethFeed));
    }

    function testInitReserveZeroAsset() public {
        vm.expectRevert();
        aave.initReserve(address(0), address(aWeth), address(dWeth), 8000, 8500, 500, address(wethFeed));
    }

    function testInitReserveZeroAToken() public {
        vm.expectRevert();
        aave.initReserve(address(11), address(0), address(dWeth), 8000, 8500, 500, address(wethFeed));
    }

    function testInitReserveZeroDebtToken() public {
        vm.expectRevert();
        aave.initReserve(address(11), address(aWeth), address(0), 8000, 8500, 500, address(wethFeed));
    }

    function testInitReserveZeroPriceFeed() public {
        vm.expectRevert();
        aave.initReserve(address(11), address(aWeth), address(dWeth), 8000, 8500, 500, address(0));
    }

    //////////////////////////////////////////////////////
    // UNINITIALIZED RESERVE TESTS
    //////////////////////////////////////////////////////

    function testDepositUninitializedReserve() public {
        ERC20Mock token = new ERC20Mock();
        token.mint(user, 100 ether);

        vm.startPrank(user);
        token.approve(address(aave), type(uint256).max);

        vm.expectRevert();
        aave.deposit(1 ether, address(token));

        vm.stopPrank();
    }

    function testBorrowUninitializedReserve() public {
        vm.expectRevert();
        aave.borrow(address(999), 1 ether);
    }

    function testWithdrawUninitializedReserve() public {
        vm.expectRevert();
        aave.withdraw(1 ether, address(999));
    }

    function testRepayUninitializedReserve() public {
        vm.expectRevert();
        aave.repay(address(999), 1 ether);
    }

    //////////////////////////////////////////////////////
    // ZERO AMOUNT TESTS
    //////////////////////////////////////////////////////

    function testCannotWithdrawZero() public {
        vm.expectRevert();
        aave.withdraw(0, address(weth));
    }

    function testCannotBorrowZero() public {
        vm.expectRevert();
        aave.borrow(address(usdc), 0);
    }

    function testCannotRepayZero() public {
        vm.expectRevert();
        aave.repay(address(usdc), 0);
    }

    function testCannotLiquidateZero() public {
        vm.expectRevert();
        aave.liquidate(user, address(usdc), address(weth), 0);
    }

    //////////////////////////////////////////////////////
    // HEALTH FACTOR / WITHDRAW FAIL TEST
    //////////////////////////////////////////////////////

    function testCannotWithdrawIfHealthFactorBreaks() public {
        vm.startPrank(user);

        aave.deposit(1 ether, address(weth));
        aave.borrow(address(usdc), 1500 ether);

        vm.expectRevert();
        aave.withdraw(0.5 ether, address(weth));

        vm.stopPrank();
    }

    //////////////////////////////////////////////////////
    // ORACLE INVALID PRICE TESTS
    //////////////////////////////////////////////////////

    function testZeroPriceReverts() public {
        wethFeed.updateAnswer(0);

        vm.expectRevert();
        aave.getAssetPrice(address(weth));
    }

    function testNegativePriceReverts() public {
        wethFeed.updateAnswer(-1);

        vm.expectRevert();
        aave.getAssetPrice(address(weth));
    }

    //////////////////////////////////////////////////////
    // LIQUIDATION COLLATERAL CAP TEST
    //////////////////////////////////////////////////////

    function testLiquidationCapsCollateralToBalance() public {
        vm.startPrank(user);

        aave.deposit(1 ether, address(weth)); // 1 WETH collateral
        aave.borrow(address(usdc), 1800 ether);

        vm.stopPrank();

        wethFeed.updateAnswer(800e8); // WETH crashes

        vm.prank(liquidator);
        aave.liquidate(user, address(usdc), address(weth), 1800 ether);

        assertEq(aave.getBalance(user, address(weth)), 0);
    }

    //////////////////////////////////////////////////////
    // TOKEN ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////

    function testOnlyPoolCanMintAToken() public {
        vm.prank(user);

        vm.expectRevert();
        aWeth.mint(user, 1 ether);
    }

    function testOnlyPoolCanBurnAToken() public {
        vm.prank(user);

        vm.expectRevert();
        aWeth.burn(user, 1 ether);
    }

    function testOnlyPoolCanMintDebtToken() public {
        vm.prank(user);

        vm.expectRevert();
        dUsdc.mint(user, 1 ether);
    }

    function testOnlyPoolCanBurnDebtToken() public {
        vm.prank(user);

        vm.expectRevert();
        dUsdc.burn(user, 1 ether);
    }
}
