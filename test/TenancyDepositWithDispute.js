let TenancyDeposit = artifacts.require('TenancyDeposit');

contract('TenancyDeposit', function(accounts) {

    // gas: 6721975, gasPrice: 100000000000

    const ContractStatus = Object.freeze({
        UNSIGNED: 0,
        DEPOSIT_REQUIRED: 1,
        ACTIVE: 2,
        COMPLETE: 3,
        DEDUCTION_CLAIMING: 4,
        DEDUCTION_AGREED: 5,
        DISPUTE: 6,
        DISPUTE_RESOLVED: 7,
        DONE: 8
    });

    const deposit = '10000000000000000000';
    const landlordAddress = "0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1";
    const tenantAddress = "0xffcf8fdee72ac11b5c542428b35eef5769c409f0";
    const arbiterAddress = "0x22d491bde2303f2f43325b2108d26f1eaba1e32b";
    const contractAddress = "0x254dffcd3277c0b1660f6d42efbb754edababc2b";

    // let instance=await TenancyDeposit.deployed();;

    // beforeEach(async function() {
    //     return await TenancyDeposit.new(tenantAddress, arbiterAddress, deposit)
    //         .then(function(_instance) {
    //             instance = _instance;
    //         });
    // });


    it("The expected deposit is correct.", async function () {
        let instance = await TenancyDeposit.deployed();
        let actualDeposit = await instance.getExpectedDeposit();
        assert.equal(actualDeposit, 10);
    });

    it("Initially the contract status is DEPOSIT_REQUIRED.", async function () {
        let instance = await TenancyDeposit.deployed();

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, '0');
        assert.equal(actualContractStatus, ContractStatus.DEPOSIT_REQUIRED);
    });

    it("Tenant should sign the contract successfully.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.signContract({from: tenantAddress, value: deposit});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.ACTIVE);
    });

    it("Tenant should terminate contract successfully.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.terminateContract({from: tenantAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.COMPLETE);
    });

    xit("Landlord should terminate contract successfully.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.terminateContract({from: landlordAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.COMPLETE);
    });

    it("Landlord should claim deduction successfully.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.landlordClaimDeduction(1, {from: landlordAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.DEDUCTION_CLAIMING);
    });

    it("Tenant should claim deduction successfully.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.tenantClaimDeduction(2, {from: tenantAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.DISPUTE);
    });

    it("Arbiter should resolve deduction argument.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.resolveDispute(3, {from: arbiterAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.DISPUTE_RESOLVED);
    });

    it("Landlord should be able to withdraw ruled deduction amount successfully.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.withdrawLandlordClaim({from: landlordAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, '9999999999999999997');
        assert.equal(actualContractStatus, ContractStatus.DISPUTE_RESOLVED);
    });

    it("Tenant should be able to withdraw the remaining of the deposit successfully after arbitrary's decision.", async function () {
        let instance = await TenancyDeposit.deployed();

        await instance.withdrawTenantDeposit({from: tenantAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, '0');
        assert.equal(actualContractStatus, ContractStatus.DONE);
    });
});
