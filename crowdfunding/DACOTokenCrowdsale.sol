pragma solidity ^0.4.15;

import "../tokens/core/Ownable.sol";
import "../common/SafeMath.sol";
import "../tokens/MintableToken.sol";
import "./RefundVault.sol";
import "../tokens/DACOToken.sol";

/**
 * @title Crowdsale
 * @dev Modified contract for managing a token crowdsale.
 * DACOTokenCrowdsale have pre-sale and main sale periods, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate and the system of bonuses.
 * Funds collected are forwarded to a wallet as they arrive.
 * pre-sale and main sale periods both have caps defined in tokens
 */

contract DACOTokenCrowdsale is Ownable {

    using SafeMath for uint256;

    // minimum amount of funds to be raised in weis
    uint256 public goal;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    // true for finalised crowdsale
    bool public isFinalized;

    // The token being sold
    address public token;

    uint256 public mainSaleWeiCap;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // campaign description
    string public description;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event FinalisedCrowdsale(uint256 totalSupply, uint256 minterBenefit);

    function DACOTokenCrowdsale(uint256 _mainSaleWeiCap, uint256 _rate, address _token, address _wallet, string _description) public {
        require(_mainSaleWeiCap > 0);
        require(_rate > 0);
        require(_wallet != 0x0);

        mainSaleWeiCap = _mainSaleWeiCap;
        rate = _rate;
        token = _token;
        wallet = _wallet;
        description = _description;

        isFinalized = false;
    }

    // fallback function can be used to buy tokens
    function() payable {
        donate(msg.sender);
    }

    // low level token purchase function
    function donate(address investor) public payable {
        require(investor != 0x0);
        require(msg.value != 0);
        require(!isFinalized);
        require(!goalReached());
        // update state
        uint256 change = 0;
        uint256 amount = msg.value;
        uint256 wantage = mainSaleWeiCap - weiRaised;
        if (amount > wantage) {
            change = amount - wantage;
            amount = wantage;
        }
        if (change > 0) {
            investor.transfer(change);
        }
        uint256 tokens = amount.mul(rate);
        wallet.transfer(amount);
//        investor.call(bytes4(sha3("transfer(address, uint256)")),investor, tokens);
        DACOToken(token).transfer(investor, tokens);
        weiRaised = weiRaised.add(wantage);
    }

    // set company finalization status
    function setFinalized() public onlyOwner {
        isFinalized = true;
    }

    // set new wallets (emergency case)
    function setWallets(address _wallet) public onlyOwner {
        require(!isFinalized);
        require(_wallet != 0x0);
        wallet = _wallet;
    }

    // set new rate (emergency case)
    function setRate(uint256 _rate) public onlyOwner {
        require(!isFinalized);
        require(_rate > 0);
        rate = _rate;
    }

    // set new goal (emergency case)
    function setGoal(uint256 _mainSaleWeiCap) public onlyOwner {
        require(!isFinalized);
        require(_mainSaleWeiCap > 0);
        mainSaleWeiCap = _mainSaleWeiCap;
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= mainSaleWeiCap;
    }
}