module MyAccount::FootballCard{
    use std::account;
    use std::signer;
    use std::string::{String,utf8};
    
    const E_CARD_DOESNT_EXIST:u64 = 0;
    const E_CARD_ALREADY_EXISTS:u64 = 1;
    
    struct FootballCard has key{
        id: u8,
        country: String,
        position: u8,
        value: u8
    }
    
    public fun card_exists(addr:address){
        assert!(exists<FootballCard>(addr),E_CARD_DOESNT_EXIST);
    }

    public fun card_doesnt_exist(addr:address){
        assert!(!exists<FootballCard>(addr),E_CARD_ALREADY_EXISTS);
    }

    public fun new_card(id:u8,country:String,position:u8): FootballCard{
        FootballCard{id,country,position, value:0}
    }

    public fun mint(footballCard: FootballCard, account:&signer){
        card_doesnt_exist(signer::address_of(account));
        move_to<FootballCard>(account, footballCard);
    }

    public fun set_price(addr:address, value:u8) acquires FootballCard{
        card_exists(addr);
        let football_card = borrow_global_mut<FootballCard>(addr);
        football_card.value = value;
    }

    public fun transfer(account: &signer, to: &signer) acquires FootballCard{
        let addr = signer::address_of(account);
        card_exists(addr);

        let football_card = move_from<FootballCard>(addr);
        move_to<FootballCard>(to, football_card);
    }

    public fun get_info(addr:address):(String, u8) acquires FootballCard {
        card_exists(addr);
        let football_card = borrow_global<FootballCard>(addr);
        (football_card.country, football_card.value)
    }

    #[test(account=@MyAccount)]
    fun test_flow(account: signer) acquires FootballCard{
        let addr = signer::address_of(&account);
        let to = account::create_account_for_test(@0x12);
        
        //create and mint
        let new_football_card = new_card(1,utf8(b"India"),2);
        mint(new_football_card, &account);
        card_exists(addr);

        //set price
        set_price(addr, 100);

        //get info
        let (country,value) = get_info(addr);
        assert!(country == utf8(b"India"), 8);
        assert!(value == 100, 8);

        //transfer
        transfer(&account, &to);
        card_doesnt_exist(addr);
        card_exists(signer::address_of(&to));
    }
}