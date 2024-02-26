module MyAccount::Voting{
    use std::signer;
    use std::simple_map::{SimpleMap, Self};
    use std::vector;


    const E_NOT_OWNER:u64 = 0;
    const E_INITIALIZED:u64 = 1;
    const E_UNINITIALIZED:u64 = 2;
    const E_CANDIDATE_ALREADY_EXISTS:u64 = 3;
    const E_CANDIDATE_DOESNT_EXISTS:u64 = 4;
    const E_ALREADY_VOTED:u64 = 5;

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

     fun candidate_exists(addr:address, candidate:address) acquires CandidateList{
        let cdt_list = borrow_global<CandidateList>(addr);
        let exists = simple_map::contains_key(&cdt_list.candidate_map ,&candidate); 
        assert!(exists,E_CANDIDATE_DOESNT_EXISTS);
    }

    fun candidate_doesnt_exist(addr:address, candidate:address) acquires CandidateList{
        let cdt_list = borrow_global<CandidateList>(addr);
        let exists = simple_map::contains_key(&cdt_list.candidate_map ,&candidate); 
        assert!(exists == false,E_CANDIDATE_ALREADY_EXISTS);
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
        candidate_doesnt_exist(addr,candidate);

        let cdt_list=borrow_global_mut<CandidateList>(addr);
        assert!(cdt_list.winner==@0x0, 0);

        simple_map::add(&mut cdt_list.candidate_map,candidate,0);
        vector::push_back(&mut cdt_list.c_vector, candidate);
    }

    public fun vote(addr:address, account:&signer, candidate: address)acquires CandidateList,VotersList{
        is_initialized(addr);
        candidate_exists(addr, candidate);

        let cdt_list =borrow_global_mut<CandidateList>(addr);
        assert!(cdt_list.winner ==@0x0, 0);
        
        let vtr_addr = signer::address_of(account);
        let vtr_list = borrow_global_mut<VotersList>(vtr_addr);
        assert!(!simple_map::contains_key(&vtr_list.voters, &vtr_addr), E_ALREADY_VOTED);

        let votes = simple_map::borrow_mut(&mut cdt_list.candidate_map, &candidate);
        *votes = *votes+1;

        simple_map::add(&mut vtr_list.voters, vtr_addr, 1);
    }

    public fun declare_winner(account: &signer):address acquires CandidateList {
        let addr = signer::address_of(account);
        is_owner(addr);
        is_initialized(addr);
        
        let cdt_list = borrow_global<CandidateList>(addr);
        assert!(cdt_list.winner== @0x0, 0);

        let c_length = vector::length(&cdt_list.c_vector); 

        let winner = @0x0;
        let highest_votes=0;
        let i=0;
        while(i <= c_length){
            let cdt_addr = vector::borrow(&cdt_list.c_vector,i);
            let votes = simple_map::borrow(&cdt_list.candidate_map, cdt_addr);
            if(*votes>highest_votes){
                highest_votes = *votes;
                winner = *cdt_addr;
            };

            i=i+1;
        };
        winner
    }
}