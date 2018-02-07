/**
 * @title DaoWars
 * @author Daniel Luca <daniel.luca@consensys.net>
 * @author Eric Tu <eric.tu@consensys.net>
 * @author Gonçalo Sá <goncalo.sa@consensys.net>
 *
 * version 0.0.1
 * Copyright (c) 2018 ConsenSys Pirates, Inc
 * The MIT License (MIT)
 *
 * This game is an experiment on a pure DAO.
 * It was created @ ConsenSys Hacks by Daniel, Eric and Gonçalo
 * Nothing plays better than money
 */
pragma solidity 0.4.18;

import "bytes/BytesLib.sol";


contract DaoWarsRevival {
    using BytesLib for bytes;

    mapping(uint => mapping(byte => uint)) public votes;

    uint public generation = 0;

    byte public mostVotedByte;
    uint public mostVotedByteEther = -1;

    uint public constant VOTING_PERIOD = 6 hours;

    address public beastAddress;
    address public oldBeastAddress;

    bytes public codeToDeploy;

    function DaoWarsRevival(address masterAddress) public {
        lastVoteTime = now;
        beastAddress = masterAddress;
    }

    function vote(byte proposedByte) public payable {
        uint count = votes[generation][proposedByte];

        if (now > lastVoteTime + VOTING_PERIOD) {
            lastVoteTime = now;
            bytes memBytes;
            memBytes[0] = proposedByte;
            codeToDeploy.concat(memBytes);

            // reset voting sytem
            generation++;
            mostVotedByteEther = 0;
            mostVotedByte = 0;
        }

        votes[generation][proposedByte] = count + msg.value;

        if (count + msg.value > mostVotedByteEther) {
            mostVotedByteEther = count + msg.value;
            mostVotedByte = proposedByte;
        }
    }

    // This function lets people deposit more eth in this contract.
    // Thank you for making the game more fun!
    function deposit() public payable {}

    function deploy() public view {
        bytes memBytes = codeToDeploy;

        address newBeastAddress;

        assembly {
            // get array length
            size := memBytes

            // go into the data part
            memBytes := add(memBytes, 0x20)

            newBeastAddress := create(0, memBytes, size)
        }

        oldBeastAddress = beastAddress;
        beastAddress = newBeastAddress;
    }

    function checkThrow() public {
        if (!this.unleashTheBeast()) {
            beastAddress = oldBeastAddress;
        }
    }

    function unleashTheBeast() public {
        beastAddress.delegatecall();
    }
}
