pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract WMessages {

    event PropertyChanged(string propName, bytes data);
    event ActionChanged(bytes4 methodSig, bytes request);
    
// A Workflow payload can either be content addressable document or NFT address with supplied token id
    struct WorkflowPayload  {
        // IPLD has containing document
        string documentURI;
        // Agent DID
        string didAgent;
        // Owner address
        address payloadOwner;
        // Owner DID
        string didPayloadOwner;
        // timeout message if router can't find addresss
        uint timeoutAfterRetries;
        // NFT Address if ERC721
        address nftAddress;
        // NFT TokenID
        uint tokenId;
    }

    function getMethodSig(bytes memory data) public pure returns (bytes4) {
        return (bytes4(data[0]) | bytes4(data[1]) >> 8 |
            bytes4(data[2]) >> 16 | bytes4(data[3]) >> 24);
    }
}