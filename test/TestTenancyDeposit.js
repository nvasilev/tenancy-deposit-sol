'use strict';

let TenancyDeposit = artifacts.require('TenancyDeposit');

contract('Tenancy Deposit Without A Dispute', function(accounts) {

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
    const landlordAddress = accounts[0];
    const tenantAddress = accounts[1];
    const arbiterAddress = accounts[2];

    let instance = null;

    beforeEach(async function() {
        instance = await TenancyDeposit.new(tenantAddress, arbiterAddress, deposit);
    });

    afterEach(async function() {
       instance = null;
    });


    it("The contract is created correctly.", async function () {
        let actualExpectedDeposit = await instance.getExpectedDeposit();
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualExpectedDeposit, deposit);
        assert.equal(actualPaidDeposit, '0');
        assert.equal(actualContractStatus, ContractStatus.DEPOSIT_REQUIRED);
    });

    it("Tenant should sign the contract successfully.", async function () {
        // when
        await instance.signContract({from: tenantAddress, value: deposit});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.ACTIVE);
    });

    it("Tenant should terminate contract successfully.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});

        // when
        await instance.terminateContract({from: tenantAddress});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.COMPLETE);
    });

    it("Landlord should terminate contract successfully.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});

        // when
        await instance.terminateContract({from: landlordAddress});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.COMPLETE);
    });

    it("Arbiter should not be able to terminate a contract.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});

        // when
        try {
            await instance.terminateContract({from: arbiterAddress});
            assert.fail(0, 1, 'Arbiter has terminated the contact');
        } catch (err) {
            assert.isTrue(err instanceof Error);
        }
    });

    it("Landlord should claim deduction successfully.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});
        await instance.terminateContract({from: tenantAddress});

        await instance.landlordClaimDeduction(1, {from: landlordAddress});

        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.DEDUCTION_CLAIMING);
    });

    it("Tenant should claim deduction successfully.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});
        await instance.terminateContract({from: tenantAddress});

        // when
        await instance.tenantClaimDeduction(1, {from: tenantAddress});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.DEDUCTION_CLAIMING);
    });

    it("Contract should be in correct state when deduction claims equal.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});
        await instance.terminateContract({from: tenantAddress});

        // when
        await instance.tenantClaimDeduction(1, {from: tenantAddress});
        await instance.landlordClaimDeduction(1, {from: landlordAddress});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.DEDUCTION_AGREED);
    });

    it("Tenant should get into a dispute if differs from landlords deduction claim", async function () {
        //given
        await instance.signContract({from: tenantAddress, value: deposit});
        await instance.terminateContract({from: tenantAddress});

        // when
        await instance.landlordClaimDeduction(2, {from: landlordAddress});
        await instance.tenantClaimDeduction(1, {from: tenantAddress});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, deposit);
        assert.equal(actualContractStatus, ContractStatus.DISPUTE);
    });

    it("Tenant should be able to withdraw the remaining of the deposit successfully after arbitrary's decision.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});
        await instance.terminateContract({from: tenantAddress});
        await instance.tenantClaimDeduction(1, {from: tenantAddress});
        await instance.landlordClaimDeduction(2, {from: landlordAddress});
        await instance.resolveDispute(3, {from: arbiterAddress});


        // when
        await instance.withdrawTenantDeposit({from: tenantAddress});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, '3');
        assert.equal(actualContractStatus, ContractStatus.DISPUTE_RESOLVED);
    });

    it("Landlord should be able to withdraw the claimed deduction successfully after arbitrary's decision.", async function () {
        // given
        await instance.signContract({from: tenantAddress, value: deposit});
        await instance.terminateContract({from: tenantAddress});
        await instance.tenantClaimDeduction(1, {from: tenantAddress});
        await instance.landlordClaimDeduction(2, {from: landlordAddress});
        await instance.resolveDispute(3, {from: arbiterAddress});


        // when
        await instance.withdrawLandlordClaim({from: landlordAddress});

        // then
        let actualPaidDeposit = await instance.getPaidDeposit();
        let actualContractStatus = await instance.getContractStatus();

        assert.equal(actualPaidDeposit, '9999999999999999997');
        assert.equal(actualContractStatus, ContractStatus.DISPUTE_RESOLVED);
    });

});
