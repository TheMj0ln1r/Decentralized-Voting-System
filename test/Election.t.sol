// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Election} from "../src/Election.sol";
import {ElectionScript} from "../script/Election.s.sol";


contract ElectionTest is Test {
    Election election;
    address owner;
    address voter1;
    address voter2;
    address voter3;
    address voter4;
    address voter5;
    address candidate1;
    address candidate2;

    function setUp() public {
        owner = address(this);
        election = new Election();
        voter1 = address(0x1);
        voter2 = address(0x2);
        voter3 = address(0x3);
        voter4 = address(0x4);
        voter5 = address(0x5);

        candidate1 = address(0xff);
        candidate2 = address(0xaa);
    }

    function testInitialElectionState() public {
        assertEq(election.owner(), owner);
        assertEq(election.totalNumOfVoters(), 0);
        assertEq(election.electionDuration(), 0);
        assertEq(election.electionStartTime(), 0);

    }

    function testRegisterVoter() public {
        vm.startPrank(voter1);
        election.registerVoter();
        assertEq(election.totalNumOfVoters(), 1);
        vm.expectRevert(Election.Election_Voter_Already_Registered.selector);
        election.registerVoter();

    }

    function testRegisterVoterDuringElection() public {
        election.startElection(100);
        vm.prank(voter1);
        vm.expectRevert(Election.Election_Election_Running.selector);
        election.registerVoter();
    }

    function testRegisterCandidate() public {
        election.registerCandidate(candidate1);
        (address c, uint v) = election.candidateDetails(0);
        assertEq(candidate1, c);
        assertEq(0, v);

        vm.expectRevert(Election.Election_Candidate_Already_Registered.selector);
        election.registerCandidate(candidate1);

        vm.expectRevert(Election.Election_Invalid_Candidate.selector);
        election.registerCandidate(address(0));

        vm.prank(voter1);
        vm.expectRevert(Election.Election_Not_Owner.selector);
        election.registerCandidate(candidate2);

    }

    function testRegisterCandidateDuringElection() public {
        election.startElection(100);
        vm.expectRevert(Election.Election_Election_Running.selector);
        election.registerCandidate(candidate1);
    }

    function testStartElection() public{
        vm.expectEmit(true, false, false, false);
        emit Election.Election_Election_Started(block.timestamp);
        election.startElection(100);

        vm.warp(block.timestamp + 100);
        vm.expectRevert(Election.Election_Invalid_Duration.selector);
        election.startElection(0);

    }

    function testStartElectionAlreadyRunning() public {
        election.startElection(100);
        vm.expectRevert(Election.Election_Election_Running.selector);
        election.startElection(100);

        vm.warp(block.timestamp + 100);
        vm.prank(voter1);
        vm.expectRevert(Election.Election_Not_Owner.selector);
        election.startElection(100);
    }

    function testCastVote() public {
        vm.prank(voter1);
        election.registerVoter();
        vm.prank(owner);
        election.registerCandidate(candidate1);
        election.startElection(100);
        vm.prank(voter1);
        election.castVote(candidate1);
        assertEq(election.getMajority(candidate1), 1);
    }

    function testCastVoteNotRegisteredVoter() public {
        vm.prank(voter1);
        election.registerVoter();
        vm.prank(owner);
        election.registerCandidate(candidate1);
        election.startElection(100);
        vm.prank(voter1);
        election.castVote(candidate1);

        vm.prank(voter2);
        vm.expectRevert(Election.Election_Voter_Not_Registered.selector);
        election.castVote(candidate1); // This should revert
    }

    function testCastVoteAlreadyVoted() public {
        vm.prank(voter1);
        election.registerVoter();
        vm.prank(owner);
        election.registerCandidate(candidate1);
        election.startElection(100);
        vm.startPrank(voter1);
        election.castVote(candidate1);
        vm.expectRevert(Election.Election_Already_Voted.selector);
        election.castVote(candidate1); // This should revert
    }

    function testCastVoteInvalidCandidate() public {
        vm.prank(voter1);
        election.registerVoter();
        vm.prank(owner);
        election.registerCandidate(candidate1);
        election.startElection(100);
        vm.startPrank(voter1);

        vm.expectRevert(Election.Election_Invalid_Candidate.selector);
        election.castVote(candidate2); // This should revert
    }

    function testGetMajority() public{
        vm.prank(voter1);
        election.registerVoter();
        vm.prank(voter2);
        election.registerVoter();
        vm.prank(voter3);
        election.registerVoter();
        vm.prank(owner);
        election.registerCandidate(candidate1);
        election.startElection(100);
        vm.prank(voter1);
        election.castVote(candidate1);
        vm.prank(voter2);
        election.castVote(candidate1);
        vm.prank(voter3);
        election.castVote(candidate1);
        assertEq(election.getMajority(candidate1), 3);
    }

    function testIsElectionActive() public {
        election.startElection(100);
        assertTrue(election.isElectionActive());

        vm.warp(block.timestamp + 100);
        assertFalse(election.isElectionActive());
    }
    function testRevealResults() public {
        election.registerCandidate(candidate1);
        election.registerCandidate(candidate2);
        vm.prank(voter1);
        election.registerVoter();
        vm.prank(voter2);
        election.registerVoter();
        vm.prank(voter3);
        election.registerVoter();

        vm.prank(owner);
        election.startElection(100);

        vm.prank(voter1);
        election.castVote(candidate1);

        vm.prank(voter2);
        election.castVote(candidate2);

        vm.prank(voter3);
        election.castVote(candidate1);

        vm.warp(block.timestamp + 100);
        vm.prank(owner);

        Election.Candidate[] memory _winners = election.revealResults();
        Election.Candidate memory winner = _winners[0];
        assertEq(candidate1, winner.candidate);
    }

     function testRevealResultsMultipleWinners() public {
        election.registerCandidate(candidate1);
        election.registerCandidate(candidate2);
        vm.prank(voter1);
        election.registerVoter();
        vm.prank(voter2);
        election.registerVoter();
        vm.prank(voter3);
        election.registerVoter();
        
        vm.prank(voter4);
        election.registerVoter();

        vm.prank(owner);
        election.startElection(100);

        vm.prank(voter1);
        election.castVote(candidate1);

        vm.prank(voter2);
        election.castVote(candidate2);

        vm.prank(voter3);
        election.castVote(candidate1);

        vm.prank(voter4);
        election.castVote(candidate2);

        vm.warp(block.timestamp + 100);
        
        vm.prank(owner);
        Election.Candidate[] memory _winners = election.revealResults();
        Election.Candidate memory winner1 = _winners[0];
        assertEq(candidate1, winner1.candidate);

        Election.Candidate memory winner2 = _winners[1];
        assertEq(candidate2, winner2.candidate);
    }
    function testRevealResultsNotOwner() public {
        election.registerCandidate(candidate2);
        vm.prank(voter1);
        election.registerVoter();

        vm.prank(owner);
        election.startElection(100);

        vm.warp(block.timestamp + 100);

        vm.prank(voter1);
        vm.expectRevert(Election.Election_Not_Owner.selector);
        election.revealResults(); // This should revert
    }
    
    function testScript() public{
        ElectionScript script = new ElectionScript();
        script.run();
        assertTrue(address(script.election()) != address(0));
    }
}