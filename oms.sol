pragma solidity >=0.4.4 <0.9.0;
pragma experimental ABIEncoderV2;

contract OMS {

    address public mainAddress;

    mapping (address => bool) healthCenterApproved;

    event newHealthyCenter(address);
    // param 1: Msg sender, param 2: The contract
    event HealthyCenterApproved(address, address);

    address[] public healthyCenterContracts;

    address[] requestsAccess;

    constructor() public {
        mainAddress = msg.sender;
    }

    // Modifier to approve a new healty center
    modifier canVerify(address sender) {
        require(sender == mainAddress, "This action is only available for the OMS");
        _;
    }

    // Give permissions to a new customer address to create a new center
    function HealtyCenter(address _center) public canVerify(msg.sender) {
        healthCenterApproved[_center] = true;
        
    }

    function requestAccessToOMS(address addr) public {
         requestsAccess.push(addr);
    }

    function getAccessRequests() public view canVerify(msg.sender) returns(address[] memory) {
        return requestsAccess;
    }



    // Contract factory to create new centers
    function CreateaNewHealthyCenter() public {
        // Verify if is approved by OMS
        require(healthCenterApproved[msg.sender], "Your address is not approved to create a new Healthy center");
        // Create a new child contract, that belongs to this main contract
        address healthyContractAddr = address(new HealthCenter(msg.sender));
        // store this new contact address to the OMS array
        healthyCenterContracts.push(healthyContractAddr);
        emit HealthyCenterApproved(msg.sender, healthyContractAddr);
    }

}

// Contract secundary for organizations that depends on OMS
contract HealthCenter {
    address owner; // Owner for this contract
    address contractAddr;
    constructor(address newOwner) public {
        owner = newOwner;
        contractAddr = address(this);
    }

    // Schema for Diagnostic
    struct Diagnostic {
        bool result;
        string result_IPFS;
    }

    event newCovidResult(Diagnostic);

    mapping (bytes32 => Diagnostic) COVID19;

    // Modifier to prevent showing results by an different Owner
    modifier CanDisplayResults(address centerAddress) {
        require(owner == centerAddress, "This action is only available for this contract owner");
        _;
    }
    // function to get covid results
    function setCovidResult(string memory userId, bool diagnostic, string memory IPFS) public CanDisplayResults(msg.sender) {
        bytes32 USER = keccak256(abi.encodePacked(userId));
        Diagnostic memory result = Diagnostic(diagnostic, IPFS);
        COVID19[USER] = result;
        emit newCovidResult(result);
    }

    function getCovidResult(string memory userId) public view returns(string memory, string memory) {
        bytes32 USER = keccak256(abi.encodePacked(userId));
        if (COVID19[USER].result) {
            return ("POSITIVE", COVID19[USER].result_IPFS);
        } else {
            return ("NEGATIVE", COVID19[USER].result_IPFS);
        }
    }
}