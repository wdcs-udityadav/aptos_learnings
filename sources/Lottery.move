module MyAccount::Lottery{
    use std::account;
    use std::aptos_account;
    use std::aptos_coin::{AptosCoin, Self};
    use std::coin;
    use std::debug::print;
    use std::signer;
    use std::simple_map::{Self,SimpleMap};
    use std::timestamp;
    use std::vector;

    // errors
    const E_NOT_OWNER:u64 = 0;
    const E_ALREADY_INITIALIZED:u64 = 1;
    const E_UNINITIALIZED:u64 = 2;
    const E_INSUFFICIENT_BALANCE:u64 = 3;
    const E_INSUFFICIENT_PLAYERS:u64 = 4;
    const E_LOTTERY_CONCLUDED:u64 = 5;
    const E_LOTTERY_NOT_CONCLUDED:u64 = 6;

    struct Lottery has key{
        bets_map: SimpleMap<address, u64>,
        bets_list: vector<address>,
        winner: address,
        total_amount: u64
    }

    fun assert_is_owner(addr: address) {
        assert!(addr == @MyAccount, E_NOT_OWNER);
    }

    fun is_initialized(addr: address):bool {
        exists<Lottery>(addr)
    }

    #[view]
    public fun get_total_players(stored_at:address):u64 acquires Lottery{
        vector::length(&borrow_global<Lottery>(stored_at).bets_list)
    }

    #[view]
    public fun get_total_amount(stored_at:address):u64 acquires Lottery {
        borrow_global<Lottery>(stored_at).total_amount
    }

    #[view]
    public fun get_bet(stored_at: address,player:address):u64 acquires Lottery {
        let lottery = borrow_global<Lottery>(stored_at);
        *simple_map::borrow(&lottery.bets_map, &player)
    }

    #[view]
    public fun get_winner(stored_at: address):address acquires Lottery{
        let lottery = borrow_global<Lottery>(stored_at);
        assert!(lottery.winner != @0x0, E_LOTTERY_NOT_CONCLUDED);
        lottery.winner
    }

    fun random(total_players:u64):u64{
        timestamp::now_microseconds() % total_players 
    }

    public entry fun initialize(account: &signer){
        let addr = signer::address_of(account);
        assert_is_owner(addr);
        assert!(!is_initialized(addr), E_ALREADY_INITIALIZED);

        move_to<Lottery>(account, Lottery{
            bets_map: simple_map::new(),
            bets_list: vector::empty(),
            winner: @0x0,
            total_amount: 0
        });
    }

    public entry fun place_bet(account:&signer, to:address, amount:u64) acquires Lottery{
        assert!(is_initialized(to), E_UNINITIALIZED);

        let from_addr = signer::address_of(account);
        assert!(coin::balance<AptosCoin>(from_addr) >= amount, E_INSUFFICIENT_BALANCE);

        aptos_account::transfer(account, to, amount);

        let lottery = borrow_global_mut<Lottery>(to);
        simple_map::add(&mut lottery.bets_map, from_addr, amount);
        vector::push_back(&mut lottery.bets_list, from_addr);
        lottery.total_amount = lottery.total_amount + amount; 
    }

    public entry fun declare_winner(account:&signer) acquires Lottery{
        let addr = signer::address_of(account);
        assert_is_owner(addr);
        assert!(is_initialized(addr), E_UNINITIALIZED);
        
        let lottery = borrow_global_mut<Lottery>(addr);
        let total_players = vector::length(&lottery.bets_list);
        assert!(total_players >= 3 , E_INSUFFICIENT_PLAYERS);
        assert!(lottery.winner == @0x0, E_LOTTERY_CONCLUDED);
        
        let random_value = random(total_players);
        let winner = vector::borrow(&lottery.bets_list,random_value);
        lottery.winner = *winner;
        
        aptos_account::transfer(account,*winner,lottery.total_amount);
    }

    #[test(owner=@MyAccount, aptos_framework=@0x1)]
    fun test_lottery(owner:signer, aptos_framework:signer) acquires Lottery {
        let stored_at = signer::address_of(&owner);

        timestamp::set_time_has_started_for_testing(&aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);

        let user1 = account::create_account_for_test(@0x4);
        let user2 = account::create_account_for_test(@0x5);
        let user3 = account::create_account_for_test(@0x6);
        let user4 = account::create_account_for_test(@0x7);

        coin::register<AptosCoin>(&user1); 
        coin::register<AptosCoin>(&user2); 
        coin::register<AptosCoin>(&user3); 
        coin::register<AptosCoin>(&user4);

        aptos_coin::mint(&aptos_framework, signer::address_of(&user1), 200);
        aptos_coin::mint(&aptos_framework, signer::address_of(&user2), 190);
        aptos_coin::mint(&aptos_framework, signer::address_of(&user3), 250);
        aptos_coin::mint(&aptos_framework, signer::address_of(&user4), 350);

        initialize(&owner);

        place_bet(&user1, stored_at, 150);
        place_bet(&user2, stored_at, 190);
        place_bet(&user3, stored_at, 200);
        place_bet(&user4, stored_at, 300);

        assert!(get_bet(stored_at, signer::address_of(&user4)) == 300, 0);
        assert!(get_total_players(stored_at) == 4 , 0);
        assert!(get_total_amount(stored_at) == 840, 0); 
        assert!(coin::balance<AptosCoin>(stored_at) == 840, 0);

        declare_winner(&owner);
        print(&get_winner(stored_at));

        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);
    }
}