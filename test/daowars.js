console.log("Testing DaoWarsRevival");

const DaoWarsRevival = artifacts.require('DaoWarsRevival.sol');
const BigNumber = require('bignumber.js');
const Promise = require('bluebird');

function advanceTime(delay, done) {
	web3.currentProvider.sendAsync({
		jsonrpc: "2.0",
		"method": "evm_increaseTime",
		params: [delay]}, done)
}
var advanceTimeAsync = Promise.promisify(advanceTime);

contract('DaoWarsRevival', async function (accounts) {
    const owner = accounts[1];
    const somebody = accounts[2];
    const oldAccount = accounts[3];
    const votingPeriod = 3600 * 6 + 10;

    it('should allow voting', async function (accounts) {
        const instance = await DaoWarsRevival.new(oldAccount, { from: owner });
        const sendValue = new BigNumber(web3.toWei(100, 'gwei'));

        const proposedByte = 42;
        const voted = await instance.vote(proposedByte);

        const initialTime = await advanceTimeAsync(0);

        assert.equal(
            1,
            voted.receipt.status,
            'Should be able to vote'
        );

        const timeAdvanced = await advanceTimeAsync(votingPeriod);

        assert.equal(
            initialTime.result + votingPeriod,
            timeAdvanced.result,
            'Should fast forward in time the votin period'
        );
    });
});