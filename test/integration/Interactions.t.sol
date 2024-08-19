pragma solidity ^0.8.18;

import {FundMe} from "../../src/FundMe.sol";
import {DevOpsTools} from "foundry-devOps/DevOpsTools.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe} from "../../script/Interactions.s.sol";

contract FundMeInteraction is Test {
    FundMe fundMe;
    address owner;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 10 * 10 ** 18;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, SEND_VALUE);
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.deal(USER, SEND_VALUE);
        fundFundMe.fundFundMe(address(fundMe));
    }
}
