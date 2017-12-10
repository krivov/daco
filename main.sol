pragma solidity ^0.4.18;

import "./tokens/core/Ownable.sol";
import "./tokens/DACOToken.sol";
import "./crowdfunding/DACOTokenCrowdsale.sol";
import "./common/SafeMath.sol";

/**
 * @title Improved congress contract by Ethereum Foundation
 * @dev https://www.ethereum.org/dao#the-blockchain-congress
 */
contract DACOMain is Ownable {
    
    using SafeMath for uint256;
    
    /**
     * @dev Minimal quorum value
     */
    uint256 public minimumQuorum;

    /**
     * @dev Duration of debates
     */
    uint256 public debatingPeriodInMinutes;

    /**
     * @dev Majority margin is used in voting procedure
     */
    int256 public majorityMargin;

    /**
     * @dev Archive of all member proposals for adding new member
     */
    Proposal[] public proposals;

    /**
     * @dev Count of proposals in archive
     */
    function numProposals() public view returns (uint256)
    { return proposals.length; }

    /**
     * @dev Congress members list
     */
    Member[] public members;

    /**
     * @dev Get member identifier by account address
     */
    mapping(address => uint256) public memberId;

    /**
     * @dev Campaigns list
     */
    Campaign[] public campaigns;

    // The token being sold
    DACOToken public token;

    // how many token units a buyer gets per wei
    uint256 public rate;

    /**
     * @dev Get campaign identifier by account address
     */
    mapping(address => uint256) public campaignId;

    /**
     * @dev On proposal added
     * @param proposal Proposal identifier
     * @param recipient Ether recipient
     * @param amount Amount of wei to transfer
     */
    event ProposalAdded(uint256 indexed proposal,
        address indexed recipient,
        uint256 indexed amount,
        string description);

    /**
     * @dev On campaign added
     * @param campaign Campaign identifier
     * @param wallet Ether recipient
     * @param amount Amount of wei to transfer
     */
    event CampaignAdded(uint256 indexed campaign,
        address indexed wallet,
        uint256 indexed amount,
        string description);

    /**
     * @dev On vote by member accepted
     * @param proposal Proposal identifier
     * @param position Is proposal accepted by memeber
     * @param voter Congress memeber account address
     * @param justification Member comment
     */
    event Voted(uint256 indexed proposal,
        bool    indexed position,
        address indexed voter,
        string justification);

    /**
     * @dev On Proposal closed
     * @param proposal Proposal identifier
     * @param quorum Number of votes
     * @param active Is proposal passed
     */
    event ProposalTallied(uint256 indexed proposal,
        uint256 indexed quorum,
        bool    indexed active);

    /**
     * @dev On changed membership
     * @param member Account address
     * @param isMember Is account member now
     */
    event MembershipChanged(address indexed member,
        bool    indexed isMember);

    /**
     * @dev On voting rules changed
     * @param minimumQuorum New minimal count of votes
     * @param debatingPeriodInMinutes New debating duration
     * @param majorityMargin New majority margin value
     */
    event ChangeOfRules(uint256 indexed minimumQuorum,
        uint256 indexed debatingPeriodInMinutes,
        int256  indexed majorityMargin);

    struct Proposal {
        address recipient;
        uint256 amount;
        string  description;
        uint256 votingDeadline;
        bool    executed;
        bool    proposalPassed;
        uint256 numberOfVotes;
        int256  currentResult;
        bytes32 proposalHash;
        Vote[]  votes;
        mapping(address => bool) voted;
    }

    struct Member {
        address member;
        string  name;
        uint256 memberSince;
    }

    struct Vote {
        bool    inSupport;
        address voter;
        string  justification;
    }

    struct Campaign {
        DACOTokenCrowdsale crowdsale;
        address ownerAddress;
        address wallet;
        uint256 amount;
        string description;
        bool isFinished;
    }

    /**
     * @dev Modifier that allows only shareholders to vote and create new proposals
     */
    modifier onlyMembers {
        require (memberId[msg.sender] != 0);
        _;
    }

    /**
     * @dev First time setup
     */
    function DACOMain(
        uint256 minimumQuorumForProposals,
        uint256 minutesForDebate,
        int256  marginOfVotesForMajority,
        address congressLeader,
        uint256 _rate //0.0000000000000001
    ) public {
        changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
        // It’s necessary to add an empty first member
        addMember(0, ''); // and let's add the founder, to save a step later
        if (congressLeader != 0) {
            addMember(congressLeader, 'The Founder');
        }

        token = new DACOToken();
        rate = _rate;
    }

    /**
     * @dev Append new congress member
     * @param targetMember Member account address
     * @param memberName Member full name
     */
    function addMember(address targetMember, string memberName) public onlyOwner {
        require (memberId[targetMember] == 0);

        memberId[targetMember] = members.length;
        members.push(Member({member:      targetMember,
            memberSince: now,
            name:        memberName}));

        MembershipChanged(targetMember, true);
    }

    /**
     * @dev Remove congress member
     * @param targetMember Member account address
     */
    function removeMember(address targetMember) public onlyOwner {
        require (memberId[targetMember] != 0);

        uint256 targetId = memberId[targetMember];
        uint256 lastId   = members.length - 1;

        // Move last member to removed position
        Member memory moved    = members[lastId];
        members[targetId]      = moved;
        memberId[moved.member] = targetId;

        // Clean up
        memberId[targetMember] = 0;
        delete members[lastId];
        --members.length;

        MembershipChanged(targetMember, false);
    }

    /**
     * @dev Change rules of voting
     * @param minimumQuorumForProposals Minimal count of votes
     * @param minutesForDebate Debate deadline in minutes
     * @param marginOfVotesForMajority Majority margin value
     */
    function changeVotingRules(
        uint256 minimumQuorumForProposals,
        uint256 minutesForDebate,
        int256  marginOfVotesForMajority
    )
    public onlyOwner
    {
        minimumQuorum           = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin          = marginOfVotesForMajority;

        ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

    /**
     * @dev Create a new proposal
     * @param beneficiary Beneficiary account address
     * @param amount Transaction value in Wei
     * @param jobDescription Job description string
     * @param transactionBytecode Bytecode of transaction
     */
    function newProposal(
        address beneficiary,
        uint256 amount,
        string  jobDescription,
        bytes   transactionBytecode
    )
    public
    onlyMembers
    returns (uint256 id)
    {
        id                 = proposals.length++;
        Proposal storage p = proposals[id];
        p.recipient        = beneficiary;
        p.amount           = amount;
        p.description      = jobDescription;
        p.proposalHash     = keccak256(beneficiary, amount, transactionBytecode);
        p.votingDeadline   = now + debatingPeriodInMinutes * 1 minutes;
        p.executed         = false;
        p.proposalPassed   = false;
        p.numberOfVotes    = 0;
        ProposalAdded(id, beneficiary, amount, jobDescription);
    }

    /**
     * @dev Check if a proposal code matches
     * @param id Proposal identifier
     * @param beneficiary Beneficiary account address
     * @param amount Transaction value in Wei
     * @param transactionBytecode Bytecode of transaction
     */
    function checkProposalCode(
        uint256 id,
        address beneficiary,
        uint256 amount,
        bytes   transactionBytecode
    )
    public
    view
    returns (bool codeChecksOut)
    {
        return proposals[id].proposalHash
        == keccak256(beneficiary, amount, transactionBytecode);
    }

    /**
     * @dev Proposal voting
     * @param id Proposal identifier
     * @param supportsProposal Is proposal supported
     * @param justificationText Member comment
     */
    function vote(
        uint256 id,
        bool    supportsProposal,
        string  justificationText
    )
    public
    onlyMembers
    {
        Proposal storage p = proposals[id];     // Get the proposal
        require (p.voted[msg.sender] != true);  // If has already voted, cancel
        p.voted[msg.sender] = true;             // Set this voter as having voted
        p.numberOfVotes++;                      // Increase the number of votes
        if (supportsProposal) {                 // If they support the proposal
            p.currentResult++;                  // Increase score
        } else {                                // If they don't
            p.currentResult--;                  // Decrease the score
        }
        // Create a log of this event
        Voted(id,  supportsProposal, msg.sender, justificationText);
    }

    /**
     * @dev Try to execute proposal
     * @param id Proposal identifier
     * @param transactionBytecode Transaction data
     */
    function executeProposal(
        uint256 id,
        bytes   transactionBytecode
    )
    public
    onlyMembers
    {
        Proposal storage p = proposals[id];
        /* Check if the proposal can be executed:
           - Has the voting deadline arrived?
           - Has it been already executed or is it being executed?
           - Does the transaction code match the proposal?
           - Has a minimum quorum?
        */

        if (now < p.votingDeadline
        || p.executed
        || p.proposalHash != keccak256(p.recipient, p.amount, transactionBytecode)
        || p.numberOfVotes < minimumQuorum)
            revert();

        /* execute result */
        /* If difference between support and opposition is larger than margin */
        if (p.currentResult > majorityMargin) {
            // Avoid recursive calling

            p.executed = true;
            require (p.recipient.call.value(p.amount)(transactionBytecode));

            p.proposalPassed = true;
        } else {
            p.proposalPassed = false;
        }
        // Fire Events
        ProposalTallied(id, p.numberOfVotes, p.proposalPassed);
    }

    /**
     * @dev Create a new campaign
     * @param _wallet Beneficiary wallet address
     * @param _amount HardCap value in Wei
     * @param _description Campaign description string
     */
    function newCampaign(
        address _wallet,
        uint256 _amount,
        string  _description
    )
    public
    onlyMembers
    returns (uint256 id)
    {
        uint256 _memberId = memberId[msg.sender];

        id                 = campaigns.length++;
        Campaign storage c = campaigns[id];

        c.wallet           = _wallet;
        c.amount           = _amount;
        c.description      = _description;
        c.ownerAddress     = members[_memberId].member;
        c.isFinished       = false;

        uint256 amountWei = _amount.mul(1000000000000000000);

        c.crowdsale        = new DACOTokenCrowdsale(
            amountWei,
            rate,
            token,
            _wallet,
            _description
        );

        token.mint(c.crowdsale, rate.mul(amountWei));

        CampaignAdded(id, _wallet, _amount, _description);
    }

    /**
     * @dev Create a new campaign
     * @param _campaign Campaign
     */
    function endCampaign(
        address _campaign
    )
    public
    onlyMembers
    returns (uint256 id)
    {
        uint256 _memberId = memberId[msg.sender];
        Member member = members[_memberId];

        uint256 _campaignId = campaignId[_campaign];
        Campaign campaign = campaigns[_campaignId];
        require(msg.sender == campaigns[_campaignId].ownerAddress);

        campaign.isFinished = true;
        campaign.crowdsale.setFinalized();
    }

    // set new dates for pre-salev (emergency case)
    function setRate(
        uint256 _rate
    )
    public
    onlyOwner
    returns (bool)
    {
        rate = _rate;
        return true;
    }
}