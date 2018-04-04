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
pragma solidity ^0.4.19;


contract DaoWarsRevival {

    mapping(uint => mapping(byte => uint)) public votes;

    uint public generation = 0;

    byte public mostVotedByte;
    uint public mostVotedByteEther;
    uint public lastDeployTime;

    //uint public constant VOTING_PERIOD = 6 hours;
    uint public constant VOTING_PERIOD = 2 minutes;

    address public beastAddress;
    address public oldBeastAddress;

    bytes public codeToDeploy;

    function DaoWarsRevival(address masterAddress) public {
        lastDeployTime = now;
        beastAddress = masterAddress;
    }

    function vote(byte proposedByte) public payable returns (address) {
        if (now > lastDeployTime + VOTING_PERIOD) {
            // change the code
            codeToDeploy.push(proposedByte);
            
            // and deploy it
            deploy();

            // reset voting sytem
            lastDeployTime = now;
            generation++;
            mostVotedByteEther = 0;
            mostVotedByte = 0x0;
            
            // execute and check if we didn't just introduce a deadlock
            // opcode sequence
            checkForReset();
        }
        
        // let's update the ether staked for this opcode
        uint currentCount = votes[generation][proposedByte] + msg.value;

        votes[generation][proposedByte] = currentCount;

        if (currentCount > mostVotedByteEther) {
            mostVotedByteEther = currentCount;
            mostVotedByte = proposedByte;
        }
        
        return beastAddress;
    }

    // This function lets people deposit more eth in this contract.
    // Thank you for making the game more fun!
    function deposit() public payable {}

    function deploy() internal {
        bytes memory memBytes = codeToDeploy; //hex"60ff6000818160ff9039f3";

        address newBeastAddress;

        assembly {
            // get array length
            let size := mload(memBytes)
            
            // we can now discard the length and prefix the bytecode with the 
            // constructor bytecode. The "ff" byte is meant to be replaced
            // by the adequate length (byte #23)
            mstore(memBytes, 0x60ff6000818160089039f3)
            // so let's replace it:
            // 0x60<codeToDeploy_size>6000818160089039f3
            mstore8(add(memBytes, 0x16), size)

            // go into the beginning of the ctor code
            memBytes := add(memBytes, 0x15)

            newBeastAddress := create(0, memBytes, add(size, 0x0b))
        }

        oldBeastAddress = beastAddress;
        beastAddress = newBeastAddress;
    }

    function checkForReset() public returns (address) {
        if (codeToDeploy.length >= 255) {
            codeToDeploy = hex"";
            
            beastAddress = 0x0;
        } else if (!this.unleashTheBeast()) {
            address memBeastAddress = oldBeastAddress;
            
            bytes memory newCodeToDeploy;
            
            assembly {
                let codelength := extcodesize(memBeastAddress)
                
                newCodeToDeploy := mload(0x60)
                
                mstore(newCodeToDeploy, codelength)
                
                extcodecopy(memBeastAddress, add(newCodeToDeploy, 0x20), 0, codelength)
            }
            
            codeToDeploy = newCodeToDeploy;
            
            beastAddress = memBeastAddress;
        }
        
        return beastAddress;
    }

    // Be careful when calling this function since the gas estimation will
    // probably not work. Make sure you send enough gas!
    function unleashTheBeast() public payable returns (bool) {
        return beastAddress.delegatecall();
    }
    
    // Adding a routing of the fallback function to `unleashTheBeast()` so that
    // there's no need to have the function ID wasting the first 4 bytes of the
    // calldata.
    function () public payable {
        unleashTheBeast();
    }
}