// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DutchAuction {
    // adresse du commissaire-priseur
    address public auctioneer;

    // indice de l'article actuellement en vente
    uint public currentArticleIndex;

    // moment où la vente aux enchères a commencé
    uint public auctionStartTime;

    // durée totale de la vente aux enchères en secondes (ici, 1 heure)
    uint public constant AUCTION_DURATION = 3600;

    // prix initial de l'article en vente
    uint public constant STARTING_PRICE = 1 ether;

    // montant de la diminution de prix par unité de temps
    uint public constant PRICE_DECREMENT = 0.1 ether;

    // prix de réserve en dessous duquel la vente est automatiquement fermée
    uint public constant RESERVE_PRICE = 0.2 ether;

    // structure représentant chaque article en vente
    struct Article {
        string name;
        // prix actuel de l'article
        uint currentPrice;
        // adresse de l'enchérisseur gagnant
        address winningBidder;
        // la vente de l'article est fermée ou non
        bool closed;
    }

    //pour stocke les informations sur tous les articles en vente
    Article[] public articles;

    // evénement signalant qu'une enchère a été placée
    event BidPlaced(uint indexed articleIndex, address indexed bidder, uint amount);

    // modificateur limitant l'accès à certaines fonctions au seul commissaire-priseur
    modifier onlyAuctioneer() {
        require(msg.sender == auctioneer, "Seul le commissaire-priseur peut appeler cette fonction");
        _;
    }

    // modificateur vérifiant si la vente aux enchères est en cours
    modifier auctionOpen() {
        require(block.timestamp >= auctionStartTime, "La vente aux encheres n'a pas encore commence");
        require(block.timestamp < auctionStartTime + AUCTION_DURATION, "La vente aux encheres est terminee");
        _;
    }

    // modificateur vérifiant si un article particulier est encore ouvert à la vente
    modifier articleOpen(uint articleIndex) {
        require(articleIndex < articles.length, "Indice d'article non valide");
        require(!articles[articleIndex].closed, "L'article est deja ferme");
        _;
    }

    // constructeur initialisant le contrat
    constructor() {
        auctioneer = msg.sender;
        auctionStartTime = block.timestamp;

        // ajouter vos articles à la vente
        articles.push(Article("Article 1", STARTING_PRICE, address(0), false));
        articles.push(Article("Article 2", STARTING_PRICE, address(0), false));

        // initialiser l'index de l'article actuel à 0
        currentArticleIndex = 0;
    }

    // fonction renvoyant le prix actuel de l'article
    function getCurrentPrice() public view returns (uint) {
        uint elapsedTime = block.timestamp - auctionStartTime;

        // diminuer le prix toutes les 60 secondes
        uint decrements = elapsedTime / 60;

        // calculer le prix actuel en fonction du temps écoulé
        uint currentPrice = STARTING_PRICE - (PRICE_DECREMENT * decrements);

        // retourner le prix actuel, mais au moins le prix de réserve
        return currentPrice > RESERVE_PRICE ? currentPrice : RESERVE_PRICE;
    }

    // fonction permettant à un enchérisseur de placer une enchère
    function placeBid(uint articleIndex) external payable auctionOpen articleOpen(articleIndex) {
        require(msg.value > 0, "Le montant de l'enchere doit etre superieur a zero");

        // obtenir le prix actuel de l'article
        uint currentPrice = getCurrentPrice();

        // vérifier si le montant de l'enchère est suffisant
        require(msg.value >= currentPrice, "Le montant de l'enchere est inferieur au prix actuel");

        // mettre à jour les informations de l article et signaler l'enchere placee
        articles[articleIndex].winningBidder = msg.sender;
        articles[articleIndex].closed = true;

        emit BidPlaced(articleIndex, msg.sender, msg.value);
    }

    // fonction permettant au commissaire-priseur de passer à l'article suivant
    function moveToNextArticle() external onlyAuctioneer {
        // vérifier si il reste des articles à vendre
        require(currentArticleIndex < articles.length - 1, "Tous les articles ont ete vendus");

        // passer a l article suivant et mettre à jour ses paramètres
        currentArticleIndex++;
        articles[currentArticleIndex].currentPrice = getCurrentPrice();
        articles[currentArticleIndex].closed = false;
    }
}
