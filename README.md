# Tenancy Deposit Solidity Contract
This is a Truffle project which holds a Solidity contract handling a tenant's deposit in the course of a tenancy agreement for renting a property. 
It returns the deposited amount at the end of the agreement. In case of damages on the property, the contract makes sure that their currency equivalent is being deducted from the deposit and is transfered to the landlord.

## Prerequisites
[Truffle](http://truffleframework.com/) and [Ganache](http://truffleframework.com/ganache/) tools are required to be installed before building/testing this project. 

## Compile
In order to compile the contract, you would need to run the execute the following command in the command line
```
$ truffle compile
```

## Test
In order to compile and run the tests against the Solity contract the following steps are required:
1. Launch Ganache in your command line:
```
$ ganache-cli -d
```
2. Launch your tests in project's folder:
```
$ truffle test
```
Please note that if your test suite grows too much, the accounts which Ganache provides might run out of fuel. Currently there is no way to change the default amount of ether per account, although there is a command line parameter `--defaultBalanceEther` parameter in Ganache's documentation.

## Remix Solidity IDE
For quick experimentation with the contract one might prefer to use [Remix Solidity IDE](http://remix.ethereum.org) as well.
