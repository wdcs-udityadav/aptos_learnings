module MyAccount::BasicToken{
    use std::account;
    use std::debug::print;
    use std::signer;

    //errors
    const E_BALANCE_ALREADY_EXISTS:u64 = 0;
    const E_BALANCE_DOESNT_EXIST:u64 = 1;
    const E_INSUFFICIENT_BALANCE:u64 = 2;
    const E_SAME_ADDRESSES:u64 = 3;

    struct Balance has key{
        coin_balance: Coins
    }

    struct Coins has store{
        amount: u8
    }

    public fun mint(coin_amount:u8): Coins {
        Coins{
            amount: coin_amount
        }
    }

    public fun burn(coins:Coins){
        let Coins{amount:_} = coins;
    }

    public fun if_balance_exists(addr:address):bool {
        exists<Balance>(addr)
    }

    public fun get_balance(addr:address):u8 acquires Balance{
        borrow_global<Balance>(addr).coin_balance.amount
    }

    public fun create_balance(account: &signer) {
        assert!(!if_balance_exists(signer::address_of(account)), E_BALANCE_ALREADY_EXISTS);

        move_to<Balance>(account, Balance{
            coin_balance: Coins{
                amount: 0
            }
        });
    }

    public fun deposit(to: address, coins:Coins) acquires Balance {
        assert!(if_balance_exists(to), E_BALANCE_DOESNT_EXIST);

        let Coins{amount} = coins;
        let balance = borrow_global_mut<Balance>(to);
        balance.coin_balance.amount = balance.coin_balance.amount + amount;
    }

    public fun withdraw(account:&signer, amount:u8):Coins acquires Balance {
        let addr = signer::address_of(account);
        assert!(if_balance_exists(addr), E_BALANCE_DOESNT_EXIST);
        assert!(get_balance(addr)>= amount, E_INSUFFICIENT_BALANCE);

        let balance = borrow_global_mut<Balance>(addr);
        balance.coin_balance.amount = balance.coin_balance.amount - amount;
        Coins{amount}
    }

    public fun transfer(account:&signer, to:address, amount:u8) acquires Balance {
        let addr = signer::address_of(account);
        assert!(if_balance_exists(addr), E_BALANCE_DOESNT_EXIST);
        assert!(if_balance_exists(to), E_BALANCE_DOESNT_EXIST);
        assert!(addr!=to, E_SAME_ADDRESSES);
        assert!(get_balance(addr)>= amount, E_INSUFFICIENT_BALANCE);

        let withdrawn_coins = withdraw(account, amount);
        deposit(to, withdrawn_coins);
    }

    #[test(account=@MyAccount)]
    fun test_flow(account:signer)acquires Balance{
        let account_addr = signer::address_of(&account);
        
        //mint
        let minted_coins = mint(5);

        //create balance
        create_balance(&account);
        assert!(get_balance(account_addr)==0,8);
        
        //deposit
        deposit(account_addr, minted_coins);
        assert!(get_balance(account_addr)==5,8);

        //withdraw
        let withdrawn_coins = withdraw(&account, 3);
        assert!(get_balance(account_addr)==2,8);

        //transfer
        let to_addr = @0x9;
        let to = account::create_account_for_test(to_addr);
        create_balance(&to);
    
        transfer(&account,to_addr,2);
        assert!(get_balance(account_addr)==0,8);
        assert!(get_balance(to_addr)==2,8);

        burn(withdrawn_coins);
    }
}