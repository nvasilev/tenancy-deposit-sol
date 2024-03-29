pragma solidity ^0.4.18;

contract TenancyDeposit {

    enum ContractStatus {UNSIGNED, DEPOSIT_REQUIRED, ACTIVE, COMPLETE, DEDUCTION_CLAIMING, DEDUCTION_AGREED, DISPUTE, DISPUTE_RESOLVED, MONEY_WITHDRAWAL,DONE}

    event StatusChanged (address indexed _contractAddress, address indexed _from, uint indexed statusIndex);
    event DeductionClaimed (address indexed _contractAddress, address indexed _from, uint claim);
    event DeductionAgreed (address indexed _contractAddress, address indexed _from, uint deduction);
    event DisputeResolved (address indexed _contractAddress, address indexed _from, uint deduction);
    event MoneyWithdrawn  (address indexed _contractAddress, address indexed _from, uint amount);
    event BalanceChanged (address indexed _contractAddress, address indexed _from, uint value);

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
    bool tenantDepositReimbursed;
    uint tenantDeductionClaim;
    address arbiter;
    uint finalDeductionAmount;
    uint expectedDeposit;
    uint paidDeposit;
    uint creationDate;

    function TenancyDeposit(address _tenant, address _arbiter, uint _expectedDeposit) public
    {
        require(_tenant != msg.sender);
        require(_arbiter != msg.sender);
        require(_arbiter != _tenant);
        require(_expectedDeposit > 0 ether);
        require(status == ContractStatus.UNSIGNED);

        contractAddress = this;

        StatusChanged(contractAddress, msg.sender, uint(status));

        landlord = msg.sender;
        landlordDeductionClaimed = false;
        landlordDeductionClaim = 0;

        tenant = _tenant;
        tenantDeductionClaimed = false;
        tenantDeductionClaim = 0;

        arbiter = _arbiter;
        finalDeductionAmount = 0;

        expectedDeposit = _expectedDeposit;
        paidDeposit = 0 ether;

        creationDate = block.timestamp;

        status = ContractStatus.DEPOSIT_REQUIRED;

        StatusChanged(contractAddress, msg.sender, uint(status));
    }

    function signContract() public payable
    tenantOnly
    withContractStatus(ContractStatus.DEPOSIT_REQUIRED)
    {
        require(expectedDeposit <= msg.value);
        paidDeposit = msg.value;
        status = ContractStatus.ACTIVE;

        StatusChanged(contractAddress, msg.sender, uint(status));
        BalanceChanged(contractAddress, msg.sender, contractAddress.balance);
    }

    function terminateContract() public payable withContractStatus(ContractStatus.ACTIVE) {
        require(tenant == msg.sender || landlord == msg.sender);
        status = ContractStatus.COMPLETE;

        StatusChanged(contractAddress, msg.sender, uint(status));
    }

    function tenantClaimDeduction(uint _tenantDeductionClaim) public tenantOnly {
        require(status == ContractStatus.COMPLETE || status == ContractStatus.DEDUCTION_CLAIMING);
        require(!tenantDeductionClaimed);
        require(_tenantDeductionClaim <= paidDeposit);

        tenantDeductionClaim = _tenantDeductionClaim;
        tenantDeductionClaimed = true;

        if (landlordDeductionClaimed) {
            if (tenantDeductionClaim == landlordDeductionClaim) {
                finalDeductionAmount = tenantDeductionClaim;
                status = ContractStatus.DEDUCTION_AGREED;
                DeductionAgreed(contractAddress, msg.sender, landlordDeductionClaim);
            } else {
                status = ContractStatus.DISPUTE;
            }
        } else {
            status = ContractStatus.DEDUCTION_CLAIMING;
        }

        StatusChanged(contractAddress, msg.sender, uint(status));
        DeductionClaimed(contractAddress, msg.sender, tenantDeductionClaim);
    }

    function landlordClaimDeduction(uint _landlordDeductionClaim) public landlordOnly {
        require(status == ContractStatus.COMPLETE || status == ContractStatus.DEDUCTION_CLAIMING);
        require(!landlordDeductionClaimed);
        require(_landlordDeductionClaim <= paidDeposit);

        landlordDeductionClaim = _landlordDeductionClaim;
        landlordDeductionClaimed = true;

        if (tenantDeductionClaimed) {
            if (tenantDeductionClaim == landlordDeductionClaim) {
                finalDeductionAmount = landlordDeductionClaim;
                status = ContractStatus.DEDUCTION_AGREED;
                DeductionAgreed(contractAddress, msg.sender, tenantDeductionClaim);
            } else {
                status = ContractStatus.DISPUTE;
            }
        } else {
            status = ContractStatus.DEDUCTION_CLAIMING;
        }

        StatusChanged(contractAddress, msg.sender, uint(status));
        DeductionClaimed(contractAddress, msg.sender, landlordDeductionClaim);
    }

    function withdrawLandlordClaim() public payable landlordOnly {
        require(status == ContractStatus.DEDUCTION_AGREED || status == ContractStatus.DISPUTE_RESOLVED || status == ContractStatus.MONEY_WITHDRAWAL);
        require(!landlordDeductionPaid);

        msg.sender.transfer(finalDeductionAmount);
        landlordDeductionPaid = true;

        if (tenantDepositReimbursed) {
            status = ContractStatus.DONE;
        } else {
            status = ContractStatus.MONEY_WITHDRAWAL;
        }

        StatusChanged(contractAddress, msg.sender, uint(status));
        MoneyWithdrawn(contractAddress, msg.sender, finalDeductionAmount);
        BalanceChanged(contractAddress, msg.sender, contractAddress.balance);
    }

    function withdrawTenantDeposit() public payable tenantOnly {
        require(status == ContractStatus.DEDUCTION_AGREED || status == ContractStatus.DISPUTE_RESOLVED || status == ContractStatus.MONEY_WITHDRAWAL);
        require(!tenantDepositReimbursed);

        uint transferAmount = paidDeposit - finalDeductionAmount;

        msg.sender.transfer(transferAmount);
        tenantDepositReimbursed = true;

        if (landlordDeductionPaid) {
            status = ContractStatus.DONE;
        } else {
            status = ContractStatus.MONEY_WITHDRAWAL;
        }

        StatusChanged(contractAddress, msg.sender, uint(status));
        MoneyWithdrawn(contractAddress, msg.sender, transferAmount);
        BalanceChanged(contractAddress, msg.sender, contractAddress.balance);
    }

    function resolveDispute(uint claim) public payable arbiterOnly withContractStatus(ContractStatus.DISPUTE) {
        require(tenantDeductionClaim != landlordDeductionClaim);
        require(claim <= paidDeposit);

        finalDeductionAmount = claim;
        status = ContractStatus.DISPUTE_RESOLVED;
        // TODO collect fee

        StatusChanged(contractAddress, msg.sender, uint(status));
        DeductionClaimed(contractAddress, msg.sender, claim);
        DisputeResolved(contractAddress, msg.sender, claim);
    }

    function getExpectedDeposit() view public returns (uint) {
        return expectedDeposit;
    }

    function getPaidDeposit() view public returns (uint) {
        return paidDeposit;
    }

    function getContractBalance() view public returns (uint) {
        return contractAddress.balance;
    }

    function getTenantBalance() view public tenantOnly returns (uint) {
        return msg.sender.balance;
    }

    function getLandlordBalance() view public landlordOnly returns (uint) {
        return msg.sender.balance;
    }

    function getContractStatus() view public returns (ContractStatus) {
        return status;
    }

    function getLandlordDeductionClaim() view public returns (uint) {
        return landlordDeductionClaim;
    }

    function getTenantDeductionClaim() view public returns (uint) {
        return tenantDeductionClaim;
    }

    function getFinalDeductionClaim() view public returns (uint) {
        return finalDeductionAmount;
    }
}
