module MyAccount::Message{
    use std::string::{String,utf8};

    struct MessageStore has key{
        message: String
    }

    fun create_message(account:&signer, message:String){
        let addr = signer::address_of(account);
        if(!exists<MessageStore>(addr)){
            move_to<MessageStore>(account, MessageStore{message})
        } else{
            let mssg = borrow_global_mut<MessageStore>(addr);
            mssg.message = message;
        }
    }

    fun get_message(account: &signer): String{
        borrow_global<MessageStore>(signer::address_of(account)).message
    }
}