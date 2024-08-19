// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address owner;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 10 * 10 ** 18;

    function setUp() external {
        DeployFundMe deployFundeMe = new DeployFundMe();
        owner = address(this);
        fundMe = deployFundeMe.run();
        vm.deal(USER, SEND_VALUE);
    }

    modifier fundUser() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumDollarIsFive() public view {
        uint256 expectedValue = 5 * 10 ** 18;
        uint256 contractValue = fundMe.MINIMUM_USD();
        assertEq(
            contractValue,
            expectedValue,
            "Minimum USD value is not correct"
        );
    }

    function testOwnerIsMsgSender() public view {
        address contractOwner = fundMe.i_owner();
        assertEq(contractOwner, msg.sender, "Owner is not the deployer");
    }

    function testGetVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithNotEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public fundUser {
        uint256 fundedAmount = fundMe.getAddressToAmountFunded(USER);
        assertEq(fundedAmount, SEND_VALUE, "Funded amount is not correct");
    }

    function testAddsFunderToTheFundersArray() public fundUser {
        address funders = fundMe.getFunder(0);
        assertEq(funders, USER, "Funder is not correct");
    }

    function testOnlyOwnerCanWithdraw() public fundUser {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public fundUser {
        //Arrange

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0, "FundMe balance is not correct");
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance,
            "Owner balance is not correct"
        );
    }

    function testWithdrawWithMultipleFunders() public fundUser {
        //Arrange
        uint160 noOfFunders = 10;
        uint160 startingIndex = 1;

        for (uint160 i = startingIndex; i < noOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert

        assert(address(fundMe).balance == 0);
        assert(
            fundMe.getOwner().balance ==
                startingOwnerBalance + startingFundMeBalance
        );
    }
}
