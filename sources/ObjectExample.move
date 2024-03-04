module MyAccount::ObjectExample{
    use std::object;
    use std::signer;
    use std::string::String;
    use std::vector;

    struct StudentList has key{
        student_list: vector<String>
    }

    publi fun create_object(account: &signer, list: vector<String>){
        let constructor_ref = object::create_object_from_account(account);
        let generated_signer = generate_signer(&constructor_ref);
        move_to<StudentList>(&generate_signer, StudentList{
            student_list:list
        });
    }

    #[test(account=@MyAccount)]
    fun test_object(account:signer){
        let list = vector::empty(String);

        list.push_back(&mut list,"John");
        list.push_back(&mut list,"Harry");
        list.push_back(&mut list, "Sam");

        create_object(&account, list)
    }
}