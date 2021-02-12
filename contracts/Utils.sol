pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Utils {
  
   function getMethodSig(bytes memory data) public pure returns (bytes4) {
        return (bytes4(data[0]) | bytes4(data[1]) >> 8 |
            bytes4(data[2]) >> 16 | bytes4(data[3]) >> 24);
    }  

}

