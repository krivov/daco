pragma solidity ^0.4.15;

import "./MintableToken.sol";

contract KARMAToken is MintableToken {
    string public constant name = "DACO KARMA Token";
    string public constant symbol = "KARMA";
    uint8 public constant decimals = 18;

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Transfering is prohobited
        return false;
    }
}
