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
    uint256 public majorityMargin;

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
     * @param owner Ether recipient
     * @param amount Amount of wei to transfer
     */
    event ProposalAdded(uint256 indexed proposal,
        address indexed owner,
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
     * @param voter Congress memeber account address
     */
    event Voted(uint256 indexed proposal,
        address indexed voter);

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
        uint256  indexed majorityMargin);

    struct Proposal {
        address owner;
        address wallet;
        uint256 amount;
        uint256 numberOfVotes;
        bool proposalPassed;
        string  description;
        mapping(address => bool) voted;
    }

    struct Member {
        address member;
        string  name;
        uint256 memberSince;
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
        address congressLeader
    ) public {
        changeVotingRules(1, 10000, 1);
        // It’s necessary to add an empty first member
        addMember(0, ''); // and let's add the founder, to save a step later
        if (congressLeader != 0) {
            addMember(congressLeader, 'The Founder');
        }

        token = new DACOToken();
        rate = 1000;
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
        uint256  marginOfVotesForMajority
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
     * @param wallet Beneficiary account address
     * @param amount Transaction value in Eth
     * @param description Job description string
     */
    function newProposal(
        address wallet,
        uint256 amount,
        string  description
    )
    public
    returns (uint256 id)
    {
        id                 = proposals.length++;
        Proposal storage p = proposals[id];

        p.owner            = msg.sender;
        p.wallet           = wallet;
        p.amount           = amount;
        p.description      = description;
        p.numberOfVotes    = 0;
        p.proposalPassed   = false;

        ProposalAdded(id, msg.sender, amount, description);
    }

    /**
     * @dev Proposal voting
     * @param id Proposal identifier
     */
    function vote(
        uint256 id
    )
    public
    onlyMembers
    {
        Proposal storage p = proposals[id];     // Get the proposal
        require (p.voted[msg.sender] != true);  // If has already voted, cancel
        require(p.numberOfVotes < majorityMargin); // If proposal already started

        p.voted[msg.sender] = true;             // Set this voter as having voted
        p.numberOfVotes++;                      // Increase the number of votes

        if (p.numberOfVotes == majorityMargin) {
            id                 = campaigns.length++;
            Campaign storage c = campaigns[id];

            c.wallet           = p.wallet;
            c.amount           = p.amount;
            c.description      = p.description;
            c.ownerAddress     = msg.sender;
            c.isFinished       = false;

            uint256 amountWei = p.amount.mul(1000000000000000000);

            c.crowdsale        = new DACOTokenCrowdsale(
                amountWei,
                rate,
                token,
                p.wallet,
                p.description
            );

            token.mint(c.crowdsale, rate.mul(amountWei));
            token.addCampaign(c.crowdsale);

            CampaignAdded(id, p.wallet, p.amount, p.description);
        }

        // Create a log of this event
        Voted(id, msg.sender);
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
        token.addCampaign(c.crowdsale);

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

        token.removeCampaign(campaign.crowdsale);
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