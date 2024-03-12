module MyAccount::Balance{
    use std::coin;
    use std::account;
    use std::aptos_account;
    use std::aptos_coin::{AptosCoin, Self};
    use std::debug::print;
    use std::signer;
    use std::simple_map::{Self, SimpleMap};
    use std::vector;

    // errors
    const E_ALREADY_INITIALIZED:u64 = 0;
    const E_UNINITIALIZED:u64 = 1;
    const E_NOT_OWNER:u64 = 2;
    const E_CLIENT_NOT_WHITELISTED:u64 = 3;
    const E_CLIENT_ALREADY_WHITELISTED:u64 = 4;
    const E_INSUFFICIENT_BALANCE:u64 = 5;

    struct WhiteList has key {
        address_list: vector<address>,
        balance_map: SimpleMap<address, u64>
    }

    fun assert_is_owner(account_address: address){
        assert!(account_address==@MyAccount, E_NOT_OWNER);
    }

    #[view]
    public fun is_whitelisted(stored_at: address, client: address):bool acquires WhiteList {
        let white_list = borrow_global<WhiteList>(stored_at);
        vector::contains(&white_list.address_list, &client)
    }

    #[view]
    public fun get_balance(stored_at: address, client: address):u64 acquires WhiteList {
        let white_list = borrow_global<WhiteList>(stored_at);
        *simple_map::borrow(&white_list.balance_map, &client)
    }

    public fun initialize(account: &signer){
        assert!(!exists<WhiteList>(signer::address_of(account)), E_ALREADY_INITIALIZED);

        move_to<WhiteList>(account, WhiteList{
            address_list: vector::empty(),
            balance_map: simple_map::new()
        });
    }

    public fun add_to_whitelist(account: &signer, client: address) acquires WhiteList {
        let account_address = signer::address_of(account);
        assert_is_owner(account_address);
        assert!(exists<WhiteList>(account_address), E_UNINITIALIZED);        
        assert!(!is_whitelisted(account_address, client), E_CLIENT_ALREADY_WHITELISTED);

        let white_list = borrow_global_mut<WhiteList>(account_address);
        vector::push_back(&mut white_list.address_list, client);
        simple_map::add(&mut white_list.balance_map, client, 0);
    }

    public fun add_many_to_whitelist(account: &signer, clients: vector<address>) acquires WhiteList {
        let account_address = signer::address_of(account);
        assert_is_owner(account_address);

        let num_clients = vector::length(&clients);
        let i = 0;
        while(i < num_clients){
            let client = vector::borrow(&clients, i);
            assert!(!is_whitelisted(account_address, *client), E_CLIENT_ALREADY_WHITELISTED);

            let white_list = borrow_global_mut<WhiteList>(account_address);
            vector::push_back(&mut white_list.address_list, *client);
            simple_map::add(&mut white_list.balance_map, *client, 0);
            i = i + 1;
        };
    }

    public fun remove_from_whitelist(account: &signer, client: address) acquires WhiteList{
        let account_address = signer::address_of(account);
        assert_is_owner(account_address);

        let white_list = borrow_global_mut<WhiteList>(account_address);
        let (if_contains, index) = vector::index_of(&white_list.address_list, &client);
        assert!(if_contains, E_CLIENT_NOT_WHITELISTED);

        vector::remove(&mut white_list.address_list, index);
        simple_map::remove(&mut white_list.balance_map, &client);   
    }

    public fun remove_many_from_whitelist(account: &signer, clients: vector<address>) acquires WhiteList {
        let account_address = signer::address_of(account);
        assert_is_owner(account_address);

        let num_clients = vector::length(&clients);
        let white_list = borrow_global_mut<WhiteList>(account_address);
        let i = 0;
        while(i < num_clients){
            let client = vector::borrow(&clients, i);
            let (if_contains, index) = vector::index_of(&white_list.address_list, client);
            assert!(if_contains, E_CLIENT_NOT_WHITELISTED);

            vector::remove(&mut white_list.address_list, index);
            simple_map::remove(&mut white_list.balance_map, client);   
            i = i + 1;
        };
    }

    public fun deposit(account: &signer, client: &signer, amount: u64) acquires WhiteList {
        let account_address = signer::address_of(account);

        let client_address = signer::address_of(client);
        assert!(is_whitelisted(account_address, client_address), E_CLIENT_NOT_WHITELISTED);

        let client_balance = coin::balance<AptosCoin>(client_address);
        assert!(client_balance >= amount, E_INSUFFICIENT_BALANCE);
        aptos_account::transfer(client, account_address, amount);
        
        let balance = simple_map::borrow_mut(&mut borrow_global_mut<WhiteList>(account_address).balance_map, &client_address);
        *balance = *balance + amount;
    }
    
    public fun withdraw(account: &signer, client: &signer, amount: u64) acquires WhiteList {
        let account_address = signer::address_of(account);

        let client_address = signer::address_of(client);
        assert!(is_whitelisted(account_address, client_address), E_CLIENT_NOT_WHITELISTED);

        let client_balance = simple_map::borrow_mut(&mut borrow_global_mut<WhiteList>(account_address).balance_map, &client_address);
        assert!(*client_balance >= amount, E_INSUFFICIENT_BALANCE);

        *client_balance = *client_balance - amount;
        aptos_account::transfer(account, client_address, amount);
    }

    #[test(account=@MyAccount,aptos_framework=@0x1)]
    public fun test_balance(account: &signer,aptos_framework: &signer) acquires WhiteList{
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(aptos_framework);
        let stored_at = signer::address_of(account);
        let client1 = account::create_account_for_test(@0x45);
        let client2 = account::create_account_for_test(@0x46);
        
        // initialization
        initialize(account);
        assert!(exists<WhiteList>(stored_at), 9);

        // adding single client to whitelist
        add_to_whitelist(account, signer::address_of(&client1));
        assert!(vector::length(&borrow_global<WhiteList>(stored_at).address_list)==1, 9);
        assert!(simple_map::length(&borrow_global<WhiteList>(stored_at).balance_map)==1, 9);

        // removing single client from whitelist
        remove_from_whitelist(account, signer::address_of(&client1));
        assert!(vector::length(&borrow_global<WhiteList>(stored_at).address_list)==0, 9);
        assert!(simple_map::length(&borrow_global<WhiteList>(stored_at).balance_map)==0, 9);

        // adding multiple clients to whitelist
        let list_add = vector<address>[@0x11,@0x12,@0x13,@0x14,@0x15];
        add_many_to_whitelist(account, list_add);
        assert!(vector::length(&borrow_global<WhiteList>(stored_at).address_list)==5, 9);
        assert!(simple_map::length(&borrow_global<WhiteList>(stored_at).balance_map)==5, 9);

        // removing multiple clients from whitelist
        let list_remove = vector<address>[@0x13,@0x11,@0x15];
        remove_many_from_whitelist(account, list_remove);
        assert!(vector::length(&borrow_global<WhiteList>(stored_at).address_list)==2, 9);
        assert!(simple_map::length(&borrow_global<WhiteList>(stored_at).balance_map)==2, 9);

        // deposit
        let client2_address = signer::address_of(&client2);
        add_to_whitelist(account, client2_address);
        assert!(vector::length(&borrow_global<WhiteList>(stored_at).address_list)==3, 9);
        assert!(simple_map::length(&borrow_global<WhiteList>(stored_at).balance_map)==3, 9);
        
        coin::register<AptosCoin>(&client2);
        aptos_coin::mint(aptos_framework, client2_address,100);
        deposit(account, &client2, 80);
        assert!(get_balance(stored_at, client2_address)==80,9);

        // withdraw
        withdraw(account, &client2, 20);
        assert!(get_balance(stored_at, client2_address)==60,9);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}