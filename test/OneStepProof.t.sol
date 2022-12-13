// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Params.sol";
import "../src/OneStepProof.sol";
import "./MockVerificationContext.sol";

contract OneStepProofTest is Test {
    using OneStepProof for OneStepProof.StateProof;
    using OneStepProof for OneStepProof.CodeProof;

    MockVerificationContext ctx;

    function setUp() public {
        ctx = new MockVerificationContext();
    }

    function testOspEncode() public {
        bytes memory bytecode = new bytes(2);
        bytecode[0] = 0x01;
        bytecode[1] = 0x02;
        OneStepProof.CodeProof memory codeProof = OneStepProof.CodeProof(bytecode);
        OneStepProof.StateProof memory startState;
        startState.depth = 1;
        startState.opCode = 0x01;
        startState.refund = 0x07;
        startState.pc = 0x99;
        startState.lastDepthHash = bytes32(0x0000000000000000000000000000000000000000000000000000aabbccddeeff);
        startState.codeHash = codeProof.hashCodeProof();
        startState.gas = Params.G_VERYLOW;
        startState.stackSize = 2;
        bytes memory encoded = startState.encodeStateProof();
        OneStepProof.StateProof memory decoded;
        (, decoded) = OneStepProof.decodeStateProofDebug(ctx, encoded, 0);
        assertEq(encoded, decoded.encodeStateProof());
    }
}
