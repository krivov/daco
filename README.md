# DACO :green_heart: Decentralized Autonomous Charity Organization

## DACO API

### contract [DACOMain](https://github.com/krivov/daco/blob/master/DACOMain.sol) is Ownable:
Improved congress contract by [Ethereum Foundation](https://www.ethereum.org/dao#the-blockchain-congress)
#### methods:
Append new congress member
* *targetMember* - member account address
* *memberName* - member full name
```solidity
function addMember(
    address targetMember, 
    string memberName
) public onlyOwner { ... }
```

Proposal voting
* *id* - proposal identifier
```solidity
function vote(
    uint256 id
) public onlyMembers { ... }
```

Create a new campaign
* *_wallet* - beneficiary wallet address
* *_amount* - hardCap value in Wei
* *_description* - campaign description string
```solidity
function newCampaign(
    address _wallet, 
    uint256 _amount, 
    string  _description
) public onlyMembers { ... }
```

Change rules of voting
* *minimumQuorumForProposals* - minimal count of votes
* *minutesForDebate* - debate deadline in minutes
* *marginOfVotesForMajority* - majority margin value
```solidity
function changeVotingRules(
    uint256 minimumQuorumForProposals,
    uint256 minutesForDebate,
    uint256 marginOfVotesForMajority
) public onlyOwner { ... }
```

Remove congress member
* *targetMember* - member account address
```solidity
function removeMember(
    address targetMember
) public onlyOwner { ... }
```

Create a new proposal
* *wallet* - beneficiary account address
* *amount* - transaction value in Eth
* *description* - job description string
```solidity
function newProposal(
    address wallet,
    uint256 amount,
    string  description
) public returns (uint256 id) { ... }
```

Set new rate value
* *_rate* - factor of convertion wei -> daco token
```solidity
function setRate(
    uint256 _rate
) public onlyOwner returns (bool) { ... }
```


### contract [DACOTokenCrowdsale](https://github.com/krivov/daco/blob/master/DACOTokenCrowdsale.sol) is Ownable:
Contract that allows to donate funds to compaign and to close compaign.
#### methods:
Low level token purchase function:
```solidity
function donate(
   address investor
) payable { ... }
```
* *investor* - donator account address

Campaign finalization:
```solidity
function setFinalized() public onlyOwner { ... }
```

### contract [KARMAToken](https://github.com/krivov/daco/blob/master/tokens/KARMAToken.sol) is MintableToken:
Special kind of token that used for user reputation managing.
It is generated when donator makes a donation. It's equivalent to donate money amount.
#### methods:
```solidity
function transfer(address _to, uint256 _value) public returns (bool) {
    // Transfering is prohobited
    return false;
}
```

### contract [DACOToken](https://github.com/krivov/daco/blob/master/tokens/DACOToken.sol) is MintableToken:
Kind of token that is used for getting a discount.
#### methods:
   Create compaign for fund-raising:
   ```solidity
   function addCampaign(address _campaign) onlyOwner public { ... }
   ```
   * *_campaign* - campaign organization account address
   
   Remove compaign:
   ```solidity
   function removeCampaign(address _campaign) public onlyOwner { ... }
   ```
   * *_campaign* - campaign organization account address

   Send funds for company maker:
   ```solidity
   function transfer(address _to, uint256 _value) public returns (bool) { ... }
   ```
   * *_to* - campaign organization account address
   * *_value* - amount of wies to send
