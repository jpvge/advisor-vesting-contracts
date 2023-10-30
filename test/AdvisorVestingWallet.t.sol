// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {AdvisorVestingWallet} from "src/AdvisorVestingWallet.sol";

contract AdvisorVestingWalletTest is Test {
    using SafeTransferLib for address;

    AdvisorVestingWallet public immutable vesting;
    address public immutable projectOwner;
    address public immutable token;

    event WithdrawUnvested(uint256 amount);

    constructor() {
        vesting = new AdvisorVestingWallet(address(this));
        projectOwner = vesting.owner();
        token = vesting.TOKEN();
    }

    /*//////////////////////////////////////////////////////////////
                             withdrawUnvested
    //////////////////////////////////////////////////////////////*/

    function testCannotWithdrawUnvestedUnauthorized() external {
        address msgSender = address(0);

        assertTrue(msgSender != projectOwner);

        vm.expectRevert(Ownable.Unauthorized.selector);

        vesting.withdrawUnvested();
    }

    function testWithdrawUnvested() external {
        uint256 vestedPercent = 75;
        uint256 totalVestingAmount = 1e18;
        uint256 vestedPercentDenominator = 100;

        deal(vesting.TOKEN(), address(vesting), totalVestingAmount);

        vm.warp(
            uint256(vesting.start()) +
                ((uint256(vesting.duration()) * vestedPercent) /
                    vestedPercentDenominator)
        );

        uint256 withdrawableAmount = totalVestingAmount -
            (totalVestingAmount * vestedPercent) /
            vestedPercentDenominator;
        uint256 tokenBalanceBeforeWithdraw = token.balanceOf(projectOwner);

        vm.prank(projectOwner);
        vm.expectEmit(false, false, false, true, address(vesting));

        emit WithdrawUnvested(withdrawableAmount);

        vesting.withdrawUnvested();

        assertEq(
            tokenBalanceBeforeWithdraw + withdrawableAmount,
            token.balanceOf(projectOwner)
        );
    }

    function testWithdrawUnvestedFuzz(
        uint8 vestedPercent,
        uint80 totalVestingAmount
    ) external {
        vm.assume(vestedPercent <= 100);
        vm.assume(totalVestingAmount != 0);

        deal(vesting.TOKEN(), address(vesting), totalVestingAmount);

        uint256 vestedPercentDenominator = 100;

        // Set the timestamp anywhere from the vesting start to the end.
        vm.warp(
            uint256(vesting.start()) +
                ((uint256(vesting.duration()) * uint256(vestedPercent)) /
                    vestedPercentDenominator)
        );

        uint256 withdrawableAmount = uint256(totalVestingAmount) -
            (uint256(totalVestingAmount) * uint256(vestedPercent)) /
            vestedPercentDenominator;
        uint256 tokenBalanceBeforeWithdraw = token.balanceOf(projectOwner);

        vm.prank(projectOwner);
        vm.expectEmit(false, false, false, true, address(vesting));

        emit WithdrawUnvested(withdrawableAmount);

        vesting.withdrawUnvested();

        assertEq(
            tokenBalanceBeforeWithdraw + withdrawableAmount,
            token.balanceOf(projectOwner)
        );
    }
}
