module LotteryAt::Lottery{
    use std::account;
    use std::aptos_account;
    use std::aptos_coin::{AptosCoin, Self};
    use std::code;
    use std::coin;
    use std::debug::print;
    use std::resource_account;
    use std::signer;
    use std::simple_map::{Self,SimpleMap};
    use std::timestamp;
    use std::vector;

    // errors
    const E_NOT_ADMIN:u64 = 0;
    const E_ALREADY_INITIALIZED:u64 = 1;
    const E_UNINITIALIZED:u64 = 2;
    const E_INSUFFICIENT_BALANCE:u64 = 3;
    const E_INSUFFICIENT_PLAYERS:u64 = 4;
    const E_LOTTERY_CONCLUDED:u64 = 5;
    const E_LOTTERY_NOT_CONCLUDED:u64 = 6;
    const E_NOT_OWNER:u64 = 7;

    struct Lottery has key{
        bets_map: SimpleMap<address, u64>,
        bets_list: vector<address>,
        winner: address,
        total_amount: u64
    }

    struct Config has key{
        signer_cap: account::SignerCapability,
        origin_addr: address
    }

    fun is_initialized():bool {
        exists<Lottery>(@LotteryAt)
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

    #[view]
    public fun get_admin():address {
        @Admin
    }

    fun random(total_players:u64):u64{
        timestamp::now_microseconds() % total_players 
    }

    fun init_module(resource_signer: &signer){
        assert!(!is_initialized(), E_ALREADY_INITIALIZED);

        move_to<Lottery>(resource_signer, Lottery{
            bets_map: simple_map::new(),
            bets_list: vector::empty(),
            winner: @0x0,
            total_amount: 0
        });

        let signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @Origin);
        move_to<Config>(resource_signer, Config{
            signer_cap,
            origin_addr: @Origin
        });
    }
    
    public entry fun upgrade(owner: &signer, metadata_serialized: vector<u8>,code: vector<vector<u8>>)acquires Config {
        let config = borrow_global<Config>(@LotteryAt);
        assert!(config.origin_addr == signer::address_of(owner), E_NOT_OWNER);
        
        let res_signer = account::create_signer_with_capability(&config.signer_cap);
        code::publish_package_txn(&res_signer, metadata_serialized, code);
    }

    public entry fun place_bet(account:&signer, amount:u64) acquires Lottery{
        assert!(is_initialized(), E_UNINITIALIZED);

        let from_addr = signer::address_of(account);
        assert!(coin::balance<AptosCoin>(from_addr) >= amount, E_INSUFFICIENT_BALANCE);

        aptos_account::transfer(account, @LotteryAt, amount);

        let lottery = borrow_global_mut<Lottery>(@LotteryAt);
        simple_map::add(&mut lottery.bets_map, from_addr, amount);
        vector::push_back(&mut lottery.bets_list, from_addr);
        lottery.total_amount = lottery.total_amount + amount; 
    }

    public entry fun declare_winner(account:&signer) acquires Lottery, Config{
        assert!(signer::address_of(account) == @Admin, E_NOT_ADMIN);
        assert!(is_initialized(), E_UNINITIALIZED);
        
        let lottery = borrow_global_mut<Lottery>(@LotteryAt);
        let total_players = vector::length(&lottery.bets_list);
        assert!(total_players >= 3 , E_INSUFFICIENT_PLAYERS);
        assert!(lottery.winner == @0x0, E_LOTTERY_CONCLUDED);
        
        let random_value = random(total_players);
        let winner = vector::borrow(&lottery.bets_list,random_value);
        lottery.winner = *winner;
        
        let res_signer = account::create_signer_with_capability(&borrow_global<Config>(@LotteryAt).signer_cap);
        aptos_account::transfer(&res_signer,*winner,lottery.total_amount);
    }
}