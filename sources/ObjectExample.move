module StoredAt::ObjectExample{
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

    struct ObjController has key{
        extended_ref: object::ExtendRef,
        transfer_ref: object::TransferRef
    }

    public fun create_object(account: &signer, num:u64, transferrable:bool): object::ConstructorRef{
        let constructor_ref = object::create_object(signer::address_of(account));
        let object_signer = object::generate_signer(&constructor_ref);
        move_to<Counter>(&object_signer, Counter{
            counter_val: num
        });

        let extended_ref = object::generate_extend_ref(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        if(!transferrable){
            object::disable_ungated_transfer(&transfer_ref); 
        };

        move_to<ObjController>(&object_signer, ObjController{
            extended_ref,
            transfer_ref
        });
        constructor_ref
    }

    public fun add_message(account: &signer, message: String, object: object::Object<ObjController>) acquires ObjController{
        assert!(object::is_owner(object, signer::address_of(account)), E_NOT_OWNER);

        let obj_addr = object::object_address(&object);
        let obj_controller = borrow_global<ObjController>(obj_addr);
        let extended_obj_signer = object::generate_signer_for_extending(&obj_controller.extended_ref);
        move_to<Message>(&extended_obj_signer, Message{message});
    }

    public fun transfer_ownership(account: &signer, to: address, object: object::Object<Message>){
        assert!(object::is_owner(object, signer::address_of(account)), E_NOT_OWNER);
        
        object::transfer(account,object,to);
    }

    public fun toggle_transfer(account: &signer, object: object::Object<ObjController>) acquires ObjController {
        assert!(object::is_owner(object, signer::address_of(account)), E_NOT_OWNER);

        let obj_addr = object::object_address(&object);
        let obj_controller = borrow_global<ObjController>(obj_addr);
        if(object::ungated_transfer_allowed(object)){
            object::disable_ungated_transfer(&obj_controller.transfer_ref);
        }else{
            object::enable_ungated_transfer(&obj_controller.transfer_ref);
        }
    }

    #[test(account=@StoredAt, to=@0x456)]
    fun test_object(account:signer, to: address)acquires ObjController{
        let constructor_ref = create_object(&account, 8, true);

        let obj = object::object_from_constructor_ref<ObjController>(&constructor_ref);
        add_message(&account,utf8(b"hello world"), obj);
        
        let obj_addr = object::address_from_constructor_ref(&constructor_ref);
        assert!(object::is_object(obj_addr), 0);
        assert!(object::object_exists<Counter>(obj_addr), 0);
        assert!(object::object_exists<ObjController>(obj_addr), 0);
        assert!(object::object_exists<Message>(obj_addr), 0);

        toggle_transfer(&account, obj); 
        toggle_transfer(&account, obj); 

        let obj_mssg = object::object_from_constructor_ref<Message>(&constructor_ref);
        transfer_ownership(&account, to, obj_mssg);
        assert!(object::owner(obj_mssg) == to, 1);
    }
}