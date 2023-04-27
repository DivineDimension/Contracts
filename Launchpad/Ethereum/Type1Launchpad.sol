pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract NFTLaunchpad is ERC721URIStorage, Ownable {

    uint256 public  MAX_NFT_SUPPLY ; // Maximum number of NFTs to be minted
    uint256 public  PRICE_PER_NFT ; // Price per NFT in ether
    uint256 public  MAX_NFT_COUNT ;
    uint256 public  Phase ;
    uint256 public  start_time;
    uint256 public  end_time;

    uint256 private _totalSupply; // Total number of NFTs minted
    bool private _isSaleActive; // Whether the NFT sale is active
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct properties {
        uint256 total_nft;
        uint256 total_price;
    }

    mapping(address => properties) public myDeposits;

    constructor(string memory _name, string memory _symbol, string memory _imageUrl) ERC721(_name, _symbol) {
        MAX_NFT_COUNT = 1000;
        PRICE_PER_NFT = 10 ether;
        MAX_NFT_SUPPLY = 0;
        Phase = 1;
        start_time = 1682527214;
        end_time = 1687797613;
        
        imageUrl = _imageUrl;
    }

    string public imageUrl;

    function mintNFT(string memory _imageUrl) public payable {
        require(start_time <= block.timestamp , "NFT sale is not yet started");
        require(end_time >= block.timestamp , "NFT sale is ended");
        require(MAX_NFT_COUNT >= MAX_NFT_SUPPLY, "Exceeded maximum NFT supply");
        require(msg.value >= PRICE_PER_NFT , "Insufficient ether");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _imageUrl);
        MAX_NFT_SUPPLY = MAX_NFT_SUPPLY + 1;

        myDeposits[msg.sender].total_nft = myDeposits[msg.sender].total_nft + 1;
        myDeposits[msg.sender].total_price = myDeposits[msg.sender].total_price + msg.value;
    }

    /**
     * @dev Withdraw accumulated ether from the contract.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }

    function reSetter(uint256 count,uint256 price,uint256 supply,uint256 phs, uint256 starttime, uint256 endtime) public onlyOwner {
        MAX_NFT_COUNT = count;
        PRICE_PER_NFT = price * 1000000000000000000;
        MAX_NFT_SUPPLY = supply;
        Phase = phs;
        start_time = starttime;
        end_time = endtime;
    }

}
