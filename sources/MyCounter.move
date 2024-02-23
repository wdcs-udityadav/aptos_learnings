module MyAccount::Counter{
    use std::signer;
    
    struct CounterHolder has key{
        count:u8
    }

    public entry fun bump(account: &signer) acquires CounterHolder {
        let addr = signer::address_of(account);
        if(!exists<CounterHolder>(addr)){
            move_to<CounterHolder>(account, CounterHolder{count:9})
        } else{
            let countHolder = borrow_global_mut<CounterHolder>(addr);
            countHolder.count = countHolder.count+1;
        }
    }

    public fun get_count(addr: address): u8 acquires CounterHolder{
        assert!(exists<CounterHolder>(addr), 0);
        borrow_global<CounterHolder>(addr).count
    }
}