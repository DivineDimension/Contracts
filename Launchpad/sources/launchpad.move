module mint_nft3::mint_nft3 {
    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::coin;

    use aptos_token::token;
    use aptos_token::token::TokenDataId;
    use aptos_framework::timestamp;

    // This struct stores an NFT collection's relevant information
    struct ModuleData has key {
        token_data_id: TokenDataId,
    }

    /// Action not authorized because the signer is not the admin of this module
    const ENOT_AUTHORIZED: u64 = 1;
    const EEXPIRED: u64 = 0x0005;

    struct Cal has store,drop,key{
        count:u64,
        start_time:u64,
        end_time:u64
    }
    struct Mydeposits has store,drop,key{
        total_aptos:u64,
        total_nft:u64
    }

  

    

    fun init_module(resource_signer: &signer) {
        move_to<Cal>(resource_signer,Cal{
            count:0,
            start_time:1681368652,
            end_time:1686398664
        })
    
    }

   

    /// `init_module` is automatically called when publishing the module.
    /// In this function, we create an example NFT collection and an example token.
    public entry fun participate<C>(source_account: &signer,owner_addr: address, collection_name: String,description: String,collection_uri: String, token_uri: String,percentageaddress:address,price:u64) acquires Cal,Mydeposits {
        // let collection_name = string::utf8(b"first");
        // let description = string::utf8(b"first");
        // let collection_uri = string::utf8(b"first uri");
        let value = borrow_global_mut<Cal>(owner_addr);
        assert!(value.start_time <= timestamp::now_seconds(), error::invalid_state(EEXPIRED));
        assert!(value.end_time >= timestamp::now_seconds(), error::invalid_state(EEXPIRED));
        value.count = value.count + 1;

        let token_name = collection_name;
        // let token_uri = string::utf8(b"https://gateway.pinata.cloud/ipfs/QmavWFW3srs6b5KujeK9ctufSDz4FKKtcZk3PmN75NF5DA");
        // This means that the supply of the token will not be tracked.
        let maximum_supply = 0;
        // This variable sets if we want to allow mutation for collection description, uri, and maximum.
        // Here, we are setting all of them to false, which means that we don't allow mutations to any CollectionData fields.
        let mutate_setting = vector<bool>[ false, false, false ];

        // Create the nft collection.
        token::create_collection(source_account, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // Create a token data id to specify the token to be minted.
        let token_data_id = token::create_tokendata(
            source_account,
            collection_name,
            token_name,
            string::utf8(b""),
            0,
            token_uri,
            signer::address_of(source_account),
            1,
            0,
            // This variable sets if we want to allow mutation for token maximum, uri, royalty, description, and properties.
            // Here we enable mutation for properties by setting the last boolean in the vector to true.
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            // We can use property maps to record attributes related to the token.
            // In this example, we are using it to record the receiver's address.
            // We will mutate this field to record the user's address
            // when a user successfully mints a token in the `mint_nft()` function.
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[ string::utf8(b"address") ],
        );

        // Store the token data id within the module, so we can refer to it later
        // when we're minting the NFT and updating its property version.
        // move_to(source_account, ModuleData {
        //     token_data_id,
        // });

        let token_id = token::mint_token(source_account, token_data_id, 1);
        let (creator_address, collection, name) = token::get_token_data_id_fields(&token_data_id);
        token::mutate_token_properties(
            source_account,
            signer::address_of(source_account),
            creator_address,
            collection,
            name,
            0,
            1,
            // Mutate the properties to record the receiveer's address.
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[bcs::to_bytes(source_account)],
            vector<String>[ string::utf8(b"address") ],
        );

        coin::transfer<C>(source_account,percentageaddress,price);
        if(!exists<Mydeposits>(signer::address_of(source_account))){
            move_to<Mydeposits>(source_account,Mydeposits{
                total_aptos:price,
                total_nft:1
            });
        }
        else{
            let mydeposit = borrow_global_mut<Mydeposits>(signer::address_of(source_account));
            mydeposit.total_aptos = mydeposit.total_aptos + price ;
            mydeposit.total_nft = mydeposit.total_nft + 1;

        }
        
    }

    /// Mint an NFT to the receiver. Note that here we ask two accounts to sign: the module owner and the receiver.
    /// This is not ideal in production, because we don't want to manually sign each transaction. It is also
    /// impractical/inefficient in general, because we either need to implement delayed execution on our own, or have
    /// two keys to sign at the same time.
    /// In part 2 of this tutorial, we will introduce the concept of "resource account" - it is
    /// an account controlled by smart contracts to automatically sign for transactions. Resource account is also known
    /// as PDA or smart contract account in general blockchain terms.
    public entry fun delayed_mint_event_ticket(module_owner: &signer, receiver: address) acquires ModuleData {
        // Assert that the module owner signer is the owner of this module.
        assert!(signer::address_of(module_owner) == @mint_nft3, error::permission_denied(ENOT_AUTHORIZED));

        // Mint token to the receiver.
        let module_data = borrow_global_mut<ModuleData>(@mint_nft3);
        let token_id = token::mint_token(module_owner, module_data.token_data_id, 1);
        // token::direct_transfer(module_owner,  receiver, token_id, 1);

        // Mutate the token properties to update the property version of this token.
        // Note that here we are re-using the same token data id and only updating the property version.
        // This is because we are simply printing edition of the same token, instead of creating
        // tokens with unique names and token uris. The tokens created this way will have the same token data id,
        // but different property versions.
        let (creator_address, collection, name) = token::get_token_data_id_fields(&module_data.token_data_id);
        token::mutate_token_properties(
            module_owner,
            receiver,
            creator_address,
            collection,
            name,
            0,
            1,
            // Mutate the properties to record the receiveer's address.
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[bcs::to_bytes(&receiver)],
            vector<String>[ string::utf8(b"address") ],
        );
    }
}
