module MyAccount::Balance{
    use std::coin;
    use std::aptos_account;
    use std::aptos_coin::AptosCoin;
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

    struct WhiteList has key,copy,drop{ //
        address_list: vector<address>,
        balance_map: SimpleMap<address, u64>
    }

    fun assert_is_owner(account_address: address){
        assert!(account_address==@MyAccount, E_NOT_OWNER);
    }

    fun if_contains_get_index(list: vector<address>, client: address):(bool, u64) {
        vector::index_of(&list, &client)
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
        
        let address_list = borrow_global_mut<WhiteList>(account_address).address_list;
        let (if_contains, _) = if_contains_get_index(address_list, client);
        assert!(!if_contains, E_CLIENT_ALREADY_WHITELISTED);

        vector::push_back(&mut address_list, client);
    }

    public fun add_many_to_whitelist(account: &signer, clients: vector<address>) acquires WhiteList {
        let account_address = signer::address_of(account);
        assert_is_owner(account_address);

        let num_clients = vector::length(&clients);
        let address_list = borrow_global_mut<WhiteList>(account_address).address_list;
        let i = 0;
        while(i < num_clients){
            let client = *vector::borrow(&address_list, i);
            let (if_contains, _) = if_contains_get_index(address_list, client);
            assert!(!if_contains, E_CLIENT_ALREADY_WHITELISTED);

            vector::push_back(&mut address_list, client);
            i = i + 1;
        };
    }

    public fun remove_from_whitelist(account: &signer, client: address) acquires WhiteList{
        let account_address = signer::address_of(account);
        assert_is_owner(account_address);

        let address_list = borrow_global_mut<WhiteList>(account_address).address_list;
        let (if_contains, index) = if_contains_get_index(address_list, client);
        assert!(if_contains, E_CLIENT_NOT_WHITELISTED);

        vector::remove(&mut address_list, index);
    }

    public fun remove_many_from_whitelist(account: &signer, clients: vector<address>) acquires WhiteList {
        let account_address = signer::address_of(account);
        assert_is_owner(account_address);

        let num_clients = vector::length(&clients);
        let address_list = borrow_global_mut<WhiteList>(account_address).address_list;
        let i = 0;
        while(i < num_clients){
            let client = *vector::borrow(&address_list, i);
            let (if_contains, index) = if_contains_get_index(address_list, client);
            assert!(if_contains, E_CLIENT_NOT_WHITELISTED);

            vector::remove(&mut address_list, index);
        };
    }

    public fun deposit(account: &signer, client: &signer, amount: u64) acquires WhiteList {
        let account_address = signer::address_of(account);
        let white_list = borrow_global_mut<WhiteList>(account_address);

        let client_address = signer::address_of(client);
        let (if_contains, _) = if_contains_get_index(white_list.address_list, client_address);
        assert!(if_contains, E_CLIENT_NOT_WHITELISTED);

        let client_balance = coin::balance<AptosCoin>(client_address);
        assert!(client_balance >= amount, E_INSUFFICIENT_BALANCE);
        aptos_account::transfer(client, account_address, amount);

        simple_map::add(&mut white_list.balance_map, client_address, amount);
    }
    
    public fun withdraw(account: &signer, client: &signer, amount: u64) acquires WhiteList {
        let account_address = signer::address_of(account);
        let white_list = borrow_global_mut<WhiteList>(account_address);

        let client_address = signer::address_of(client);
        let (if_contains, _) = if_contains_get_index(white_list.address_list, client_address);
        assert!(if_contains, E_CLIENT_NOT_WHITELISTED);

        let client_balance = *simple_map::borrow(&white_list.balance_map, &client_address);
        assert!(client_balance >= amount, E_INSUFFICIENT_BALANCE);

        aptos_account::transfer(account, client_address, amount);
    }

    #[test_only]
    fun get_info(account:&signer):WhiteList acquires WhiteList{
        let white_list = borrow_global<WhiteList>(signer::address_of(account));
        *white_list
    }

    #[test(account=@MyAccount,client=@0x38)]
    public fun test_flow(account: &signer, client:address) acquires WhiteList{
        initialize(account);

        let if_exists = exists<WhiteList>(signer::address_of(account));
        assert!(if_exists, 9);
        // print(&if_exists);

        // add_to_whitelist(account, client);

        // remove_from_whitelist(account, client);
        let y = get_info(account);
        // print(&y);
    }
}