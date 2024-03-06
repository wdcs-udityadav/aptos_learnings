module MyAccount::NFT{
    use std::signer;
    use std::string::{utf8,String};
    use aptos_token::token;

    struct DataModule has key{
        token_data_id: token::TokenDataId
    }

    fun init_module(creator: &signer){
        token::create_collection(
            creator,
            utf8(b"Test Collection"),
            utf8(b"Test description"),
            utf8(b"Test uri"),
            1,
            vector<bool>[false,false,false]
        );
    
        let token_data_id = token::create_tokendata(
            creator,
            utf8(b"Test Collection"),
            utf8(b"Test token"),
            utf8(b"Test desctiption"),
            1,
            utf8(b"test uri"),
            signer::address_of(creator),
            10,
            1,
            token::create_token_mutability_config(&vector<bool>[false, false, false, false, false]),
            vector<String>[utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[utf8(b"address")]
        );

        move_to<DataModule>(creator, DataModule{
            token_data_id
        });
    }

    public fun mint_nft(creator: &signer, receiver: &signer) acquires DataModule{
        let data_module= borrow_global<DataModule>(signer::address_of(creator));
        let token_id = token::mint_token(creator, data_module.token_data_id, 1);
        token::direct_transfer(creator, receiver,token_id, 1);

        let (creator, collection, name) = token::get_token_data_id_fields(&data_module.token_data_id);
        token::mutate_token_properties(
            creator,
            signer::address_of(receiver),
            signer::address_of(creator),
            collection,
            name,
            0,
            1,
            vector<String>[b"given_to"]
            vector<vector<u8>[signer::address_of(receiver)],
            vector<String>[b"address"]

        );
    }
}