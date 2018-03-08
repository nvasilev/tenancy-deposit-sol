let TenancyContract = artifacts.require('TenancyContract');

contract('TenancyContract', function(accounts) {
    it("The expected deposit is correct.", async function () {
        let instance = await TenancyContract.deployed();
        let expectedDeposit = await instance.getExpectedDeposit();
        assert.equal(10, expectedDeposit);
    })
});