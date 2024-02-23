module MyAccount::coin{
    use std::signer;

    struct Coin has key{
        value: u8
    }

    entry fun mint(account: &signer, value:u8) {
        move_to<Coin>(account, Coin{value})
    }

    #[test(account = @0x456)]
    fun test_mint(account: &signer) acquires Coin {
        let addr = signer::address_of(account);
        mint(account, 8);
        assert!(borrow_global<Coin>(addr).value==8,0);
    }
}