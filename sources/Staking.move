module MyAccount::Staking{
    use std::signer;

    use MyAccount::BasicToken;

    const E_INSUFFICIENT_BALANCE:u64 = 0;
    const E_ALREADY_STAKED:u64 = 1;
    const E_INSUFFICIENT_STAKE:u64 = 2;

    const APY:u64 = 1000;

    struct StakedBalance has key{
        amount: u64
    }

    public fun get_staked_balance(addr:address):u64 acquires StakedBalance{
        borrow_global<StakedBalance>(addr).amount
    }

    public fun stake(account: &signer, amount:u64){
        let addr = signer::address_of(account);
        assert!(BasicToken::get_balance(addr) >= amount, E_INSUFFICIENT_BALANCE);
        assert!(!exists<StakedBalance>(addr), E_ALREADY_STAKED);

        let withdrawn_coins = BasicToken::withdraw(account, amount);
        BasicToken::burn(withdrawn_coins);
        move_to<StakedBalance>(account, StakedBalance{
            amount
        });
    }

    public fun unstake(account:&signer, amount:u64) acquires StakedBalance{
        let addr = signer::address_of(account);

        let staked = borrow_global_mut<StakedBalance>(addr);
        assert!(staked.amount >= amount, E_INSUFFICIENT_STAKE);
        staked.amount = staked.amount - amount;

        let minted_coins = BasicToken::mint(amount);
        BasicToken::deposit(addr, minted_coins);
    }

    public fun claim_rewards(addr:address) acquires StakedBalance{
        let staked_balance = get_staked_balance(addr);
        assert!(staked_balance >0 , E_INSUFFICIENT_STAKE);

        let reward = (staked_balance * APY) / 10000;
        let reward_coins = BasicToken::mint(reward);
        BasicToken::deposit(addr, reward_coins)
    }

    #[test(account=@MyAccount)]
    fun test_flow(account: signer) acquires StakedBalance{
        let addr = signer::address_of(&account);

        //create balance, mint, deposit
        let minted_coins = BasicToken::mint(110);
        BasicToken::create_balance(&account);
        BasicToken::deposit(addr,minted_coins);
        assert!(BasicToken::get_balance(addr)==110, 9);

        //stake
        stake(&account, 105);
        assert!(get_staked_balance(addr) == 105, 9);
    
        //unstake
        unstake(&account, 5);
        assert!(get_staked_balance(addr)==100,9);
        assert!(BasicToken::get_balance(addr)==10,9);

        //claim rewards
        claim_rewards(addr);
        assert!(BasicToken::get_balance(addr)==20,9);
    }
}