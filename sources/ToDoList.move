module MyAccount::ToDoList{
    use std::string::String;
    use std::debug::print;
    use std::signer;
    use std::event;
    use std::table::{Self,Table};

    //errors
    const E_LIST_DOESNT_EXIST:u64 = 0;
    const E_TASK_DOESNT_EXIST:u64 = 1;
    const E_TASK_ALREADY_COMPLETED:u64 = 2;

    struct List has key{
        tasks: Table<u8, Task>,
        task_counter: u8
    }

    struct Task has store, drop, copy{
        task_id: u8,
        content: String,
        signer_address: address,
        is_completed: bool
    }

    #[event]
    struct Task_Created has drop, store{
        created_task: Task
    }

    public entry fun create_list(account: &signer){
        let new_list = List{
            tasks: table::new(),
            task_counter: 0
        };
        move_to<List>(account, new_list)
    }

    public entry fun create_task(account: &signer,content: String) acquires List {
        let addr = signer::address_of(account);
        assert!(exists<List>(addr), E_LIST_DOESNT_EXIST);

        let list = borrow_global_mut<List>(addr);
        let counter = list.task_counter + 1;
        let new_task = Task{
            task_id: counter,
            content,
            signer_address: addr,
            is_completed : false
        };
        table::upsert(&mut list.tasks, counter, new_task);
        list.task_counter = counter;

        event::emit(Task_Created {
            created_task: new_task
        });
    }

    public entry fun complete_task(account: &signer, task_id: u8) acquires List {
        let addr = signer::address_of(account);
        assert!(exists<List>(addr), E_LIST_DOESNT_EXIST);
        let list = borrow_global_mut<List>(addr);

        assert!(table::contains(&list.tasks, task_id), E_TASK_DOESNT_EXIST);
        let task = table::borrow_mut(&mut list.tasks, task_id);
        assert!(task.is_completed == false, E_TASK_ALREADY_COMPLETED);
        task.is_completed = true;
    }

    #[view]
    public fun if_exists(addr: address):bool {
        exists<List>(addr)
    }
    
    public fun get_task_counter(addr: address):u8 acquires List {
        borrow_global<List>(addr).task_counter
    }

    public fun get_task(addr:address, task_id: u8): (u8,String,address,bool) acquires List{
        let list = borrow_global<List>(addr);
        let task = table::borrow(&list.tasks, task_id);
        return (task.task_id,task.content,task.signer_address,task.is_completed)
    }
}