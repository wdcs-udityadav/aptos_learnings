#[test_only]
module MyAccount::Message_test{
    use std::signer;
    use std::unit_test;
    use std::vector;

    use MyAccount::Message;

    fun get_signer():signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    #[test]
    fun test(){
        let account = get_signer();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
    }
}