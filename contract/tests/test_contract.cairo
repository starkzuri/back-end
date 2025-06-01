// import the interface and the dispatcher to be able to interact with the smart contract

use contract::interfaces::{IStarkZuriContractDispatcher, IStarkZuriContractDispatcherTrait};
use contract::structs::{User, Notification};
use contract::starkzuri::StarkZuri;
use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
// import traits and functions from snforge
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use contract::erc20::{IERC20DispatcherTrait, IERC20Dispatcher};

// add additionaly the testing utilities
use snforge_std::{start_cheat_caller_address_global, stop_cheat_caller_address_global, load};
// declare and deploy contract and return it's dispatcher
use starknet::{ContractAddress, get_caller_address};

fn deploy(owner: ContractAddress) -> IStarkZuriContractDispatcher {
    let contract = declare("StarkZuri").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![owner.into()]).unwrap();

    IStarkZuriContractDispatcher {contract_address}
    
}

#[test]
fn test_deploy() {
    let owner: ContractAddress = '0x'.try_into().unwrap();
    let contract = deploy(owner);


    assert_eq!(contract.get_owner(), owner);
}

#[test]
fn test_add_user() {
    let contract = deploy('0x'.try_into().unwrap());
    let caller: ContractAddress = starknet::contract_address_const::<'0x'>();
    start_cheat_caller_address_global(caller);
    contract.add_user('felix', 'felabs', "just a humble bounty hunter", "picstring", "picstring");
    let user: User = contract.view_user(caller);

    assert_eq!(user.userId, caller, "user does not exist");
    assert_eq!(user.profile_pic, "picstring", "user doesn't exist");
    assert_eq!(contract.view_user_count(), 1_u256, "user count did not increase"); // check if the user count increased

}


#[test]
fn test_follow_user(){
    let contract = deploy('0x'.try_into().unwrap());
    let caller: ContractAddress = starknet::contract_address_const::<'0x'>();
    let caller2: ContractAddress = starknet::contract_address_const::<'0x2'>();
    start_cheat_caller_address_global(caller);
    contract.follow_user(caller2);
    assert_eq!(contract.follower_exist(caller2), true, "didn't follow successfully");
    // check if user got notified after follow
    let notifications: Array<Notification> = contract.view_notifications(caller2);
    assert_eq!(notifications.len(), 1, "follow notification didn't happen");


}


// test create post

#[test]
fn test_create_post() {
    let contract = deploy('0x'.try_into().unwrap());
    let caller: ContractAddress = starknet::contract_address_const::<'0x'>();
    start_cheat_caller_address_global(caller);

    let content: ByteArray = "My first post!";
    let images: ByteArray = "image_url_1";

    contract.create_post(content.clone(), images.clone());

    // Post ID should be 1 since it's the first post
    let post = contract.view_post(1_u256);

    assert_eq!(post.postId, 1_u256, "Post ID mismatch");
    assert_eq!(post.caller, caller, "Caller mismatch");
    assert_eq!(post.content, content, "Post content mismatch");
    assert_eq!(post.images, images, "Image URL mismatch");
    assert_eq!(post.likes, 0_u8, "Likes should be zero");
    assert_eq!(post.comments, 0_u256, "Comments should be zero");
    assert_eq!(contract.get_total_posts(), 1_u256, "Post count mismatch");

    // // Optional: Check notification
    // let notifications: Array<Notification> = contract.view_notifications(caller);
    // assert_eq!(notifications.len(), 1, "Notification not triggered");

    stop_cheat_caller_address_global();
}



// test like post

#[test]
fn test_like_post() {
    let contract = deploy('0x'.try_into().unwrap());
    let caller: ContractAddress = starknet::contract_address_const::<'0x'>();
    // let erc_address = starknet::contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>();
    start_cheat_caller_address_global(caller);
    let content: ByteArray = "my first post";
    let images: ByteArray = "[image1, image2]";
    // contract.add_token_address('eth', erc_address);
    // let contractBalance:u256 = contract.view_contract_balance(erc_address);
    // contract balance should be 0 in the first place and a token address was added
    // assert_eq!(contractBalance, 0, "contract balance should be 0");
    
    // posting the content
    contract.create_post(content, images);
    let mut post = contract.view_post(1);

    // checking the post before a like
    assert_eq!(post.likes, 0, "like should be there yet");
    // making sure the post accomodated a like
    contract.like_post(1);
    let liked_post = contract.view_post(1);
    // let contract_balance_after_like = contract.view_contract_balance(erc_address);
    assert_eq!(liked_post.likes, 1, "post not liked");
    assert_eq!(liked_post.zuri_points, 10, "zuri points should be 10");
    // assert_eq!(contract_balance_after_like, 31000000000000, "contract balance should be 31000000000000");
    


}






// test comment on post
 


 // test create reel


 // test comment on reel


 // test create community
 #[test]
fn test_create_community() {
    let deployer: ContractAddress = '0x'.try_into().unwrap();
    let contract = deploy(deployer);

    // Setup: add a user first, since create_community reads user info
    let caller: ContractAddress = '0x1'.try_into().unwrap();
    start_cheat_caller_address_global(caller);

    contract.add_user(
        'alice',
        'alice123',
        "A community lover",
        "profile_pic",
        "cover_photo"
    );

    // Community details
    let community_name: felt252 = 'MyCommunity';
    let description: ByteArray = "This is a test community";
    let profile_image: ByteArray = "profile_img";
    let cover_image: ByteArray = "cover_img";

    // Call create_community
    contract.create_community(community_name, description.clone(), profile_image.clone(), cover_image.clone());

    // After creation:
    let community_id = 1_u256; // first community should have ID 1
    let community = contract.list_communities();

    // Check community fields
    assert_eq!(community.len(), 1, "community add success");

    stop_cheat_caller_address_global();
}



 // test join community


 // test trigger notification


 // test create reel

 #[test]
fn test_create_reel() {
    // Arrange
   let deployer: ContractAddress = '0x'.try_into().unwrap();
    let contract = deploy(deployer);
    let caller: ContractAddress = '0x1'.try_into().unwrap();

      start_cheat_caller_address_global(caller);
// Mock the caller

    let description = "My first reel";
    let video = "video_data_bytes";

    // Act
    contract.create_reel(description, video);

    // Assert
    let reel_count = contract.view_reels().len();
    assert_eq!(reel_count, 1_u32, "reel count should be 1");

    
    // Optionally check timestamp is recent (if test framework supports)
}



 // test like reel


 // test comment on reel

 // test view_reel_comments


 // test repost reel


 // test claim reel points

 // test claim post points


 // test deposit fee


 // test get_total_posts



 // test withdraw_zuri points




