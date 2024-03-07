module MyAccount::NFT{
    use std::account;
    use std::bcs;
    use std::resource_account;
    use std::signer;
    use std::string::{utf8,String};
    use aptos_token::token;

    const E_MINTING_DISABLED:u64 = 0;
    const E_NOT_ADMIN:u64 = 1;

    struct DataModule has key{
        token_data_id: token::TokenDataId,
        signer_cap: account::SignerCapability,
        minting_enabled: bool
    }

    fun init_module(resource_signer: &signer){
        token::create_collection(
            resource_signer,
            utf8(b"Test Collection"),
            utf8(b"Test description"),
            utf8(b"Test uri"),
            1,
            vector<bool>[false,false,false]
        );
    
        let token_data_id = token::create_tokendata(
            resource_signer,
            utf8(b"Test Collection"),
            utf8(b"Test token"),
            utf8(b"Test desctiption"),
            1,
            utf8(b"test uri"),
            signer::address_of(resource_signer),
            10,
            1,
            token::create_token_mutability_config(&vector<bool>[false, false, false, false, true]),
            vector<String>[utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[utf8(b"address")]
        );

        let signer_cap =  resource_account::retrieve_resource_account_cap(resource_signer, @Admin);
        move_to<DataModule>(resource_signer, DataModule{
            token_data_id,
            signer_cap,
            minting_enabled: false
        });
    }

    public entry fun mint_nft(receiver: &signer) acquires DataModule{
        let data_module= borrow_global<DataModule>(@MyAccount);
        assert!(data_module.minting_enabled, 0);
        let resource_signer = account::create_signer_with_capability(&data_module.signer_cap);

        let token_id = token::mint_token(&resource_signer, data_module.token_data_id, 1);
        token::direct_transfer(&resource_signer, receiver,token_id, 1);

        let (creator_address, collection, name) = token::get_token_data_id_fields(&data_module.token_data_id);
        token::mutate_token_properties(
            &resource_signer,
            signer::address_of(receiver),
            creator_address,
            collection,
            name,
            0,
            1,
            vector<String>[utf8(b"given_to")],
            vector<vector<u8>>[bcs::to_bytes(&signer::address_of(receiver))],
            vector<String>[utf8(b"address")]
        );
    }

    public entry fun toggle_minting(account: &signer) acquires DataModule{
        assert!(signer::address_of(account) == @Admin, 1);
        let data_module = borrow_global_mut<DataModule>(@MyAccount);
        if(data_module.minting_enabled){
            data_module.minting_enabled = false;
        }else{
            data_module.minting_enabled = true;
        }
    }
}