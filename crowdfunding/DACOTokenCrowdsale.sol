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
    MintableToken public token;

    // start and end timestamps where main-investments are allowed (both inclusive)
    uint256 public mainSaleStartTime;
    uint256 public mainSaleEndTime;

    // maximum amout of wei for pre-sale and main sale
    uint256 public preSaleWeiCap;
    uint256 public mainSaleWeiCap;

    // address where funds are collected
    address public wallet;

    // address where final 10% of funds will be collected
    address public tokenWallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    uint256 public defaultPercent;


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

    function DACOTokenCrowdsale(uint256 _mainSaleWeiCap, uint256 _rate, address _wallet, string _description) public {
        require(_mainSaleWeiCap > 0);
        require(_rate > 0);
        require(_wallet != 0x0);

        goal = _mainSaleWeiCap;
        rate = _rate;
        wallet = _wallet;
        description = _description;

        isFinalized = false;

        token = new DACOToken();
        vault = new RefundVault(wallet);
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

        uint256 weiAmount = msg.value;

        validateWithinCaps(weiAmount);

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        token.mint(investor, tokens);
        forwardFunds();
    }

    //send ether to the fund collection of the wallet
    function sendFunds(uint256 amount) public payable {
        require(!isFinalized);
        require(!goalReached());
        require(vault.hasSum(msg.sender, msg.value + msg.gas));
        wallet.transfer(msg.value);
        vault.refund(msg.sender);
    }

    // set company finalization status
    function setFinalized(bool _finalized) public onlyOwner {
        isFinalized = _finalized;
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

    // set token Ownership
    function transferTokenOwnership(address newOwner) external onlyOwner {
        DACOToken(token).transferOwnership(newOwner);
    }

    function validateWithinCaps(uint256 weiAmount) internal constant {
        uint256 expectedWeiRaised = weiRaised.add(weiAmount);
        require(expectedWeiRaised <= mainSaleWeiCap);
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());
        vault.refund(msg.sender);
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }
}