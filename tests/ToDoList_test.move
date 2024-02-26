#[test_only]
module MyAccount::ToDoList_test{
    use std::debug::print;
    use std::string::utf8;
    use std::signer;
    use std::event;
    use std::vector;
    use std::unit_test;
    // use std::table;

    use MyAccount::ToDoList;

    fun get_signer():signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    #[test]
    fun test_toDoList(){
        //create list
        let account = get_signer();
        let addr = signer::address_of(&account);
        ToDoList::create_list(&account);
        assert!(ToDoList::if_exists(addr), 0);
        assert!(ToDoList::get_task_counter(addr)==0, 0);

        //create task
        let task_content = utf8(b"Task One");
        ToDoList::create_task(&account, task_content);
        assert!(ToDoList::get_task_counter(addr)==1, 0);
        let (task_id, content, signer_address, is_completed) = ToDoList::get_task(addr, ToDoList::get_task_counter(addr));
        assert!(task_id==1,0);
        assert!(content==task_content,0);
        assert!(signer_address==addr,0);
        assert!(is_completed==false,0);

        //event
        let events = event::emitted_events<ToDoList::Task_Created>();
        let emitted_event = vector::pop_back(&mut events);
        print(&emitted_event);

        //update task as completed
        ToDoList::complete_task(&account, task_id);
        let (_, _, _, is_completed) = ToDoList::get_task(addr, task_id);
        assert!(is_completed==true,0);
    }
}