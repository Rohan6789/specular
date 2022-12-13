//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/interfaces/IVerificationContext.sol";

contract MockVerificationContext is IVerificationContext {
    struct BlockContext {
        bytes32 blockHashAcc;
        address coinbase;
        uint256 timestamp;
        uint256 number;
        uint256 difficulty;
        uint64 gasLimit;
        uint256 chainID;
        uint256 basefee;
    }

    BlockContext private blockContext;

    bytes32 private stateRoot;
    bytes32 private endStateRoot;
    address private origin;
    address private recipient;
    IVerificationContext.TxnType private txnType;
    uint256 private value;
    uint64 private gas;
    uint256 private gasPrice;
    bytes private input;
    bytes32 private inputRoot;
    bytes32 private codeHash;

    function initializeBlockContext(
        bytes32 _blockHashAcc,
        address _coinbase,
        uint256 _timestamp,
        uint256 _number,
        uint256 _difficulty,
        uint64 _gasLimit,
        uint256 _chainID,
        uint256 _basefee
    ) external {
        blockContext.blockHashAcc = _blockHashAcc;
        blockContext.coinbase = _coinbase;
        blockContext.timestamp = _timestamp;
        blockContext.number = _number;
        blockContext.difficulty = _difficulty;
        blockContext.gasLimit = _gasLimit;
        blockContext.chainID = _chainID;
        blockContext.basefee = _basefee;
    }

    function initializeTransactionContext(
        bytes32 _stateRoot,
        bytes32 _endStateRoot,
        address _origin,
        address _recipient,
        IVerificationContext.TxnType _txnType,
        uint256 _value,
        uint64 _gas,
        uint256 _gasPrice,
        bytes32 _inputRoot,
        bytes32 _inputCodeHash,
        bytes calldata _input
    ) external {
        stateRoot = _stateRoot;
        endStateRoot = _endStateRoot;
        origin = _origin;
        recipient = _recipient;
        txnType = _txnType;
        value = _value;
        gas = _gas;
        gasPrice = _gasPrice;
        inputRoot = _inputRoot;
        codeHash = _inputCodeHash;
        input = _input;
    }

    function getBlockHashAcc() external view override returns (bytes32) {
        return blockContext.blockHashAcc;
    }

    function getCoinbase() external view override returns (address) {
        return blockContext.coinbase;
    }

    function getTimestamp() external view override returns (uint256) {
        return blockContext.timestamp;
    }

    function getBlockNumber() external view override returns (uint256) {
        return blockContext.number;
    }

    function getDifficulty() external view override returns (uint256) {
        return blockContext.difficulty;
    }

    function getGasLimit() external view override returns (uint64) {
        return blockContext.gasLimit;
    }

    function getChainID() external view override returns (uint256) {
        return blockContext.chainID;
    }

    function getBaseFee() external view override returns (uint256) {
        return blockContext.basefee;
    }

    function getStateRoot() external view override returns (bytes32) {
        return stateRoot;
    }

    function getEndStateRoot() external view override returns (bytes32) {
        return endStateRoot;
    }

    function getOrigin() external view override returns (address) {
        return origin;
    }

    function getRecipient() external view override returns (address) {
        return recipient;
    }

    function getTxnType() external view override returns (IVerificationContext.TxnType) {
        return txnType;
    }

    function getValue() external view override returns (uint256) {
        return value;
    }

    function getGas() external view override returns (uint256) {
        return gas;
    }

    function getGasPrice() external view override returns (uint256) {
        return gasPrice;
    }

    function getInput() external view override returns (bytes memory) {
        return input;
    }

    function getInputSize() external view override returns (uint64) {
        return uint64(input.length);
    }

    function getInputRoot() external view override returns (bytes32) {
        return inputRoot;
    }

    function getCodeHashFromInput() external view override returns (bytes32) {
        return codeHash;
    }
}
