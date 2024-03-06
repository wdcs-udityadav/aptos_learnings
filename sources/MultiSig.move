module MyAccount::MultiSig{
    use std::signer;
    
    struct Counter has key{
        count:u8
    }
    
    public entry fun bump(account: &signer) acquires Counter {
        let addr = signer::address_of(account);
        assert!(addr == @Multisig, 0);
        if(!exists<Counter>(addr)){
            move_to<Counter>(account, Counter{count:10})
        } else{
            let countHolder = borrow_global_mut<Counter>(addr);
            countHolder.count = countHolder.count+1;
        }
    }

    #[view]
    public fun get_count(addr: address): u8 acquires Counter{
        assert!(exists<Counter>(addr), 1);
        borrow_global<Counter>(addr).count
    }
}