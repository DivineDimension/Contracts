pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract NFTLaunchpad is ERC721URIStorage, Ownable {

   

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

    struct tokenprop {
        uint256 total_nft;
        uint256 total_amount;
    }


    mapping(address => properties) public myDeposits;

    mapping(address => tokenprop) public depositedTokens;


    address public erc20TokenAddress;

    constructor(string memory _name, string memory _symbol, string memory _imageUrl, address _erc20TokenAddress) ERC721(_name, _symbol) {

        start_time = 1682527214;
        end_time = 1687797613;
        
        imageUrl = _imageUrl;
        erc20TokenAddress = _erc20TokenAddress;
    }


    string public imageUrl;

    function mintNFT(uint256 _amount,string memory _imageUrl) public payable {
        require(_amount > 0, "Invalid amount");
        require(start_time <= block.timestamp , "NFT sale is not yet started");
        require(end_time >= block.timestamp , "NFT sale is ended");
        require(msg.value >= _amount , "Insufficient ether");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _imageUrl);
       

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
    
    function withdrawTokens() public onlyOwner {
        IERC20 erc20Token = IERC20(erc20TokenAddress);
        uint256 balance = erc20Token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(erc20Token.transfer(owner(), balance), "Token transfer failed");
    }

   

    function mintNFTWithTokens(uint256 _amount,string memory _imageUrl) public {
        require(_amount > 0, "Invalid amount");
        require(start_time <= block.timestamp , "NFT sale is not yet started");
        require(end_time >= block.timestamp , "NFT sale is ended");
        

        // uint256 requiredTokens = PRICE_PER_NFT * 10 ** 18; // Convert to wei


        _tokenIds.increment();
        require(IERC20(erc20TokenAddress).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _imageUrl);
       

        // Update the deposited tokens mapping
        // depositedTokens[msg.sender] -= requiredTokens;
        depositedTokens[msg.sender].total_nft = depositedTokens[msg.sender].total_nft + 1;
        depositedTokens[msg.sender].total_amount = depositedTokens[msg.sender].total_amount + _amount;
        // depositedTokens[msg.sender] += _amount;
    }



}
