module MyAccount::Message{
    use std::string::{String,utf8};
    use std::signer;

    struct MessageStore has key{
        message: String
    }

    public fun create_message(account:&signer, message:String) acquires MessageStore{
        let addr = signer::address_of(account);
        if(!exists<MessageStore>(addr)){
            move_to<MessageStore>(account, MessageStore{message})
        } else{
            let mssg = borrow_global_mut<MessageStore>(addr);
            mssg.message = message;
        }
    }

    public fun get_message(account: &signer): String acquires MessageStore{
        borrow_global<MessageStore>(signer::address_of(account)).message
    }
}