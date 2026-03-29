// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MembershipBoard {
    
    address public immutable OWNER;
    bytes32 public merkleRoot;
    mapping(address => bool) public members;

    constructor() {
        OWNER = msg.sender;        
    }

    // Event
    event MemberAdded(address indexed member);
    event MerkleRootSet(bytes32 indexed root);

    // Error
    error nonOwner();
    error duplicatedMember();

    // only owner is admin
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() view internal {
        if (msg.sender != OWNER) revert nonOwner();
    }

    // Part 1: Add Members One-by-One (Mapping)
    function addMember(address _member) external onlyOwner {
        if (members[_member]) {
            revert duplicatedMember();
        } else {
            members[_member] = true;
            emit MemberAdded(_member);
        }
    }

    // Part 2: Batch Add Members (Mapping)
    function batchAddMembers(address[] calldata _members) external onlyOwner {
        for (uint i = 0; i < _members.length; i++) {
            if (members[_members[i]]) {
                revert duplicatedMember();
            } else {
                members[_members[i]] = true;
                emit MemberAdded(_members[i]);
            }
        }
    }

    //Part 3: Set Merkle Root
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
        emit MerkleRootSet(merkleRoot);
    }

    // Part 4: Verify Membership (Mapping)
    function verifyMemberByMapping(address _member) external view returns (bool) {
        return members[_member];
    }

    // Part 5: Verify Membership (Merkle Proof)
    function verifyMemberByProof(address _member, bytes32[] calldata _proof) external view returns (bool) {
        // The Standard Merkle Tree uses an opinionated double leaf hashing algorithm
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_member))));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }
}