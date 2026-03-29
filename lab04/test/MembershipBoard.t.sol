// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "../lib/forge-std/src/Test.sol";
import {stdJson} from "../lib/forge-std/src/stdJson.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {MembershipBoard} from "../src/MembershipBoard.sol";

contract MembershipBoardTest is Test {
    using stdJson for string;

    MembershipBoard board;

    address internal owner = address(this);
    address internal nonOwner = address(0xBEEF);

    string internal constant MEMBERS_PATH = "./members.json";
    string internal constant MERKLE_PATH = "./merkle-data.json";

    string membersJson;
    string merkleDataJson;

    function setUp() public {
        board = new MembershipBoard();

        membersJson = vm.readFile(MEMBERS_PATH);
        merkleDataJson = vm.readFile(MERKLE_PATH);
    }

    /*//////////////////////////////////////////////////////////////
                            ADDING MEMBERS
    //////////////////////////////////////////////////////////////*/
    /// Owner can add a single member via addMember
    function test_ownerAddMember() public {
        address member = membersJson.readAddress(".addresses[0]");
        
        board.addMember(member);
        assertTrue(board.verifyMemberByMapping(member));
    }

    /// Non-owner cannot add a member
    function test_nonOwnerAddMember_Revert() public {
        address member = membersJson.readAddress(".addresses[0]");
        
        vm.prank(nonOwner);
        vm.expectRevert(MembershipBoard.nonOwner.selector);
        board.addMember(member);
    }

    /// Adding a duplicate member reverts
    function test_addDuplicatedMember_Revert() public {
        address member = membersJson.readAddress(".addresses[0]");
        
        board.addMember(member);
        
        vm.expectRevert(MembershipBoard.duplicatedMember.selector);
        board.addMember(member);
    }

    /// Owner can batch add members via batchAddMembers
    function test_batchAddMembers() public {
        address[] memory members = membersJson.readAddressArray(".addresses");
        
        address[] memory batchMembers = new address[](3);
        batchMembers[0] = members[0];
        batchMembers[1] = members[1];
        batchMembers[2] = members[2];

        board.batchAddMembers(batchMembers);
        assertTrue(board.verifyMemberByMapping(batchMembers[0]));
        assertTrue(board.verifyMemberByMapping(batchMembers[1]));
        assertTrue(board.verifyMemberByMapping(batchMembers[2]));
    }

    /// Adding a duplicate in a batch reverts
    function test_batchAddDuplicatedMembers_Revert() public {
        address[] memory members = membersJson.readAddressArray(".addresses");
        
        address[] memory batchMembers = new address[](3);
        batchMembers[0] = members[0];
        batchMembers[1] = members[1];
        batchMembers[2] = members[1];

        vm.expectRevert(MembershipBoard.duplicatedMember.selector);
        board.batchAddMembers(batchMembers);
    }

    /// All 1,000 members are correctly stored after batch add
    function test_batchAdd1000Members() public {
        address[] memory members = membersJson.readAddressArray(".addresses");
        
        board.batchAddMembers(members);
        for (uint256 i = 0; i < members.length; i++) {
            assertTrue(board.verifyMemberByMapping(members[i]));
        }
    }
    
    /*//////////////////////////////////////////////////////////////
                            Setting Merkle Root
    //////////////////////////////////////////////////////////////*/
    /// Owner can set Merkle Root
    function test_ownerSetMerkleRoot() public {
        bytes32 merkleRoot = merkleDataJson.readBytes32(".root");

        board.setMerkleRoot(merkleRoot);
        assertEq(board.merkleRoot(), merkleRoot);
    }

    // Non-owner cannot set the Merkle root
    function test_nonOwnerSetMerkleRoot_Revert() public {
        bytes32 merkleRoot = merkleDataJson.readBytes32(".root");

        vm.prank(nonOwner);
        vm.expectRevert(MembershipBoard.nonOwner.selector);
        board.setMerkleRoot(merkleRoot);
    }

    /*//////////////////////////////////////////////////////////////
                            Verification (Mapping)
    //////////////////////////////////////////////////////////////*/
    /// Returns true for a registered member
    function test_verifyMemberByMapping_TrueForRegisterd() public {
        address member = membersJson.readAddress(".addresses[1]");
        
        board.addMember(member);
        assertTrue(board.verifyMemberByMapping(member));
    }

    /// Returns false for a non-member
    function test_verifyMemberByMapping_FalseForNonMember() view public {
        address nonMember = address(0x00000000);
        assertFalse(board.verifyMemberByMapping(nonMember));
    }

    /*//////////////////////////////////////////////////////////////
                            Verification (Merkle Proof)
    //////////////////////////////////////////////////////////////*/
    /// Valid proof for a registered member returns true
    function test_verifyMemberByProof_Valid() public {
        bytes32 merkleRoot = merkleDataJson.readBytes32(".root");
        board.setMerkleRoot(merkleRoot);

        address member = membersJson.readAddress(".addresses[0]");
        string memory key = string.concat(".proofs.", vm.toString(member));
        bytes32[] memory proof = merkleDataJson.readBytes32Array(key);

        assertTrue(board.verifyMemberByProof(member, proof));
    }
    
    /// Invalid proof returns false
    function test_verifyMemberByProof_InvalidProof() public {
        bytes32 merkleRoot = merkleDataJson.readBytes32(".root");
        board.setMerkleRoot(merkleRoot);

        address member1 = membersJson.readAddress(".addresses[0]");
        address member2 = membersJson.readAddress(".addresses[1]");
        string memory fakeKey = string.concat(".proofs.", vm.toString(member2));
        bytes32[] memory fakeProof = merkleDataJson.readBytes32Array(fakeKey);

        assertFalse(board.verifyMemberByProof(member1, fakeProof));
    }
    /// Proof for a non-member returns false
    function test_verifyMemberByProof_NonMember() public {
        address nonMember = address(0x00000000);

        bytes32 merkleRoot = merkleDataJson.readBytes32(".root");
        board.setMerkleRoot(merkleRoot);

        address member = membersJson.readAddress(".addresses[0]");
        string memory key = string.concat(".proofs.", vm.toString(member));
        bytes32[] memory proof = merkleDataJson.readBytes32Array(key);

        assertFalse(board.verifyMemberByProof(nonMember, proof));
    }


    /*//////////////////////////////////////////////////////////////
                            Gas Profiling
    //////////////////////////////////////////////////////////////*/
    // Reset Contract
    function resetBoard() public {
        board = new MembershipBoard();
    }

    // Gas Measurements
    function test_gas_Measurements() public {
        address[] memory members = membersJson.readAddressArray(".addresses");
        bytes32 root = merkleDataJson.readBytes32(".root");

        // --- 1. addMember ---
        resetBoard();
        uint256 startGas = gasleft();
        board.addMember(members[0]);
        console.log("Action: addMember (single) Gas:", startGas - gasleft());

        // --- 2. batchAddMembers ---
        // 50; 100; 200; 500; 1000
        uint256[] memory sizes = new uint256[](5);
        sizes[0] = 50; sizes[1] = 100; sizes[2] = 200; sizes[3] = 500; sizes[4] = 1000;

        for (uint i = 0; i < sizes.length; i++) {
            resetBoard();
            uint256 size = sizes[i];
            address[] memory batch = new address[](size);
            for (uint j = 0; j < size; j++) {
                batch[j] = members[j];
            }
            
            startGas = gasleft();
            board.batchAddMembers(batch);
            console.log(string.concat("Action: batchAddMembers ", vm.toString(size), " Gas:"), startGas - gasleft());
        }

        // --- 3. setMerkleRoot ---
        resetBoard();
        startGas = gasleft();
        board.setMerkleRoot(root);
        console.log("Action: setMerkleRoot Gas:", startGas - gasleft());

        // --- 4. verifyMemberByMapping ---
        resetBoard();
        board.addMember(members[0]); // add member first
        startGas = gasleft();
        board.verifyMemberByMapping(members[0]);
        console.log("Action: verifyMemberByMapping Gas:", startGas - gasleft());

        // --- 5. verifyMemberByProof ---
        resetBoard();
        board.setMerkleRoot(root); // set root first
        string memory key = string.concat(".proofs.", vm.toString(members[0]));
        bytes32[] memory proof = merkleDataJson.readBytes32Array(key);
        
        startGas = gasleft();
        board.verifyMemberByProof(members[0], proof);
        console.log("Action: verifyMemberByProof Gas:", startGas - gasleft());
    }
}