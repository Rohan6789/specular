// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/libraries/BytesLib.sol";
import "../src/Verifier.sol";
import "../src/Params.sol";
import "../src/OneStepProof.sol";
import "./MockVerificationContext.sol";

contract VerifierTest is Test {
    using OneStepProof for OneStepProof.StateProof;
    using OneStepProof for OneStepProof.CodeProof;
    using OneStepProof for OneStepProof.StackProof;
    using BytesLib for bytes;

    MockVerificationContext ctx;
    Verifier verifier;

    function setUp() public {
        ctx = new MockVerificationContext();
        verifier = new Verifier();
    }

    function testAdd(
        uint256 a,
        uint256 b,
        bytes32 originalStackHash,
        uint64 pc,
        uint64 gas,
        bytes memory bytecode,
        uint64 stackSize // [NEW] fuzz the stackSize too,

    ) public {
        // Get ground truth of opcode execution
        uint256 c;
        assembly {
            c := add(a, b)
        }

        // Pre-conditions
        vm.assume(bytecode.length > pc); // assume pc is not out of bound
        vm.assume(bytecode[pc] == 0x01); // assume the current bytecode is ADD [to optimize]
        vm.assume(gas >= Params.G_VERYLOW); // assume the gas is enough
        vm.assume((stackSize > 1) && (stackSize <= 1024)); // [NEW] assume stackSize is 0-1024
        

        // Construct the code proof
        OneStepProof.CodeProof memory codeProof = OneStepProof.CodeProof(bytecode);

        // Construct the start state
        OneStepProof.StateProof memory startState;
        startState.depth = 1;
        startState.pc = pc;
        startState.opCode = 0x01;
        startState.codeHash = codeProof.hashCodeProof();
        startState.gas = gas;
        startState.stackSize = stackSize;
        // startState.stackSize = 2;
        bytes32 stackHash = keccak256(abi.encodePacked(originalStackHash, a));
        stackHash = keccak256(abi.encodePacked(stackHash, b));
        startState.stackHash = stackHash;

        // Construct the stack proof
        OneStepProof.StackProof memory stackProof;
        stackProof.pops = new uint256[](2);
        stackProof.pops[0] = b;
        stackProof.pops[1] = a;
        stackProof.stackHashAfterPops = originalStackHash;

        // Construct the end state using the ground truth
        OneStepProof.StateProof memory endState;
        endState.depth = 1;
        endState.pc = pc + 1;
        if (bytecode.length > pc + 1) {
            endState.opCode = uint8(bytecode[pc + 1]);
        }
        endState.gas = gas - Params.G_VERYLOW;
        endState.codeHash = codeProof.hashCodeProof();
        endState.stackSize = stackSize-1; // [NEW] endstate stacksize will be 1 less than startstate stacksize
        endState.stackHash = keccak256(abi.encodePacked(originalStackHash, c));

        // Assemble the proof
        bytes memory proof;
        proof = proof.concat(startState.encodeStateProof());
        proof = proof.concat(codeProof.encodeCodeProof());
        proof = proof.concat(abi.encodePacked(bytes1(0))); // error code
        proof = proof.concat(stackProof.encodeStackProof());

        assertEq(verifier.verifyOneStepProof(ctx, startState.hashStateProof(), proof), endState.hashStateProof());
    }

    // ----------------------------------------------------------------------------------------------------------------]
    
    function testMul(
        uint256 a,
        uint256 b,
        bytes32 originalStackHash,
        uint64 pc,
        uint64 gas,
        bytes memory bytecode,
        uint64 stackSize // [NEW] fuzz the stackSize too

    ) public {
        // Get ground truth of opcode execution
        uint256 c;
        assembly {
            c := mul(a, b)
        }

        // Pre-conditions
        vm.assume(bytecode.length > pc); // assume pc is not out of bound
        vm.assume(bytecode[pc] == 0x02); // assume the current bytecode is MUL
        vm.assume(gas >= 5); // assume the gas is enough for MUL
        // vm.assume(gas >= 7); // mul needs at least 5 gas
        vm.assume((stackSize > 1) && (stackSize <= 1024)); // [NEW] assume stackSize is 0-1024
        

        // Construct the code proof
        OneStepProof.CodeProof memory codeProof = OneStepProof.CodeProof(bytecode);

        // Construct the start state
        OneStepProof.StateProof memory startState;
        startState.depth = 1;
        startState.pc = pc;
        startState.opCode = 0x02; // opCode for MUL
        startState.codeHash = codeProof.hashCodeProof();
        startState.gas = gas;
        startState.stackSize = stackSize;
        // startState.stackSize = 2;
        bytes32 stackHash = keccak256(abi.encodePacked(originalStackHash, a));
        stackHash = keccak256(abi.encodePacked(stackHash, b));
        startState.stackHash = stackHash;

        // Construct the stack proof
        OneStepProof.StackProof memory stackProof;
        stackProof.pops = new uint256[](2);
        stackProof.pops[0] = b;
        stackProof.pops[1] = a;
        stackProof.stackHashAfterPops = originalStackHash;

        // Construct the end state using the ground truth
        OneStepProof.StateProof memory endState;
        endState.depth = 1;
        endState.pc = pc + 1;
        if (bytecode.length > pc + 1) {
            endState.opCode = uint8(bytecode[pc + 1]);
        }
        endState.gas = gas - Params.G_LOW;
        endState.codeHash = codeProof.hashCodeProof();
        endState.stackSize = stackSize-1; // [NEW] endstate stacksize will be 1 less than startstate stacksize
        endState.stackHash = keccak256(abi.encodePacked(originalStackHash, c));

        // Assemble the proof
        bytes memory proof;
        proof = proof.concat(startState.encodeStateProof());
        proof = proof.concat(codeProof.encodeCodeProof());
        proof = proof.concat(abi.encodePacked(bytes1(0))); // error code
        proof = proof.concat(stackProof.encodeStackProof());

        assertEq(verifier.verifyOneStepProof(ctx, startState.hashStateProof(), proof), endState.hashStateProof());
    }

    // ----------------------------------------------------------------------------------------------------------------]

    function testMod(
        uint256 a,
        uint256 b,
        bytes32 originalStackHash,
        uint64 pc,
        uint64 gas,
        bytes memory bytecode,
        uint64 stackSize // [NEW] fuzz the stackSize too

    ) public {
        // Get ground truth of opcode execution
        uint256 c;
        assembly {
            c := mod(a, b)
        }

        // Pre-conditions
        vm.assume(bytecode.length > pc); // assume pc is not out of bound
        vm.assume(bytecode[pc] == 0x06); // assume the current bytecode is MOD
        vm.assume(gas >= Params.G_LOW); // assume the gas is enough for MOD
        // vm.assume(gas >= 7); // mul needs at least 5 gas
        vm.assume((stackSize > 1) && (stackSize <= 1024)); // [NEW] assume stackSize is 0-1024
        

        // Construct the code proof
        OneStepProof.CodeProof memory codeProof = OneStepProof.CodeProof(bytecode);

        // Construct the start state
        OneStepProof.StateProof memory startState;
        startState.depth = 1;
        startState.pc = pc;
        startState.opCode = 0x06; // opCode for MOD
        startState.codeHash = codeProof.hashCodeProof();
        startState.gas = gas;
        startState.stackSize = stackSize;
        // startState.stackSize = 2;
        bytes32 stackHash = keccak256(abi.encodePacked(originalStackHash, a));
        stackHash = keccak256(abi.encodePacked(stackHash, b));
        startState.stackHash = stackHash;

        // Construct the stack proof
        OneStepProof.StackProof memory stackProof;
        stackProof.pops = new uint256[](2);
        stackProof.pops[0] = b;
        stackProof.pops[1] = a;
        stackProof.stackHashAfterPops = originalStackHash;

        // Construct the end state using the ground truth
        OneStepProof.StateProof memory endState;
        endState.depth = 1;
        endState.pc = pc + 1;
        if (bytecode.length > pc + 1) {
            endState.opCode = uint8(bytecode[pc + 1]);
        }
        endState.gas = gas - Params.G_LOW;
        endState.codeHash = codeProof.hashCodeProof();
        endState.stackSize = stackSize-1; // [NEW] endstate stacksize will be 1 less than startstate stacksize
        endState.stackHash = keccak256(abi.encodePacked(originalStackHash, c));

        // Assemble the proof
        bytes memory proof;
        proof = proof.concat(startState.encodeStateProof());
        proof = proof.concat(codeProof.encodeCodeProof());
        proof = proof.concat(abi.encodePacked(bytes1(0))); // error code
        proof = proof.concat(stackProof.encodeStackProof());

        assertEq(verifier.verifyOneStepProof(ctx, startState.hashStateProof(), proof), endState.hashStateProof());
    }

    // ----------------------------------------------------------------------------------------------------------------]

    function testDiv(
        uint256 a,
        uint256 b,
        bytes32 originalStackHash,
        uint64 pc,
        uint64 gas,
        bytes memory bytecode,
        uint64 stackSize // [NEW] fuzz the stackSize too

    ) public {
        // Get ground truth of opcode execution
        uint256 c;
        assembly {
            c := div(a, b)
        }

        // Pre-conditions
        vm.assume(bytecode.length > pc); // assume pc is not out of bound
        vm.assume(bytecode[pc] == 0x04); // assume the current bytecode is DIV
        vm.assume(gas >= Params.G_LOW); // assume the gas is enough for DIV
        // vm.assume(gas >= 7); // mul needs at least 5 gas
        vm.assume((stackSize > 1) && (stackSize <= 1024)); // [NEW] assume stackSize is 0-1024
        

        // Construct the code proof
        OneStepProof.CodeProof memory codeProof = OneStepProof.CodeProof(bytecode);

        // Construct the start state
        OneStepProof.StateProof memory startState;
        startState.depth = 1;
        startState.pc = pc;
        startState.opCode = 0x04; // opCode for DIV
        startState.codeHash = codeProof.hashCodeProof();
        startState.gas = gas;
        startState.stackSize = stackSize;
        // startState.stackSize = 2;
        bytes32 stackHash = keccak256(abi.encodePacked(originalStackHash, a));
        stackHash = keccak256(abi.encodePacked(stackHash, b));
        startState.stackHash = stackHash;

        // Construct the stack proof
        OneStepProof.StackProof memory stackProof;
        stackProof.pops = new uint256[](2);
        stackProof.pops[0] = b;
        stackProof.pops[1] = a;
        stackProof.stackHashAfterPops = originalStackHash;

        // Construct the end state using the ground truth
        OneStepProof.StateProof memory endState;
        endState.depth = 1;
        endState.pc = pc + 1;
        if (bytecode.length > pc + 1) {
            endState.opCode = uint8(bytecode[pc + 1]);
        }
        endState.gas = gas - Params.G_LOW;
        endState.codeHash = codeProof.hashCodeProof();
        endState.stackSize = stackSize-1; // [NEW] endstate stacksize will be 1 less than startstate stacksize
        endState.stackHash = keccak256(abi.encodePacked(originalStackHash, c));

        // Assemble the proof
        bytes memory proof;
        proof = proof.concat(startState.encodeStateProof());
        proof = proof.concat(codeProof.encodeCodeProof());
        proof = proof.concat(abi.encodePacked(bytes1(0))); // error code
        proof = proof.concat(stackProof.encodeStackProof());

        assertEq(verifier.verifyOneStepProof(ctx, startState.hashStateProof(), proof), endState.hashStateProof());
    }

    

}

