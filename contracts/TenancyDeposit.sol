pragma solidity ^0.4.18;

contract TenancyDeposit {

    enum ContractStatus {UNSIGNED, DEPOSIT_REQUIRED, ACTIVE, COMPLETE, DEDUCTION_CLAIMING, DEDUCTION_CLAIMED, DISPUTE, DISPUTE_RESOLVED, DONE}

    ContractStatus status = ContractStatus.UNSIGNED;

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

    modifier withContractStatus(ContractStatus _status) {
        require(status == _status);
        _;
    }

    address contractAddress;
    address landlord;
    bool landlordDeductionClaimed;
    bool landlordDeductionPaid;
    uint landlordDeductionClaim;
    address tenant;
    bool tenantDeductionClaimed;
    bool tenantDepositReturned;
    uint tenantDeductionClaim;
    address arbiter;
    uint arbiterDeductionClaim;
    uint expectedDeposit;
    uint paidDeposit;
    uint creationDate;

    function TenancyDeposit(address _tenant, address _arbiter, uint _expectedDeposit) public payable
    {
        require(_tenant != msg.sender);
        require(_arbiter != msg.sender);
        require(_arbiter != _tenant);
        require(_expectedDeposit > 0 ether);
        require(status == ContractStatus.UNSIGNED);

        contractAddress = this;

        landlord = msg.sender;
        landlordDeductionClaimed = false;
        landlordDeductionClaim = 0;

        tenant = _tenant;
        tenantDeductionClaimed = false;
        tenantDeductionClaim = 0;

        arbiter = _arbiter;
        arbiterDeductionClaim = 0;

        expectedDeposit = _expectedDeposit;
        paidDeposit = 0 ether;

        creationDate = block.timestamp;

        status = ContractStatus.DEPOSIT_REQUIRED;
    }

    function signContract() public payable
    tenantOnly
    withContractStatus(ContractStatus.DEPOSIT_REQUIRED)
    {
        require(expectedDeposit <= msg.value);
        paidDeposit = msg.value;
        status = ContractStatus.ACTIVE;
    }

    function terminateContract() public payable withContractStatus(ContractStatus.ACTIVE) {
        require(tenant == msg.sender || landlord == msg.sender);
        status = ContractStatus.COMPLETE;
    }

    function tenantClaimDeduction(uint _tenantDeductionClaim) public tenantOnly {
        require(status == ContractStatus.COMPLETE || status == ContractStatus.DEDUCTION_CLAIMING);
        require(!tenantDeductionClaimed);
        require(_tenantDeductionClaim <= paidDeposit);

        tenantDeductionClaim = _tenantDeductionClaim;
        tenantDeductionClaimed = true;

        if (landlordDeductionClaimed) {
            status = ContractStatus.DEDUCTION_CLAIMED;
        } else {
            status = ContractStatus.DEDUCTION_CLAIMING;
        }
    }

    function landlordClaimDeduction(uint _landlordDeductionClaim) public landlordOnly {
        require(status == ContractStatus.COMPLETE || status == ContractStatus.DEDUCTION_CLAIMING);
        require(!landlordDeductionClaimed);
        require(_landlordDeductionClaim <= paidDeposit);

        landlordDeductionClaim = _landlordDeductionClaim;
        landlordDeductionClaimed = true;

        if (tenantDeductionClaimed) {
            status = ContractStatus.DEDUCTION_CLAIMED;
        } else {
            status = ContractStatus.DEDUCTION_CLAIMING;
        }
    }

    function withdrawLandlordClaim() public payable landlordOnly {
        require(status == ContractStatus.DEDUCTION_CLAIMED || status == ContractStatus.DISPUTE_RESOLVED);
        require(!landlordDeductionPaid);

        if (landlordDeductionClaim != tenantDeductionClaim) {
            status = ContractStatus.DISPUTE;
            return;
        }

        msg.sender.transfer(landlordDeductionClaim);
        landlordDeductionPaid = true;
        if (tenantDepositReturned) {
            status = ContractStatus.COMPLETE;
        }
    }

    function withdrawTenantDeposit() public payable tenantOnly {
        require(status == ContractStatus.DEDUCTION_CLAIMED || status == ContractStatus.DISPUTE_RESOLVED);
        require(!tenantDepositReturned);

        if (landlordDeductionClaim != tenantDeductionClaim) {
            status = ContractStatus.DISPUTE;
            return;
        }

        uint deduction = landlordDeductionClaim;
        if (status == ContractStatus.DISPUTE_RESOLVED) {
            deduction = arbiterDeductionClaim;
        }

        msg.sender.transfer(paidDeposit - deduction);
        tenantDepositReturned = true;
        if (tenantDepositReturned) {
            status = ContractStatus.COMPLETE;
        }
    }

    function resolveDispute(uint claim) public payable arbiterOnly withContractStatus(ContractStatus.DISPUTE) {
        require(tenantDeductionClaim != landlordDeductionClaim);
        require(claim <= paidDeposit);

        arbiterDeductionClaim = claim;
        status = ContractStatus.DISPUTE_RESOLVED;
        // TODO collect fee
    }

    function getExpectedDeposit() view public returns (uint) {
        return expectedDeposit;
    }

    function getPaidDeposit() view public returns (uint) {
        return contractAddress.balance;
    }

    function getContractStatus() view public returns (ContractStatus) {
        return status;
    }

}
