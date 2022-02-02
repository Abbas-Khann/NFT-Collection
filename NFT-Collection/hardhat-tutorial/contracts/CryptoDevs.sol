// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable , Ownable {

    string _baseTokenURI;

    // _price is the price of one crypto dev NFT
    uint256 public _price = 0.01 ether;

    // _paused is used to pause the contract in case of an emergency 
    bool public _paused;

    // maximum number of CryptoDevs
    uint256 public maxTokenIds = 20;

    // Total number of tokenIds minted
    uint256 public tokenIds;

    // Whitelist contract instance
    IWhitelist whitelist;

    // boolean to keep track of when the presale starts
    bool public presaleStarted;

    // Timestamp for even presale would end
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721 ("Crypto Devs" , "CD") {

        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    } 

    // starting the presale for the whitelisted addresses 

    function startPresale() public onlyOwner {
        presaleStarted = true;
        // let's set the presaleEnded time as the current timestamp + 5 more minutes
        // Solidity has it's own syntax for timestamps (seconds, minutes, hours, days, years)
        presaleEnded = block.timestamp + 5 minutes;
    }

    function startPresaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        require(tokenIds < maxTokenIds, "Exceeded maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds++;

        // SafeMint is a safer version of the _mint funtion as it ensures that if the address being minted is a contract
        // Then it knows how to deal with ERC 721 tokens
        // If the address being minted to is not a contract, it works the same way as _mint function
        _safeMint(msg.sender, tokenIds);
    }

    //@dev Mint will allow a user to mint 1 NFT per transaction after the presale has ended

    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >= presaleEnded, "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceeded maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds++;
        _safeMint(msg.sender, tokenIds);
    }

    //@dev _baseURI overrides the openzeppelin's ERC721 implementation which by default returned an empty string for the baseURI

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //@dev setpaused makes the contract paused or unpaused 

    function setPaused (bool val) public onlyOwner {
        _paused = val;
    }

    //@dev withdraw sends all the ether in the contract to the owner of the contract

    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount} ("");
        require (sent , "Failed to send ether");
    }

    // Function to recieve Ether.msg.data must be empty 
    receive() external payable {}

    // Fallback function is called when msg.data is not empty 
    fallback() external payable {}
}