pragma solidity ^0.4.15;

import "../tokens/core/Ownable.sol";
import "common/math.sol";

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

    // wel token emission
    uint256 public tokenEmission;

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

    uint256 public mainSaleMinimumWei;

    uint256 public defaultPercent;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event FinalisedCrowdsale(uint256 totalSupply, uint256 minterBenefit);

    function DACOTokenCrowdsale(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, uint256 _mainSaleWeiCap, uint256 _goal, uint256 _rate, address _wallet, address _tokenWallet) public {

        require(_goal > 0);

        // can't start main sale in the past
        require(_mainSaleStartTime >= now);

        // the end of main sale can't happen before it's start
        require(_mainSaleStartTime < _mainSaleEndTime);

        require(_rate > 0);
        require(_mainSaleWeiCap > 0);
        require(_wallet != 0x0);
        require(_tokenWallet != 0x0);

        mainSaleMinimumWei = 300000000000000000;
        // 0.3 Ether default minimum
        defaultPercent = 0;

        tokenEmission = 150000000 ether;

        mainSaleStartTime = _mainSaleStartTime;
        mainSaleEndTime = _mainSaleEndTime;
        mainSaleWeiCap = _mainSaleWeiCap;
        goal = _goal;
        rate = _rate;
        wallet = _wallet;
        tokenWallet = _tokenWallet;

        isFinalized = false;

        token = new DACOToken();
        vault = new RefundVault(wallet);
    }

    // fallback function can be used to buy tokens
    function() payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {

        require(beneficiary != 0x0);
        require(msg.value != 0);
        require(!isFinalized);

        uint256 weiAmount = msg.value;

        validateWithinPeriods();
        validateWithinCaps(weiAmount);

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount);

        forwardFunds();
    }

    // owner can mint tokens during crowdsale withing defined caps
    function mintTokens(address beneficiary, uint256 weiAmount, uint256 forcePercent) external onlyOwner returns (bool) {

        require(forcePercent <= 100);
        require(beneficiary != 0x0);
        require(weiAmount != 0);
        require(!isFinalized);

        validateWithinCaps(weiAmount);

        uint256 percent = 0;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        token.mint(beneficiary);
        TokenPurchase(msg.sender, beneficiary, weiAmount);
    }

    // set new dates for main-sale (emergency case)
    function setMainSaleParameters(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, uint256 _mainSaleWeiCap, uint256 _mainSaleMinimumWei) public onlyOwner {
        require(!isFinalized);
        require(_mainSaleStartTime < _mainSaleEndTime);
        require(_mainSaleWeiCap > 0);
        mainSaleStartTime = _mainSaleStartTime;
        mainSaleEndTime = _mainSaleEndTime;
        mainSaleWeiCap = _mainSaleWeiCap;
        mainSaleMinimumWei = _mainSaleMinimumWei;
    }

    // set new wallets (emergency case)
    function setWallets(address _wallet, address _tokenWallet) public onlyOwner {
        require(!isFinalized);
        require(_wallet != 0x0);
        require(_tokenWallet != 0x0);
        wallet = _wallet;
        tokenWallet = _tokenWallet;
    }

    // set new rate (emergency case)
    function setRate(uint256 _rate) public onlyOwner {
        require(!isFinalized);
        require(_rate > 0);
        rate = _rate;
    }

    // set new goal (emergency case)
    function setGoal(uint256 _goal) public onlyOwner {
        require(!isFinalized);
        require(_goal > 0);
        goal = _goal;
    }


    // set token on pause
    function pauseToken() external onlyOwner {
        require(!isFinalized);
        DACOToken(token).pause();
    }

    // unset token's pause
    function unpauseToken() external onlyOwner {
        DACOToken(token).unpause();
    }

    // set token Ownership
    function transferTokenOwnership(address newOwner) external onlyOwner {
        DACOToken(token).transferOwnership(newOwner);
    }

    // @return true if main sale event has ended
    function mainSaleHasEnded() external constant returns (bool) {
        return now > mainSaleEndTime;
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        //wallet.transfer(msg.value);
        vault.deposit.value(msg.value)(msg.sender);
    }

    function applyBonus(uint256 tokens) internal constant returns (uint256 bonusedTokens) {
        uint256 tokensToAdd = tokens.div(100);
        return tokens.add(tokensToAdd);
    }

    function validateWithinPeriods() internal constant {
        // within pre-sale or main sale
        require(now >= mainSaleStartTime && now <= mainSaleEndTime);
    }

    function validateWithinCaps(uint256 weiAmount) internal constant {
        uint256 expectedWeiRaised = weiRaised.add(weiAmount);

        // within main sale
        if (now >= mainSaleStartTime && now <= mainSaleEndTime) {
            require(expectedWeiRaised <= mainSaleWeiCap);
        }
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

    // finish crowdsale,
    // take totalSupply as 90% and mint 10% more to specified owner's wallet
    // then stop minting forever

    function finaliseCrowdsale() external onlyOwner returns (bool) {
        require(!isFinalized);
        uint256 totalSupply = token.totalSupply();
        uint256 minterBenefit = tokenEmission.sub(totalSupply);
        if (goalReached()) {
            token.mint(tokenWallet, minterBenefit);
            vault.close();
            //token.finishMinting();
        } else {
            vault.enableRefunds();
        }

        FinalisedCrowdsale(totalSupply, minterBenefit);
        isFinalized = true;
        return true;
    }

}