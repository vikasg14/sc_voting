// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Voting {
    struct Question {
        uint256 questionId;
        uint256 questionType;
        Status status;
        string questionStatement;
        uint256 optionCount;
        Option[] options;
        uint256 qVotes;
    }

    struct Option {
        uint256 optionId;
        string optionValue;
        uint256 oVotes;
        uint256 weightedVotes;
    }

    struct UserVote {
        address userAddress;
        uint256 questionId;
        uint256 optionId;
        uint256 voteWeight;
        bool voted;
    }

    enum Status {
        New,
        Active,
        Inactive,
        Deleted
    }

    uint256 public totalQuestions = 0;
    uint256 public totalVotes = 0;
    uint256 public totalVoters = 0;

    uint256 private constant NQUESTIONTYPES = 5; // ???
    uint256 private constant MAX_WEIGHT = 100; // ???

    address public immutable owner;         // ???
    uint256 private optionIdCounter = 0;

    // map (address => map(questionId => UserVote))
    mapping(address => mapping(uint256 => UserVote)) public mapUserVotes;

    // map(questionId => Question)
    mapping(uint256 => Question) public mapQuestions;

    constructor() {
        owner = msg.sender;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner.");
        _;
    }

    modifier validQuestion(uint256 _qid) {
        require(
            _qid > 0 && _qid <= totalQuestions,
            "Question does not exists."
        );
        require(mapQuestions[_qid].questionId > 0, "Question does not exists.");
        _;
    }

    modifier inStatus(uint256 _qid, Status _status) {
        require(
            mapQuestions[_qid].status == _status,
            "Operation not valid, invalid question status."
        );
        _;
    }

    function addQuestion(
        uint256 _qtype,
        string memory _qStatement,
        string memory _option1,
        string memory _option2,
        string memory _option3,
        string memory _option4,
        string memory _option5
    ) public onlyOwner {
        require(
            _qtype > 0 && _qtype <= NQUESTIONTYPES,
            "Invalid question type."
        );

        require(bytes(_qStatement).length != 0, "Invalid question statement.");
        require(bytes(_option1).length != 0, "Invalid option 1.");
        require(bytes(_option2).length != 0, "Invalid option 2.");

        Question storage quest = mapQuestions[++totalQuestions];
        quest.questionId = totalQuestions;
        quest.questionType = _qtype;
        quest.status = Status.New;
        quest.questionStatement = _qStatement;
        quest.options.push(Option(1, _option1, 0, 0));
        quest.options.push(Option(2, _option2, 0, 0));

        optionIdCounter = 2;

        if (bytes(_option3).length != 0) {
            quest.options.push(Option(++optionIdCounter, _option3, 0, 0));
        }
        if (bytes(_option4).length != 0) {
            quest.options.push(Option(++optionIdCounter, _option4, 0, 0));
        }
        if (bytes(_option5).length != 0) {
            quest.options.push(Option(++optionIdCounter, _option5, 0, 0));
        }

        quest.optionCount = optionIdCounter;
    }

    function enableQuestion(uint256 _qid)
        public
        onlyOwner
        validQuestion(_qid)
        inStatus(_qid, Status.New)
    {
        mapQuestions[_qid].status = Status.Active;
    }

    function disableQuestion(uint256 _qid)      // ??? want to enable it again?
        public
        onlyOwner
        validQuestion(_qid)
        inStatus(_qid, Status.Active)
    {
        mapQuestions[_qid].status = Status.Inactive;
    }

    function vote(
        address _userAddress,
        uint256 _qid,
        uint256 _optionId,
        uint256 _voteWeight
    ) public validQuestion(_qid) inStatus(_qid, Status.Active) {
        require(
            _optionId > 0 && _optionId <= mapQuestions[_qid].optionCount,
            "Invalid option choosen."
        );
        require(
            _voteWeight > 0 && _voteWeight <= MAX_WEIGHT,
            "Invalid vote weight."
        );
        require(
            mapUserVotes[_userAddress][_qid].voted == false,
            "User already voted."
        );

        // ???
        // if (!mapUserVotes[_userAddress]) {
        //     totalVoters++;
        // }

        UserVote memory userVote;
        userVote.userAddress = _userAddress;
        userVote.questionId = _qid;
        userVote.optionId = _optionId;
        userVote.voteWeight = _voteWeight;
        userVote.voted = true;
        mapUserVotes[_userAddress][_qid] = userVote;

        Question storage quest = mapQuestions[_qid];
        quest.qVotes += 1;
        quest.options[_optionId - 1].oVotes += 1;
        quest.options[_optionId - 1].weightedVotes += _voteWeight;           // ???

        totalVotes++;
    }
}
