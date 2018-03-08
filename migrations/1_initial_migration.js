var Migrations = artifacts.require("./Migrations.sol");
var TenancyContract = artifacts.require("./TenancyContract.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(TenancyContract,"0xffcf8fdee72ac11b5c542428b35eef5769c409f0",
                                  "0x22d491bde2303f2f43325b2108d26f1eaba1e32b",
                                  10,
                                  20
      );
};
