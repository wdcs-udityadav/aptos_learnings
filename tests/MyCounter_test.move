#[test_only]
module MyAccount::Counter_test{
    use std::debug::print;
    use std::signer;
    use std::unit_test;
    use std::vector;
    use MyAccount::Counter;

    fun get_signer(): signer{
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))  
    }

    #[test]
    fun test_bump() {
        let account = get_signer();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        Counter::bump(&account);
        let x = Counter::get_count(addr);
        print(&x);
        assert!(x == 9, 0);

        Counter::bump(&account);
        let y = Counter::get_count(addr);
        print(&y);
        assert!(y == 10, 0);
    }
}