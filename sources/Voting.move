module MyAccount::Voting{
    use std::account;
    use std::debug::print;
    use std::signer;
    use std::simple_map::{SimpleMap, Self};
    use std::vector;

    const E_NOT_OWNER:u64 = 0;
    const E_INITIALIZED:u64 = 1;
    const E_UNINITIALIZED:u64 = 2;
    const E_CANDIDATE_ALREADY_EXISTS:u64 = 3;
    const E_CANDIDATE_DOESNT_EXIST:u64 = 4;
    const E_ALREADY_VOTED:u64 = 5;
    const E_NOT_VOTED:u64 = 6;
    const E_WINNER_ALREDY_DECLARED:u64 = 7;

    struct CandidateList has key{
        candidate_map: SimpleMap<address, u8>,
        c_vector: vector<address>,
        winner: address
    }

    struct VotersList has key{
        voters: SimpleMap<address, u8>
    }

    fun is_owner(addr:address) {
        assert!(addr == @MyAccount, E_NOT_OWNER);
    }

    fun is_initialized(addr:address) {
        assert!(exists<CandidateList>(addr), E_UNINITIALIZED);
        assert!(exists<VotersList>(addr), E_UNINITIALIZED);
    }

    fun is_uninitialized(addr:address) {
        assert!(!exists<CandidateList>(addr), E_INITIALIZED);
        assert!(!exists<VotersList>(addr), E_INITIALIZED);
    }

    fun candidate_exists(c_map:&SimpleMap<address,u8>, candidate:&address){
        assert!(simple_map::contains_key(c_map,candidate), E_CANDIDATE_DOESNT_EXIST);
    }

    fun candidate_doesnt_exist(c_map:&SimpleMap<address,u8>, candidate:&address){
        assert!(!simple_map::contains_key(c_map,candidate), E_CANDIDATE_ALREADY_EXISTS);
    }

    fun has_voted(voters:&SimpleMap<address, u8>, vtr_addr:&address) {
        assert!(simple_map::contains_key(voters, vtr_addr), E_NOT_VOTED);
    }

    fun has_not_voted(voters:&SimpleMap<address, u8>, vtr_addr:&address) {
        assert!(!simple_map::contains_key(voters, vtr_addr), E_ALREADY_VOTED);
    }

    public fun initialize_with_candidate(account: &signer, candidate: address) acquires CandidateList{
        let addr = signer::address_of(account);
        is_owner(addr);
        is_uninitialized(addr);

        let c_list =  CandidateList{
            candidate_map: simple_map::new<address, u8>(),
            c_vector: vector::empty<address>(),
            winner: @0x0
        };
        move_to<CandidateList>(account,c_list);

        let v_list = VotersList{
            voters: simple_map::new<address,u8>()
        };
        move_to<VotersList>(account, v_list);

        let cdt_list = borrow_global_mut<CandidateList>(addr);
        simple_map::add(&mut cdt_list.candidate_map,candidate,0);
        vector::push_back(&mut cdt_list.c_vector, candidate);
    }
    
    public fun add_candidate(account: &signer, candidate: address) acquires CandidateList {
        let addr = signer::address_of(account);
        is_owner(addr);
        is_initialized(addr);
        candidate_doesnt_exist(&borrow_global<CandidateList>(addr).candidate_map, &candidate);

        let cdt_list=borrow_global_mut<CandidateList>(addr);
        assert!(cdt_list.winner==@0x0, E_WINNER_ALREDY_DECLARED);

        simple_map::add(&mut cdt_list.candidate_map,candidate,0);
        vector::push_back(&mut cdt_list.c_vector, candidate);
    }

    public fun vote(addr:address, account:&signer, candidate: address)acquires CandidateList,VotersList{
        is_initialized(addr);
        
        candidate_exists(&borrow_global<CandidateList>(addr).candidate_map, &candidate);

        let cdt_list =borrow_global_mut<CandidateList>(addr);
        assert!(cdt_list.winner ==@0x0, E_WINNER_ALREDY_DECLARED);
        
        let vtr_addr = signer::address_of(account);
        let vtr_list = borrow_global_mut<VotersList>(addr);
        has_not_voted(&vtr_list.voters,&vtr_addr);

        let votes = simple_map::borrow_mut(&mut cdt_list.candidate_map, &candidate);
        *votes = *votes+1;

        simple_map::add(&mut vtr_list.voters, vtr_addr, 1);
    }

    public fun declare_winner(account: &signer) acquires CandidateList {
        let addr = signer::address_of(account);
        is_owner(addr);
        is_initialized(addr);
        
        let cdt_list = borrow_global_mut<CandidateList>(addr);
        assert!(cdt_list.winner == @0x0, E_WINNER_ALREDY_DECLARED);

        let c_length = vector::length(&cdt_list.c_vector); 

        let winner = @0x0;
        let highest_votes=0;
        let i=0;
        while(i < c_length){
            let cdt_addr = vector::borrow(&cdt_list.c_vector, i);
            let votes = simple_map::borrow(&cdt_list.candidate_map, cdt_addr);
            if(*votes>highest_votes){
                highest_votes = *votes;
                winner = *cdt_addr;
            };
            i=i+1;
        };
        cdt_list.winner = winner;
    }

    #[test(owner=@MyAccount)]
    fun test_flow(owner:signer) acquires CandidateList,VotersList {
        let owner_addr = signer::address_of(&owner);
        
        //candidates
        let cdt1 = @0x1;
        let cdt2 = @0x2;

        //voters
        let vtr1 = account::create_account_for_test(@0x4);
        let vtr2 = account::create_account_for_test(@0x5);
        let vtr3 = account::create_account_for_test(@0x6);
        
        //initialization
        initialize_with_candidate(&owner, cdt1);
        is_initialized(owner_addr);

        //adding candidate
        add_candidate(&owner, cdt2);
        let candidates = &borrow_global<CandidateList>(owner_addr).candidate_map;
        candidate_exists(candidates,&cdt1);
        candidate_exists(candidates,&cdt2);
        
        //voting
        vote(owner_addr, &vtr1, cdt1);
        vote(owner_addr, &vtr2, cdt2);
        vote(owner_addr, &vtr3, cdt2);
        
        let voters = &borrow_global<VotersList>(owner_addr).voters;
        has_voted(voters, &signer::address_of(&vtr1));
        has_voted(voters, &signer::address_of(&vtr2));
        has_voted(voters, &signer::address_of(&vtr3));

        //declare winner
        declare_winner(&owner);
        assert!(borrow_global<CandidateList>(owner_addr).winner == cdt2, 11);
    }

    #[test]
    #[expected_failure(abort_code = E_NOT_OWNER)]
    fun test_initialize_with_candidate_not_owner() acquires CandidateList{
        let candidate = @0x7;
        let not_owner = account::create_account_for_test(@0x8);
        initialize_with_candidate(&not_owner,candidate);
    }

    #[test(owner=@MyAccount)]
    #[expected_failure(abort_code = E_INITIALIZED)]
    fun test_reinitialize(owner: signer)acquires CandidateList{
        let cdt1 = @0x7;
        let cdt2 = @0x8;

        initialize_with_candidate(&owner,cdt1);
        initialize_with_candidate(&owner,cdt2);
    }

    #[test(owner=@MyAccount)]
    #[expected_failure(abort_code = E_CANDIDATE_ALREADY_EXISTS)]
    fun test_add_candidate_already_exists(owner: signer)acquires CandidateList{
        let cdt1 = @0x7;

        initialize_with_candidate(&owner,cdt1);
        add_candidate(&owner,cdt1);
    }

    #[test(owner=@MyAccount)]
    #[expected_failure(abort_code = E_ALREADY_VOTED)]
    fun test_already_voted(owner: signer)acquires CandidateList,VotersList{
        let cdt1 = @0x7;
        let cdt2 = @0x8;
        initialize_with_candidate(&owner,cdt1);
        add_candidate(&owner, cdt2);

        let voter = account::create_account_for_test(@0x5);
        vote(signer::address_of(&owner), &voter, cdt1);
        vote(signer::address_of(&owner), &voter, cdt2);
    }

    #[test(owner=@MyAccount)]
    #[expected_failure(abort_code = E_WINNER_ALREDY_DECLARED)]
    fun test_add_candidate_after_winner_declared(owner:signer) acquires CandidateList, VotersList{
        let cdt1 = @0x7;
        initialize_with_candidate(&owner,cdt1);

        let voter = account::create_account_for_test(@0x5);
        vote(signer::address_of(&owner), &voter, cdt1);
        declare_winner(&owner);

        add_candidate(&owner, @0x8);
    }

    #[test(owner=@MyAccount)]
    #[expected_failure(abort_code = E_WINNER_ALREDY_DECLARED)]
    fun test_vote_after_winner_declared(owner:signer) acquires CandidateList, VotersList{
        let cdt1 = @0x7;
        let cdt2 = @0x8;
        initialize_with_candidate(&owner,cdt1);
        add_candidate(&owner, cdt2);

        let voter = account::create_account_for_test(@0x5);
        vote(signer::address_of(&owner), &voter, cdt1);
        declare_winner(&owner);

        vote(signer::address_of(&owner), &voter, cdt2);
    }

    #[test(owner=@MyAccount)]
    #[expected_failure(abort_code = E_WINNER_ALREDY_DECLARED)]
    fun test_redeclare_winner(owner:signer) acquires CandidateList, VotersList{
        let cdt1 = @0x7;
        initialize_with_candidate(&owner,cdt1);

        let voter = account::create_account_for_test(@0x5);
        vote(signer::address_of(&owner), &voter, cdt1);
        declare_winner(&owner);
        declare_winner(&owner);
    }
}