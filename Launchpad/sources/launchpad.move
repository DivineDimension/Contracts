module nftlaunchpad1::NftLaunchpad1 {
  use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::event::EventHandle;
    use aptos_std::table; 
    use aptos_std::table::Table; 
    use std::string;
    use std::string::String;
    use std::option;
    use std::signer;
    use std::vector;
    use std::error;
    use std::debug;
    use aptos_token::token::{Self,check_collection_exists,balance_of,direct_transfer,transfer,opt_in_direct_transfer};

     const MAX_U64: u128 = 18446744073709551615;

 struct PoolInfo has key {
        active: bool,
        owner: address,
        new_owner: option::Option<address>,
        
        


        asset_aggregate_names: vector<String>, // [aggregate_name]
        asset_aggregates: Table<String, vector<String>>, // aggregate_name -> [coin_name]

        

        
        pool_ownership_transfer_events: EventHandle<PoolOwnershipTransferEvent>,

        signer_cap: account::SignerCapability,
    }

     struct Pools has key {
        pools: vector<address>,
        create_new_pool_events: EventHandle<CreateNewPoolEvent>,
        pool_ownership_transfer_events: EventHandle<PoolOwnershipTransferEvent>,
    }
      struct CreateNewPoolEvent has store, drop {
        owner_addr: address,
        pool_addr: address,
    }
   struct PoolOwnershipTransferEvent has store, drop {
        pool_addr: address,
        old_owner: address,
        new_owner: address,
    }



  public entry fun createpool(owner: &signer) acquires Pools {
        let (pool_signer, signer_cap) = account::create_resource_account(owner, vector::empty());

        let pool_addr = signer::address_of(&pool_signer);
        let pool = PoolInfo {
            active: true,
            owner: signer::address_of(owner),
            new_owner: option::none(),

            asset_aggregate_names: vector::empty(),
            asset_aggregates: table::new(),

            pool_ownership_transfer_events: account::new_event_handle(&pool_signer),


            signer_cap
        };
        move_to<PoolInfo>(&pool_signer, pool);

        if (!exists<Pools>(signer::address_of(owner))) {
            move_to<Pools>(owner, Pools {
                pools: vector::empty(),
                create_new_pool_events: account::new_event_handle(owner),
                pool_ownership_transfer_events: account::new_event_handle(owner),

            });
        };

        let pools = borrow_global_mut<Pools>(signer::address_of(owner));
        vector::push_back(&mut pools.pools, pool_addr);

        event::emit_event(&mut pools.create_new_pool_events, CreateNewPoolEvent {
            owner_addr: signer::address_of(owner),
            pool_addr,
        });
    }

    fun create_pool_signer(pool_addr: address): signer acquires PoolInfo {
        
        let pool_info = borrow_global_mut<PoolInfo>(pool_addr);

        account::create_signer_with_capability(&pool_info.signer_cap)
    }

    public entry fun add_asset<C>(account: &signer, pool_addr: address, creator_addr: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        tokens:u64
        ) acquires PoolInfo {
        let pool_signer = create_pool_signer(pool_addr);
        // coin::register<C>(&pool_signer);
        let token_id = token::create_token_id_raw(creator_addr, collection_name, token_name, property_version);
        //transfer(&pool_signer,token_id, staker_addr, tokens);        
        direct_transfer(account,&pool_signer,token_id,tokens);        
        // let (reward_treasury, reward_treasury_cap) = account::create_resource_account(staker, to_bytes(&seed));
    }

    public entry fun add_assets<C>(account: &signer, pool_addr: address, creator_addr: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        tokens:u64
        ) acquires PoolInfo {
        let pool_signer = create_pool_signer(pool_addr);
        // coin::register<C>(&pool_signer);
        let token_id = token::create_token_id_raw(creator_addr, collection_name, token_name, property_version);
        //transfer(&pool_signer,token_id, staker_addr, tokens);        
        //direct_transfer(account,&pool_signer,token_id,tokens);        
        transfer(account,token_id,pool_addr,tokens);
        // let (reward_treasury, reward_treasury_cap) = account::create_resource_account(staker, to_bytes(&seed));
    }

    public entry fun add_assetss<C>(account: &signer, pool_addr: address, creator_addr: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        tokens:u64
        ) acquires PoolInfo {
        let pool_signer = create_pool_signer(pool_addr);
        // coin::register<C>(&pool_signer);
        let token_id = token::create_token_id_raw(creator_addr, collection_name, token_name, property_version);
        //transfer(&pool_signer,token_id, staker_addr, tokens);        
        //direct_transfer(account,&pool_signer,token_id,tokens);        
        //transfer(account,token_id,pool_addr,tokens);
        opt_in_direct_transfer(&pool_signer,true)
        // let (reward_treasury, reward_treasury_cap) = account::create_resource_account(staker, to_bytes(&seed));
    }


    public entry fun add_assetssopt<C>(account: &signer, pool_addr: address, creator_addr: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        tokens:u64
        ) {
        //let pool_signer = create_pool_signer(pool_addr);
        // coin::register<C>(&pool_signer);
        //let token_id = token::create_token_id_raw(creator_addr, collection_name, token_name, property_version);
        //transfer(&pool_signer,token_id, staker_addr, tokens);        
        //direct_transfer(account,&pool_signer,token_id,tokens);        
        //transfer(account,token_id,pool_addr,tokens);
        opt_in_direct_transfer(account,true)
        // let (reward_treasury, reward_treasury_cap) = account::create_resource_account(staker, to_bytes(&seed));
    }






    public entry fun get_token<C>(account: &signer, pool_addr: address,amount: u64) {
        // let pool_signer = create_pool_signer(pool_addr);
        coin::transfer<C>(account, pool_addr, amount);

    }

    public entry fun dispense
    <C>
    (to: &signer, pool_addr: address,creator_addr: address,
        lister_add:address,
        collection_name: String,
        token_name: String,
        percentageaddress:address,
        price:u64,
        property_version: u64,
        tokens:u64) acquires PoolInfo {
        opt_in_direct_transfer(to,true);
        let staker_addr = signer::address_of(to);
        let pool = borrow_global_mut<PoolInfo>(pool_addr);
        let pool_signer = account::create_signer_with_capability(&pool.signer_cap);
        let token_id = token::create_token_id_raw(creator_addr, collection_name, token_name, property_version);
        //direct_transfer(&pool_signer,to,token_id,tokens);                
        //let coin = withdraw(&pool, tokens);
        //deposit(staker_addr, coin);
        //direct_transfer(&pool_signer,to,token_id,tokens);                
        // let royaltyescrow = ((price*15)/1000);
        // let royaltyremaining = ((price*985)/1000);                
        coin::transfer<C>(to,percentageaddress,price);
        // coin::transfer<C>(to,lister_add,royaltyremaining);        
        transfer(&pool_signer,token_id, staker_addr, tokens);
        //transfer_with_opt_in(&pool_signer,)
        //coin::transfer<CoinType>(staker,lister_address,prices);
        
    }

}
