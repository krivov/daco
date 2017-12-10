# DACO :green_heart: Decentralized Autonomous Charity Organization
Our platform unites charity organizations, businesses and donators in new way.
Charity organizations creates new social project that needs to be financed. 
Open heart people donate money for project that they like
Socially responsible businesses that also want to take part in charity project offer donators discounts for their services or products.
Charity organization get needed money, businesses expands their client base, donators receives discounts and a plus in their karma that is much more important.

## DACO API

### contract [DACOMain](https://github.com/krivov/daco/blob/master/DACOMain.sol) is Ownable:
Improved congress contract by [Ethereum Foundation](https://www.ethereum.org/dao#the-blockchain-congress).
#### methods:
Append new congress member:
```solidity
function addMember(
    address targetMember, 
    string memberName
) public onlyOwner { ... }
```
* *targetMember* - member account address
* *memberName* - member full name

Proposal voting:
```solidity
function vote(
    uint256 id
) public onlyMembers { ... }
```
* *id* - proposal identifier

Create a new campaign:
```solidity
function newCampaign(
    address _wallet, 
    uint256 _amount, 
    string  _description
) public onlyMembers { ... }
```
* *_wallet* - beneficiary wallet address
* *_amount* - hardCap value in Wei
* *_description* - campaign description string

Change rules of voting:
```solidity
function changeVotingRules(
    uint256 minimumQuorumForProposals,
    uint256 minutesForDebate,
    uint256 marginOfVotesForMajority
) public onlyOwner { ... }
```
* *minimumQuorumForProposals* - minimal count of votes
* *minutesForDebate* - debate deadline in minutes
* *marginOfVotesForMajority* - majority margin value

Remove congress member:
```solidity
function removeMember(
    address targetMember
) public onlyOwner { ... }
```
* *targetMember* - member account address

Create a new proposal:
```solidity
function newProposal(
    address wallet,
    uint256 amount,
    string  description
) public returns (uint256 id) { ... }
```
* *wallet* - beneficiary account address
* *amount* - transaction value in Eth
* *description* - job description string

Set new rate value:
```solidity
function setRate(
    uint256 _rate
) public onlyOwner returns (bool) { ... }
```
* *_rate* - factor of convertion wei -> daco token


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
function transfer(
    address _to, 
    uint256 _value
) public returns (bool) {
    // Transfering is prohobited
    return false;
}
```

### contract [DACOToken](https://github.com/krivov/daco/blob/master/tokens/DACOToken.sol) is MintableToken:
Kind of token that is used for getting a discount.
#### methods:
Create compaign for fund-raising:
```solidity
function addCampaign(
   address _campaign
) onlyOwner public { ... }
```
* *_campaign* - campaign organization account address
   
Remove compaign:
```solidity
function removeCampaign(
   address _campaign
) public onlyOwner { ... }
```
* *_campaign* - campaign organization account address

Send funds for company maker:
```solidity
function transfer(
    address _to, 
    uint256 _value
) public returns (bool) { ... }
```
* *_to* - campaign organization account address
* *_value* - amount of wies to send
