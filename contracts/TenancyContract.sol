pragma solidity ^0.4.18;

// import "dev.oraclize.it/api.sol";
// import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
// import "./oraclizeAPI.sol";

contract TenancyContract { // is usingOraclize {
    
    enum Status {UNSIGNED, DEPOSIT_REQUIRED, ACTIVE, COMPLETE, 
                OWNER_DEDUCTION_REQUESTED, TENANT_DEDUCTION_REQUESTED, 
                DEDUCTION_DISPUTE, DISPUTE_RESOLVED, TERMINATED}
    Status status = Status.UNSIGNED;
    
    uint constant MAX_VALUE = ~uint256(0);
    
    modifier landlordOnly() {
        require(landlord == msg.sender);
        _;
    }
    
    modifier tenantOnly() {
        require(tenant == msg.sender);
        _;
    }
    
    modifier arbiterOnly() {
        require(arbiter == msg.sender);
        _;
    }
    
    modifier withStatus(Status _status) {
        require(status == _status);
        _;
    }
    
    address landlord;
    address tenant;
    address arbiter;
    uint expectedDeposit;
    uint paidDeposit;
    uint ownerDeductionClaim;
    uint tenantDeductionClaim;
    uint arbiterDeductionVerdict;
    uint lengthInSeconds;
    // uint pricePerPack = 1 finney;
    
    function TenancyContract(address _tenant, address _arbiter, uint _lengthInSeconds, uint _expectedDeposit) 
        public 
        payable 
        // landlordOnly 
    {
        require(_tenant != msg.sender);
        require(_arbiter != msg.sender);
        require(_tenant != msg.sender);
        require(_expectedDeposit > 0 ether);
        require(status == Status.UNSIGNED);
        
        landlord = msg.sender;
        tenant = _tenant;
        arbiter = _arbiter;
        expectedDeposit = _expectedDeposit;
        paidDeposit = 0 ether;
        ownerDeductionClaim = MAX_VALUE;
        tenantDeductionClaim = MAX_VALUE;
        arbiterDeductionVerdict = MAX_VALUE;
        lengthInSeconds = _lengthInSeconds * 60;
        status = Status.DEPOSIT_REQUIRED;
        // scheduleContractTermination();
    }
    
    // function scheduleContractTermination() {
    //   oraclize_query(lengthInSeconds, "URL", "");
    // }
    
    function signContract() public payable 
        tenantOnly 
        withStatus(Status.DEPOSIT_REQUIRED) 
    {
        require(expectedDeposit <= msg.value);
        paidDeposit = msg.value;
        status = Status.ACTIVE;
    }
    
    // function __callback(bytes32 myid, string result) {
    //     require(msg.sender == oraclize_cbAddress());
        
    //     // status = Status.TENANCY_COMPLETE;
    //      expireTenancyContract();
    // }
    
    // DELETE ME
    function expireTenancyContract() public payable
            landlordOnly
        withStatus(Status.ACTIVE)
    {
        status = Status.COMPLETE;
    }
    
    // TODO investigate potential collision issues
    function claimOwnerDeduction(uint _ownerDeductionClaim) public landlordOnly {
        require(status == Status.COMPLETE || status == Status.TENANT_DEDUCTION_REQUESTED);
        require(ownerDeductionClaim == MAX_VALUE);
        require(_ownerDeductionClaim >= 0);
        require(_ownerDeductionClaim <= paidDeposit);
        
        ownerDeductionClaim = _ownerDeductionClaim;
        
        if (status == Status.COMPLETE) {
            status = Status.OWNER_DEDUCTION_REQUESTED;
        } 
        else if (status == Status.TENANT_DEDUCTION_REQUESTED) {
            if (ownerDeductionClaim == tenantDeductionClaim) {
                status = Status.TERMINATED;
            } else {
                status = Status.DEDUCTION_DISPUTE;
                // TODO notify arbiter?
            }
        }
    }
    
    // TODO investigate potential collision issues
    function claimTenantDeduction(uint _tenantDeductionClaim) public payable tenantOnly {
        require(status == Status.OWNER_DEDUCTION_REQUESTED || status == Status.COMPLETE);
        require(status == Status.COMPLETE);
        require(tenantDeductionClaim == MAX_VALUE);
        require(_tenantDeductionClaim >= 0);
        require(_tenantDeductionClaim <= paidDeposit);
        
        tenantDeductionClaim = _tenantDeductionClaim;
        
        if (status == Status.COMPLETE) {
            status = Status.TENANT_DEDUCTION_REQUESTED;
        } 
        else if (status == Status.OWNER_DEDUCTION_REQUESTED) {
            if (ownerDeductionClaim == tenantDeductionClaim) {
                status = Status.TERMINATED;
            } else {
                status = Status.DEDUCTION_DISPUTE;
                // TODO notify arbiter?
            }
        }
    }
    
    function resolveDispute(uint _arbiterDeductionVerdict) public arbiterOnly {
        require(status == Status.DEDUCTION_DISPUTE);
        require(_arbiterDeductionVerdict != MAX_VALUE);
        require(_arbiterDeductionVerdict >= 0);
        require(_arbiterDeductionVerdict <= paidDeposit);
        
        arbiterDeductionVerdict = _arbiterDeductionVerdict;
        status = Status.DISPUTE_RESOLVED;
    }
    
    function withdrawDeduction() public landlordOnly payable {
        require(status == Status.TERMINATED || status == Status.DISPUTE_RESOLVED);
        // require();
        
        // mapping needed owner => deduction
    }

 
    
    function getExpectedDeposit() view public returns (uint) {
        return expectedDeposit;
    }
    
    function getPaidDeposit() view public returns (uint) {
        return paidDeposit;
    }
    
    function getStatus() view public returns (Status) {
        return status;
    }
    
}