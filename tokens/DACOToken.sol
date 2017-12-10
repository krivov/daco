pragma solidity ^0.4.15;

import "../common/SafeMath.sol";
import "./MintableToken.sol";
import "./KARMAToken.sol";

contract DACOToken is MintableToken {
  string public constant name = "DACO Loyality Token";
  string public constant symbol = "DACO";
  uint8 public constant decimals = 18;
  KARMAToken public karma_token;
  mapping(address => uint8) campaigns;
  
  function DACOToken() public {
      karma_token = new KARMAToken();
  }
  
  function addCampaign(address _campaign) onlyOwner public {
      require(campaigns[_campaign] == 0);
      campaigns[_campaign] = 1;
  }
  
  function removeCampaign(address _campaign) onlyOwner public {
      require(campaigns[_campaign] != 0);
      delete campaigns[_campaign];
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (campaigns[msg.sender] != 0) {
        // Transfer if sender is crowdfunding compaign
        super.transfer(_to, _value);
    } else {
        // Otherwise destroy DACO token and mint KARMA token
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        
        // Mint EmptyToken to receiver
        karma_token.mint(_to, _value);
        Transfer(msg.sender, _to, _value);
    }
    return true;
  }
}
