DACO - Decentralized autonomous charity organization

### DACO API

#### contract DACOMain is Ownable
```solidity
function addMember(
    address targetMember, 
    string memberName
) public onlyOwner { ... }
```
Append new congress member
* *targetMember* - member account address
* *memberName* - member full name

```solidity
function vote(
    uint256 id
) public onlyMembers { ... }
```
Proposal voting
* *id* - proposal identifier

```solidity
function newCampaign(
    address _wallet, 
    uint256 _amount, 
    string  _description
) public onlyMembers { ... }
```
Create a new campaign
* *_wallet* - beneficiary wallet address
* *_amount* - hardCap value in Wei
* *_description* - campaign description string

```solidity
function changeVotingRules(
    uint256 minimumQuorumForProposals,
    uint256 minutesForDebate,
    uint256 marginOfVotesForMajority
) public onlyOwner { ... }
```
Change rules of voting
* *minimumQuorumForProposals* - minimal count of votes
* *minutesForDebate* - debate deadline in minutes
* *marginOfVotesForMajority* - majority margin value

```solidity
function removeMember(
    address targetMember
) public onlyOwner { ... }
```
Remove congress member
* *targetMember* - member account address


```solidity
function newProposal(
    address wallet,
    uint256 amount,
    string  description
) public returns (uint256 id) { ... }
```
Create a new proposal
* *wallet* - beneficiary account address
* *amount* - transaction value in Eth
* *description* - job description string

```solidity
function setRate(
    uint256 _rate
) public onlyOwner returns (bool) { ... }
```
Set new rate value
* *_rate* - factor of convertion wei -> daco token


