pragma solidity ^0.4.15;

import "./MintableToken.sol";

contract EmptyToken is MintableToken {
    string public constant name = "DACO Empty token";
    string public constant symbol = "DACOE";
    uint8 public constant decimals = 18;

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Transfering is prohobited
        return false;
    }
}