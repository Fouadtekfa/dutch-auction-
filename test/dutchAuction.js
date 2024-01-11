const DutchAuction = artifacts.require("DutchAuction");

contract('DutchAuction', (accounts) => {
    let dutchAuctionInstance;

    before(async () => {
        dutchAuctionInstance = await DutchAuction.deployed();
    });

    it('should initialize with correct auctioneer address and starting price', async () => {
        // vérifier l'adresse correcte du commissaire-priseur
        const auctioneer = await dutchAuctionInstance.auctioneer.call();
        assert.equal(auctioneer, accounts[0], "L'adresse du commissaire-priseur n'est pas correcte");

        // vérifier que le prix de départ est de 1 ether
        const startingPrice = await dutchAuctionInstance.getCurrentPrice.call();
        assert.equal(startingPrice, web3.utils.toWei('1', 'ether'), "Le prix de départ n'est pas de 1 ether");
    });

    it('should decrease the price over time', async () => {
        const startingPrice = await dutchAuctionInstance.getCurrentPrice.call();

        // avancer le temps de 120 secondes (2 minutes)
        await advanceTime(120);

        // Vérifier que le nouveau prix est inférieur au prix initial
        const newPrice = await dutchAuctionInstance.getCurrentPrice.call();
        assert.isTrue(newPrice.lt(startingPrice), "Le prix n'a pas diminué avec le temps");
    });

    it('should close the auction after a valid bid', async () => {
        // placer une enchère valide
        await dutchAuctionInstance.placeBid(0, { from: accounts[1], value: web3.utils.toWei('1', 'ether') });

        // vérifier si l'article est marqué comme fermé
        const article = await dutchAuctionInstance.articles(0);
        assert.isTrue(article.closed, "L'enchère n'est pas fermée après une enchère valide");
    });

    it('should close the auction after the auction duration', async () => {
        // avancer le temps pour dépasser la durée de l'enchère (supposons que la durée de l'enchère est de 3600 secondes)
        await advanceTime(3600);

        // vérifier si l'enchère est marquée comme fermée
        const article = await dutchAuctionInstance.articles(0);
        assert.isTrue(article.closed, "L'enchère n'est pas fermée après la durée de l'enchère");
    });

    // fonction pour avancer le temps
    async function advanceTime(time) {
        await new Promise((resolve, reject) => {
            web3.currentProvider.send({
                jsonrpc: "2.0",
                method: "evm_increaseTime",
                params: [time],
                id: new Date().getTime()
            }, (err, result) => {
                if (err) { return reject(err); }
                return resolve(result);
            });
        });

        await new Promise((resolve, reject) => {
            web3.currentProvider.send({
                jsonrpc: '2.0',
                method: 'evm_mine',
                id: new Date().getTime()
            }, (err, result) => {
                if (err) { return reject(err); }
                return resolve(result);
            });
        });
    }
});