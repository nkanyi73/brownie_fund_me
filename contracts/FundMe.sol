//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {

    //library that checks the overflows
    using SafeMathChainlink for uint256;
    //mapping to keep track of who and how much they sent
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;
    //constructor that creates the owner of the contract
    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    } 
    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18;

        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");
        //save it to the mapping
        addressToAmountFunded[msg.sender] += msg.value;
        // what the ETH -> USD conversion rate is
        //Oracles are the bridge between blockchains and real world systems
        funders.push(msg.sender);

    }
    
    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }


    function getVersion() public view returns (uint256){
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256){
        (
            ,int256 answer,,,
        ) = priceFeed.latestRoundData();
        //return price with 18dp
        return uint256(answer * 10000000000);
    }

    //answers are 10^8
    function getConversionRate (uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    //modifiers are used to change the behaviors of functions in a non declarative way
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    //function to withdraw the money sent/contributed

    function withdraw() payable onlyOwner public {
        //(using the modifier)
        //withdraw and send the money to the sender's address
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address [](0);
    }

}