#[test_only]
module MyAccount::Message_test{
    use std::debug::print;
    use std::string::{String,utf8};
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
        Message::create_message(&account,utf8(b"hello world"));
        let mssg1= Message::get_message(&account);
        print(&mssg1);
        assert!(mssg1 == utf8(b"hello world"),0);
        Message::create_message(&account, utf8(b"hello"));
        let mssg2= Message::get_message(&account);
        print(&mssg2);
        assert!(mssg2 == utf8(b"hello"),0);
    }
}