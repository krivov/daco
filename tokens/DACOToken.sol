pragma solidity ^0.4.15;

import "../common/SafeMath.sol";
import "./MintableToken.sol";
import "./EmptyToken.sol";
import "./PausableToken.sol";

contract DACOToken is MintableToken {
    string public constant name = "DACO Loyality token";
    string public constant symbol = "DACOL";
    uint8 public constant decimals = 18;
    EmptyToken public empty_token;

    function DACOToken() public {
        empty_token = new EmptyToken();
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (msg.sender == _to) {
            super.transfer(_to, _value);
        } else {
            require(_to != address(0));
            require(_value <= balances[msg.sender]);

            // SafeMath.sub will throw if there is not enough balance.
            balances[msg.sender] = balances[msg.sender].sub(_value);

            // Mint EmptyToken to receiver
            empty_token.mint(_to, _value);
            Transfer(msg.sender, _to, _value);
        }
        return true;
    }
}