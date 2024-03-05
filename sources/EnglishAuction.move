module MyAccount::EnglishAuction{
    use std::account;
    use std::signer;
    use std::simple_map::{Self,SimpleMap};
    use std::vector;

    use MyAccount::BasicToken;

    //errors
    const E_NOT_OWNER:u64 = 0;
    const E_ALREADY_INITIALIZED:u64 = 1;
    const E_UNINITIALIZED:u64 = 2;
    const E_INSUFFICIENT_BALANCE:u64 = 3;
    const E_AUCTION_CONCLUDED:u64 = 4;
    const E_BID_ALREADY_PLACED:u64 = 5;

    struct Auction has key{
        bidders_map: SimpleMap<address, u64>,
        bidders_vector: vector<address>,
        winner: address
    }

    public fun is_owner(addr: address) {
        assert!(addr==@MyAccount, E_NOT_OWNER);
    }

    public fun is_initialized(addr: address):bool {
        exists<Auction>(addr)
    }
    
    public fun bid_placed(addr:address, stored_at:address):bool acquires Auction{
        let auction = borrow_global<Auction>(stored_at);
        vector::contains(&auction.bidders_vector, &addr)
    }

    public fun initialize(account: &signer) {
        let addr = signer::address_of(account);
        is_owner(addr);
        assert!(!is_initialized(addr), E_ALREADY_INITIALIZED);

        let new_auction = Auction{
            bidders_map: simple_map::new(),
            bidders_vector: vector::empty(),
            winner: @0x0
        };

        move_to<Auction>(account, new_auction);
    }

    public fun place_bid(account:&signer, amount:u64, stored_at: address) acquires Auction{
        let addr = signer::address_of(account);

        assert!(is_initialized(stored_at),E_UNINITIALIZED);
        assert!(borrow_global<Auction>(stored_at).winner == @0x0, E_AUCTION_CONCLUDED);
        assert!(!bid_placed(addr, stored_at), E_BID_ALREADY_PLACED);
        assert!(BasicToken::get_balance(addr) >= amount, E_INSUFFICIENT_BALANCE);

        let auction = borrow_global_mut<Auction>(stored_at);
        simple_map::add(&mut auction.bidders_map, addr, amount);
        vector::push_back(&mut auction.bidders_vector, addr);

        BasicToken::burn(BasicToken::withdraw(account, amount));
    }

    public fun get_winner(addr: address) acquires Auction {
        let auction = borrow_global_mut<Auction>(addr);
        is_owner(addr);
        assert!(is_initialized(addr),E_UNINITIALIZED);
        assert!(auction.winner==@0x0, E_AUCTION_CONCLUDED);

        let total_bidders = vector::length(&auction.bidders_vector);
        let i=0;
        let highest_bid = 0;
        let winner = @0x0;

        while(i < total_bidders) {
            let bidder = vector::borrow(&auction.bidders_vector, i);
            let bid = simple_map::borrow(&auction.bidders_map, bidder);
            if(*bid > highest_bid){
                highest_bid = *bid;
                winner = *bidder;
            };
            i = i+1;
        };
        auction.winner = winner;
    }

    #[test(account=@MyAccount)]
    public fun test_auction(account:signer) acquires Auction {
        let addr = signer::address_of(&account);

        let acc1 = account::create_account_for_test(@0x11);
        let acc2 = account::create_account_for_test(@0x12);
        let acc3 = account::create_account_for_test(@0x13);
        let acc4 = account::create_account_for_test(@0x14);

        //initialization
        initialize(&account);

        //create balance,mint,deposit
        BasicToken::create_balance(&acc1);
        BasicToken::create_balance(&acc2);
        BasicToken::create_balance(&acc3);
        BasicToken::create_balance(&acc4);

        BasicToken::deposit(signer::address_of(&acc1), BasicToken::mint(110));
        BasicToken::deposit(signer::address_of(&acc2), BasicToken::mint(200));
        BasicToken::deposit(signer::address_of(&acc3), BasicToken::mint(50));
        BasicToken::deposit(signer::address_of(&acc4), BasicToken::mint(300));

        //place bid
        place_bid(&acc1, 100, addr);
        place_bid(&acc2, 200, addr);
        place_bid(&acc3, 50, addr);
        place_bid(&acc4, 290, addr);
        assert!(BasicToken::get_balance(signer::address_of(&acc1))==10, 9);
        assert!(BasicToken::get_balance(signer::address_of(&acc2))==0, 9);
        assert!(BasicToken::get_balance(signer::address_of(&acc3))==0, 9);
        assert!(BasicToken::get_balance(signer::address_of(&acc4))==10, 9);

        //get winner
        get_winner(addr);
        assert!(borrow_global<Auction>(addr).winner == signer::address_of(&acc4), 9);
    }
}