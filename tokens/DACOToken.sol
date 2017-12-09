pragma solidity ^0.4.15;

import "../common/SafeMath.sol";
import "./MintableToken.sol";
import "./PausableToken.sol";

contract DACOToken is MintableToken, PausableToken {
    string public constant name = "DACO Loyality token";
    string public constant symbol = "DACO";
    uint8 public constant decimals = 18;
}