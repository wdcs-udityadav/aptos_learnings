module MyAccount::DutchAuction{
    use std::debug::print;
    use std::signer;
    use std::timestamp;

    struct Auction has key{
        seller:address,
        starting_price:u64,
        starts_at:u64,
        discount_rate:u64,
        ends_at:u64
    }

    public fun initialize(account:&signer,starting_price:u64, discount_rate:u64, duration:u64) {
        let addr = signer::address_of(account);
        assert!(addr==@MyAccount, 0);
        assert!(!exists<Auction>(addr), 1);
        
        let now = timestamp::now_seconds();
        let new_auction = Auction{
            seller:signer::address_of(account),
            starting_price,
            starts_at:now,
            discount_rate,
            ends_at: now + duration
        };
        move_to<Auction>(account, new_auction);
    }

    public fun get_price(stored_at:address):u64 acquires Auction{
        assert!(exists<Auction>(stored_at), 2);
        let auction = borrow_global<Auction>(stored_at);
        
        let time_elapsed = timestamp::now_seconds() - auction.starts_at;
        auction.starting_price - ((time_elapsed * auction.discount_rate)/10000)
    }

    #[test(account=@MyAccount, framework=@0x1)]
    fun test_auction(account:signer, framework:signer)acquires Auction {
        timestamp::set_time_has_started_for_testing(&framework);

        let addr = signer::address_of(&account);
        
        let discount_rate = 20;     // 0.2%
        let duration = 3600;
        initialize(&account,1000,discount_rate,duration);
        assert!(exists<Auction>(addr), 2);

        timestamp::fast_forward_seconds(500);
        assert!(get_price(addr) == 999, 9);
    }
}