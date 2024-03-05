module StoredAt::ObjectExample{
    use std::account;
    use std::debug::print;
    use std::object;
    use std::signer;
    use std::string::{String,utf8};

    const E_NOT_OWNER:u64 = 0;

    struct Counter has key{
        counter_val: u64
    }
    
    struct Message has key {
        message: String
    }

    struct ObjectController has key{
        extended_ref: object::ExtendRef,
        transfer_ref: object::TransferRef,
        delete_ref: object::DeleteRef
    }

    public fun create_object(account: &signer, num:u64, transferrable:bool): object::ConstructorRef{
        let constructor_ref = object::create_object(signer::address_of(account));
        let object_signer = object::generate_signer(&constructor_ref);
        move_to<Counter>(&object_signer, Counter{
            counter_val: num
        });

        let extended_ref = object::generate_extend_ref(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let delete_ref = object::generate_delete_ref(&constructor_ref);
        if(!transferrable){
            object::disable_ungated_transfer(&transfer_ref); 
        };

        move_to<ObjectController>(&object_signer, ObjectController{
            extended_ref,
            transfer_ref,
            delete_ref
        });
        constructor_ref
    }

    public fun add_message(account: &signer, message: String, object: object::Object<ObjectController>) acquires ObjectController{
        assert!(object::is_owner(object, signer::address_of(account)), E_NOT_OWNER);

        let obj_addr = object::object_address(&object);
        let obj_controller = borrow_global<ObjectController>(obj_addr);
        let extended_obj_signer = object::generate_signer_for_extending(&obj_controller.extended_ref);
        move_to<Message>(&extended_obj_signer, Message{message});
    }

    public fun transfer_ownership(account: &signer, to: address, object: object::Object<ObjectController>){
        assert!(object::is_owner(object, signer::address_of(account)), E_NOT_OWNER);
        
        object::transfer(account,object,to);
    }

    public fun transfer_using_owner(to: address, object: object::Object<ObjectController>)acquires ObjectController {
        let obj_addr = object::object_address(&object);
        let obj_controller = borrow_global<ObjectController>(obj_addr);

        let linear_transfer_ref = object::generate_linear_transfer_ref(&obj_controller.transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, to);
    }

    public fun toggle_transfer(account: &signer, object: object::Object<ObjectController>) acquires ObjectController {
        assert!(object::is_owner(object, signer::address_of(account)), E_NOT_OWNER);

        let obj_addr = object::object_address(&object);
        let obj_controller = borrow_global<ObjectController>(obj_addr);
        if(object::ungated_transfer_allowed(object)){
            object::disable_ungated_transfer(&obj_controller.transfer_ref);
        }else{
            object::enable_ungated_transfer(&obj_controller.transfer_ref);
        }
    }

    public fun delete_object(account: &signer, object: object::Object<ObjectController>)acquires ObjectController {
        assert!(object::is_owner(object, signer::address_of(account)), E_NOT_OWNER);
        
        let obj_addr = object::object_address(&object);
        let ObjectController{extended_ref:_, transfer_ref:_, delete_ref} = move_from<ObjectController>(obj_addr);

        object::delete(delete_ref);
    }

    #[test(account=@StoredAt)]
    fun test_object(account:signer)acquires ObjectController{
        let user1 = account::create_account_for_test(@0x45);
        let user2 = account::create_account_for_test(@0x46);
        let user1_addr = signer::address_of(&user1);
        let user2_addr = signer::address_of(&user2);

        let constructor_ref = create_object(&account, 8, true);

        let obj = object::object_from_constructor_ref<ObjectController>(&constructor_ref);
        add_message(&account,utf8(b"hello world"), obj);
        
        let obj_addr = object::address_from_constructor_ref(&constructor_ref);
        assert!(object::is_object(obj_addr), 0);
        assert!(object::object_exists<Counter>(obj_addr), 0);
        assert!(object::object_exists<ObjectController>(obj_addr), 0);
        assert!(object::object_exists<Message>(obj_addr), 0);

        toggle_transfer(&account, obj); 
        toggle_transfer(&account, obj); 

        transfer_ownership(&account,user1_addr, obj);
        assert!(object::owner(obj) == user1_addr, 1);

        transfer_using_owner(user2_addr, obj);
        assert!(object::owner(obj) == user2_addr, 1);

        delete_object(&user2, obj);
        assert!(!object::is_object(obj_addr), 1);
    }
}