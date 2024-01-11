const DutchAuction = artifacts.require("DutchAuction");

contract('DutchAuction', (accounts) => {
    let dutchAuctionInstance;

    before(async () => {
        dutchAuctionInstance = await DutchAuction.deployed();
    });

    it('should initialize with correct auctioneer address and starting price', async () => {
        const auctioneer = await dutchAuctionInstance.auctioneer.call();
        assert.equal(auctioneer, accounts[0], "L'adresse du commissaire-priseur n'est pas correcte");

        const startingPrice = await dutchAuctionInstance.getCurrentPrice.call();
        assert.equal(startingPrice, web3.utils.toWei('1', 'ether'), "Le prix de départ n'est pas de 1 ether");
    });
});
