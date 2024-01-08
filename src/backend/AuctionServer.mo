/// Import the necessary libraries:

import Principal "mo:base/Principal";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import List "mo:base/List";


/// Next, define the actor fort he auction platform:

actor {
  /// Define an item for the auction: 
  type Item = {
    /// Define a title for the auction:
    title : Text;
    /// Define a description for the auction:
    description : Text;
    /// Define an image used as an icon for the auction:
    image : Blob;
  };

  /// Define the auction's bid:
  type Bid = {
    /// Define the price for the bid using ICP as the currency:
    price : Nat;
    /// Define the time the bid was placed, measured as the time remaining in the auction: 
    time : Nat;
    /// Define the authenticated user ID of the bid:
    originator : Principal.Principal;
  };

  /// Define an auction ID to uniquely identify the auction:
  type AuctionId = Nat;

  /// Define an auction overview:
  type AuctionOverview = {
    id : AuctionId;
    /// Define the auction sold at the item:
    item : Item;
  };

  /// Define the details of the auction:
  type AuctionDetails = {
    /// Item sold in the auction:
    item : Item;
    /// Bids submitted in the auction:
    bidHistory : [Bid];
    /// Time remaining in the auction:
    /// the auction winner.
    remainingTime : Nat;
  };

  /// Define an internal, non-shared type for storing info about the auction:
  type Auction = {
    id : AuctionId;
    item : Item;
    var bidHistory : List.List<Bid>;
    var remainingTime : Nat;
  };

  /// Create a stable variable to store the auctions:
  stable var auctions = List.nil<Auction>();
  /// Define a counter for generating new auction IDs.
  stable var idCounter = 0;

  /// Define a timer that occurs every second, used to define the time remaining in the open auction:
  func tick() : async () {
    for (auction in List.toIter(auctions)) {
      if (auction.remainingTime > 0) {
        auction.remainingTime -= 1;
      };
    };
  };

  /// Install a timer: 
  let timer = Timer.recurringTimer(#seconds 1, tick);

  /// Define a function to generating a new auction:
  func newAuctionId() : AuctionId {
    let id = idCounter;
    idCounter += 1;
    id;
  };

  /// Define a function to register a new auction that is open for the defined duration:
  public func newAuction(item : Item, duration : Nat) : async () {
    let id = newAuctionId();
    let bidHistory = List.nil<Bid>();
    let newAuction = { id; item; var bidHistory; var remainingTime = duration };
    auctions := List.push(newAuction, auctions);
  };

  /// Define a function to retrieve all auctions: 
  /// Specific auctions can be separately retrieved by `getAuctionDetail`:
  public query func getOverviewList() : async [AuctionOverview] {
    func getOverview(auction : Auction) : AuctionOverview = {
      id = auction.id;
      item = auction.item;
    };
    let overviewList = List.map<Auction, AuctionOverview>(auctions, getOverview);
    List.toArray(List.reverse(overviewList));
  };

  /// Define an internal helper function to retrieve auctions by ID: 
  func findAuction(auctionId : AuctionId) : Auction {
    let result = List.find<Auction>(auctions, func auction = auction.id == auctionId);
    switch (result) {
      case null Debug.trap("Inexistent id");
      case (?auction) auction;
    };
  };

  /// Define a function to retrieve detailed info about an auction using its ID: 
  public query func getAuctionDetails(auctionId : AuctionId) : async AuctionDetails {
    let auction = findAuction(auctionId);
    let bidHistory = List.toArray(List.reverse(auction.bidHistory));
    { item = auction.item; bidHistory; remainingTime = auction.remainingTime };
  };

  /// Define an internal helper function to retrieve the minimum price for an auction's next bid; the next bid must be one unit of currency larger than the last bid: 
  func minimumPrice(auction : Auction) : Nat {
    switch (auction.bidHistory) {
      case null 1;
      case (?(lastBid, _)) lastBid.price + 1;
    };
  };

  /// Make a new bid for a specific auction specified by the ID:
  /// Checks that:
  /// * The user (`message.caller`) is authenticated.
  /// * The price is valid, higher than the last bid, if existing.
  /// * The auction is still open.
  /// If valid, the bid is appended to the bid history.
  /// Otherwise, traps with an error.
  public shared (message) func makeBid(auctionId : AuctionId, price : Nat) : async () {
    let originator = message.caller;
    if (Principal.isAnonymous(originator)) {
      Debug.trap("Anonymous caller");
    };
    let auction = findAuction(auctionId);
    if (price < minimumPrice(auction)) {
      Debug.trap("Price too low");
    };
    let time = auction.remainingTime;
    if (time == 0) {
      Debug.trap("Auction closed");
    };
    let newBid = { price; time; originator };
    auction.bidHistory := List.push(newBid, auction.bidHistory);
  };
};
