// pragma solidity >=0.4.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract Hash {
    function calcularHash(string memory cadena) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(cadena));
    }
    function calcularHashWithParameters(string memory cadena, uint _k, address sender) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(cadena, _k, sender));
    }
}