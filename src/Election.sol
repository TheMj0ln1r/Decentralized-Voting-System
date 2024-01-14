// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Election{
    struct Voter {
        uint256 voterID;
        bool voted;
    }

    struct Candidate {
        address candidate;
        uint256 votesCount;
    }
    
    address public immutable owner;
    uint256 public totalNumOfVoters;
    uint256 public electionDuration;
    uint256 public electionStartTime;

    Candidate[] public candidateDetails;
    mapping (address candidate => uint candidId) public candidAddrToId;
    mapping (address voter => Voter) private voterDetails;


    //Events
    event Election_Candidate_Registered(address candidate, uint candidID);
    event Election_Voter_Registered(address voter, uint voterID);
    event Election_Voted(address voter);
    event Election_Winner_Declared(Candidate[] candidate);
    event Election_Election_Started(uint startTime);

    //Errors
    error Election_Not_Owner();
    error Election_Voter_Already_Registered();
    error Election_Candidate_Already_Registered();
    error Election_Invalid_Candidate();
    error Election_Already_Voted();
    error Election_Voter_Not_Registered();
    error Election_Election_Running();
    error Election_Election_Completed();
    error Election_Invalid_Duration();


    modifier  onlyOwner() {
        if (msg.sender != owner) revert Election_Not_Owner();
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function registerVoter() external{
        if(isElectionActive()) revert Election_Election_Running();
        if (voterDetails[msg.sender].voterID != 0) revert Election_Voter_Already_Registered();
        
        totalNumOfVoters += 1;

        uint vid = totalNumOfVoters;
        voterDetails[msg.sender].voterID = vid;

        emit Election_Voter_Registered(msg.sender, vid);
    }

    function registerCandidate(address _candidate) external onlyOwner(){
        if(isElectionActive()) revert Election_Election_Running();
        uint cand = candidAddrToId[_candidate];
        if ( cand != 0) revert Election_Candidate_Already_Registered();
        if (_candidate == address(0) || _candidate == owner) revert Election_Invalid_Candidate();

        uint cid = candidateDetails.length;
        candidateDetails.push(Candidate({candidate:_candidate, votesCount: 0}));
        candidAddrToId[_candidate] = cid + 1;

        emit Election_Candidate_Registered(_candidate, cid);
    }

    function startElection(uint _duration) public onlyOwner(){
        if(isElectionActive()) revert Election_Election_Running();
        if (_duration == 0) revert Election_Invalid_Duration();
        electionStartTime = block.timestamp;
        electionDuration = _duration;

        emit Election_Election_Started(block.timestamp);
    }


    function castVote(address _candidate) external{
        if (voterDetails[msg.sender].voterID == 0) revert Election_Voter_Not_Registered();
        if (voterDetails[msg.sender].voted) revert Election_Already_Voted();
        uint cand = candidAddrToId[_candidate];
        if (cand == 0) revert Election_Invalid_Candidate();

        if (!isElectionActive()) revert Election_Election_Completed();

        candidateDetails[cand-1].votesCount += 1;
        voterDetails[msg.sender].voted = true;

        emit Election_Voted(msg.sender);
    }

    function revealResults() external onlyOwner() returns (Candidate[] memory){
        if(isElectionActive()) revert Election_Election_Running();
        uint totalNumOfCandidates = candidateDetails.length;
        uint max;
        uint maxCount;
        for (uint i; i < totalNumOfCandidates; i++){
            uint votes = candidateDetails[i].votesCount;
            if (max < votes){
                max = votes;
                maxCount = 1;
            }
            else if (max == votes ){
                maxCount++;
            }
        }
        uint[] memory maxIndices = new uint[](maxCount);
        uint index;
        for (uint i; i<totalNumOfCandidates; i++){
            if (candidateDetails[i].votesCount == max){
                maxIndices[index] = i;
                index++;
            }
        }
        Candidate[] memory winners = new Candidate[](index);
        for (uint i; i< index; i++){
            winners[i] = candidateDetails[maxIndices[i]];
        }
        emit Election_Winner_Declared(winners);
        return winners;

    }
    function getMajority(address _candidate) public view returns (uint){
        if (_candidate == address(0) || _candidate == owner) revert Election_Invalid_Candidate();
        uint cand = candidAddrToId[_candidate];
        return candidateDetails[cand-1].votesCount;
    }

    function isElectionActive() public view returns(bool){
        if ((block.timestamp - electionStartTime < electionDuration) && electionStartTime != 0){
            return true;
        }
        return false;
    }
}