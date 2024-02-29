module MyAccount::Lottery{
    use std::aptos_account;
    use std::aptos_coin::AptosCoin;
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

    fun random(total_players:u64):u64{
        timestamp::now_microseconds() % total_players 
    }

    public fun initialize(account: &signer){
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

    public fun place_bet(account:&signer, to:address, amount:u64) acquires Lottery{
        assert!(is_initialized(to), E_UNINITIALIZED);

        let from_addr = signer::address_of(account);
        assert!(coin::balance<AptosCoin>(from_addr) >= amount, E_INSUFFICIENT_BALANCE);

        aptos_account::transfer(account, to, amount);

        let lottery = borrow_global_mut<Lottery>(to);
        simple_map::add(&mut lottery.bets_map, from_addr, amount);
        vector::push_back(&mut lottery.bets_list, from_addr);
        lottery.total_amount = lottery.total_amount + amount; 
    }

    public fun get_winner(account:&signer):address acquires Lottery{
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
        *winner
    }

    #[test(account=@MyAccount)]
    fun test_lottery(account: signer) {
        initialize(&account);
    }
}