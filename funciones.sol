//pragma solidity >=0.4.0 <0.7.0;

contract FuncionesBlockChain {
    // ID del remitente 
    function MsgSender() public view returns(address) {
        return msg.sender;
    }
    // Block.gaslimit
    function BlockGasLimit() public view returns(uint) {
        return block.gaslimit;
    }
    // Block.coinbase 
    function BlockCoinBase() public view returns(address) {
        return block.coinbase;
    }
    // data
    function BlockNum() public view returns(uint) {
        return block.number;
    }
    function GasPrice() public view returns(uint) {
        return tx.gasprice;
    }

}