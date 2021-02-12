pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20Interface.sol";
import "./MessageRoute.sol";
import "./Whitelist.sol";

/**
 * Maintains workflow state machine flow
 */
contract ActionRouteRegistry is Whitelist, MessageRoute {
    ERC20Interface public stablecoin;
    uint public fee;
    mapping (bytes32 => mapping( bytes4 => ActionRoute)) public actions;
    mapping (address => uint) public accounting;
    

    event Withdrawn(address indexed payee, uint256 weiAmount);

    
    event MessageEntryAdded(
        bytes32 domainSeparator,
        address from,
        address controller,
        bytes32 id
    );

    function getAction(
        bytes32 domainSeparator,
        bytes4 selector
    ) public view returns(ActionRoute memory) {
        return actions[domainSeparator][selector];
    }


    /**
    * XDV Data Token
    */
    constructor(
        address tokenAddress
    ) public  {
        owner = msg.sender;
        stablecoin  = ERC20Interface(tokenAddress);
    }
   
    function setProtocolConfig(uint256 _fee) public {
        require(msg.sender == owner, "INVALID_USER");
        fee = _fee;
    }

    function getProtocolConfig() public returns (uint256) {
        return (fee);
    }

    function withdraw(address payable payee) public {
        require(msg.sender == owner, "INVALID_USER");
        uint256 b = address(this).balance;
        payee.transfer(address(this).balance);

        emit Withdrawn(payee, b);
    }

    function withdrawToken(address payable payee, address token) public {
        require(msg.sender == owner, "INVALID_USER");
        uint256 b = ERC20Interface(token).balanceOf(address(this));
        payee.transfer(b);

        emit Withdrawn(payee, b);
    }

    // topic ABI Function Ethers
    // ExecutePrescription(uint, uint, string) === bytes32
    // 0xA1...

    function mapAction(
        bytes32 domainSeparator,
        address controller,
        bytes4 messageRequest,
        bytes4[] memory conditions,
        bool[] memory conditionStatus,
        address[] memory whitelist
    )
        external
        payable
        returns (bool)
    {

        // User must have a balance
        require(
            stablecoin.balanceOf(msg.sender) >= 0,
            "Invalid token balance"
        );
        // User must have an allowance
        require(
            stablecoin.allowance(msg.sender, address(this)) >= 0,
            "Invalid token allowance"
        );

        require(
            conditions.length == conditionStatus.length,
            "Invalid conditions size"
        );

        require(
            conditions.length < 6,
            "Max 5 conditions"
        );

        require(
            whitelist.length < 6,
            "Max 5 address whitelist"
        );

        /* require(
            stablecoin.balanceOf(msg.sender) == (mintingServiceFee.sum(protocolServiceFee)), 
            "MUST SEND FEE BEFORE USE");
        */

        require(actions[domainSeparator][messageRequest].controller == address(0), "Address already exists");

        // register topic and mutation
        actions[domainSeparator][messageRequest] = ActionRoute({
            selector: messageRequest,
            controller: controller,
            conditions: conditions,
            conditionStatus: conditionStatus
        });

        for (uint i = 0;i < whitelist.length; i++) {
            userWhitelist[whitelist[i]][messageRequest] = true;
        }
        

        // Update accounting
        //  - create mappings to data provider accounting
        //  - create mappings to protocol fee accounting
        // Transfer tokens to pay service fee
        require(
            stablecoin.transferFrom(
                msg.sender,
                address(this), 
                fee),
            "Transfer failed for fee"
        );
        actionWhitelisting[domainSeparator][messageRequest] = true;


        accounting[msg.sender] = accounting[msg.sender] + fee;
        accounting[address(this)] = accounting[address(this)] + fee;
        emit MessageEntryAdded(
            domainSeparator,
            msg.sender,
            controller,
            messageRequest
        );

        return true;
    }       


}