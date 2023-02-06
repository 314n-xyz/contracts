// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ICampaign.sol";

contract ThreeFourteenN is ERC1155Pausable, AccessControl {// Pausable:sıkıntı olursa, Reenterency Guard
    using SafeERC20 for IERC20;
    
    IERC20 public immutable NATIVE;
    address contractOwner;

    mapping(address => uint256) public tokenIds;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant BUSINESS = keccak256("BUSINESS");

    mapping(bytes32 => uint256) public tokenTypePrice;
    uint256 public newBusinessPrice = 100;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    mapping(address => uint256[]) public tokenIdsbyBusiness;
    mapping(uint256 => address) public businessAddressbyToken;
    mapping(uint256 => bytes32) public typeofToken;
    mapping(bytes32 => bool) public tokenTypes; // isTokenType olmalı
    mapping(bytes32 => address[]) public tokenTypeCampaignAddreses;
    mapping(address => bool) public isValidCampaignAddres;

    constructor(IERC20 _native) ERC1155("https://coffeepin.me/token/{id}") {
        _setupRole(ADMIN, msg.sender);
        contractOwner=msg.sender;
        NATIVE=_native;
    }

    function contractURI() public pure returns (string memory) {
        return "https://coffeepin.me/token/0";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    event MintEvent(uint256 indexed tokenId, address indexed business);
    event BurnEvent(uint256[] indexed tokenIds, address indexed business, address indexed customer);

    function newBusiness() public {
        require(
            NATIVE.balanceOf(msg.sender) >= newBusinessPrice,
            "Not enough ERC20 balance, price of new business defining @newBusinessPrice"
        );
        require(!(hasRole(BUSINESS, msg.sender)), "Caller cannot be BUSINESS");
        NATIVE.safeTransferFrom(msg.sender,payable(contractOwner), newBusinessPrice);//  işletmenin transfer approvalı nodedan yapıyoruz?
        _setupRole(BUSINESS, msg.sender);
    } 

    function newTokenType(bytes32 typeHash,uint256 price) public {
        require((hasRole(ADMIN, msg.sender)), "Caller must be ADMIN");
        tokenTypes[typeHash]=true;
        tokenTypePrice[typeHash]=price;
    }

    function removeTokenType(bytes32 typeHash) public {
        require((hasRole(ADMIN, msg.sender)), "Caller must be ADMIN");
        delete tokenTypeCampaignAddreses[typeHash];
        delete tokenTypes[typeHash]; 
    }

    function newCampaignAddr(bytes32 typeHash, address addr) public payable{
        require((hasRole(ADMIN, msg.sender)), "Caller must be ADMIN");
        require(
            tokenTypes[typeHash]==true,
            "There is no token type"
        );
        tokenTypeCampaignAddreses[typeHash].push(addr);
        isValidCampaignAddres[addr]=true;
    }

    function removeCampaignAddr(bytes32 typeHash, address addr) public payable{
        require((hasRole(ADMIN, msg.sender)), "Caller must be ADMIN");
        for (uint i = 0; i<tokenTypeCampaignAddreses[typeHash].length-1; i++){
            if(tokenTypeCampaignAddreses[typeHash][i]==addr){
                tokenTypeCampaignAddreses[typeHash][i] = tokenTypeCampaignAddreses[typeHash][i+1];
            }
        }
        tokenTypeCampaignAddreses[typeHash].pop();
        delete isValidCampaignAddres[addr];
    }

    function mint(bytes32 tokentype, uint256 amount, uint256 tokenId) public payable {
        require(hasRole(BUSINESS, msg.sender), "Caller is not a BUSINESS");
        require(
            amount <= NATIVE.balanceOf(msg.sender),
            "You dont have enough your Token, Your Token to Pin rate is 1to1"
        );
        if(tokenId==0){
            require(
                NATIVE.balanceOf(msg.sender)>amount+tokenTypePrice[tokentype],//amount * tokenTypePrice
                "Not enough ERC20 Balance"
            );
            require(
                tokenTypes[tokentype]==true,
                "There is no token type"
            );
            _tokenIds.increment();
            tokenIdsbyBusiness[msg.sender].push(_tokenIds.current());
            businessAddressbyToken[_tokenIds.current()] = msg.sender;
            typeofToken[_tokenIds.current()] = tokentype;
            NATIVE.safeTransferFrom(msg.sender,payable(contractOwner), tokenTypePrice[tokentype]);
            NATIVE.safeTransferFrom(msg.sender,payable(contractOwner), amount);
            _mint(msg.sender, _tokenIds.current(), amount, "");
        }else{
            NATIVE.safeTransferFrom(msg.sender,payable(contractOwner), amount);
            _mint(msg.sender, tokenId, amount, "");
        }
        emit MintEvent(_tokenIds.current(), msg.sender);
    }

    function callCampaign(address campaignAddr, address businessAddr, uint256[] calldata callTokenIds, uint256[] calldata callTokenAmounts) public {
        ICampaign(campaignAddr).run(businessAddr,msg.sender,callTokenIds,callTokenAmounts);
    }

    function externalBurn(address business, address customer, uint256[] calldata tokens, uint256[] calldata amounts) external {
        require(isValidCampaignAddres[msg.sender],"is not valid adress");
        _burnBatch(customer, tokens, amounts);
        emit BurnEvent(tokens, business, customer);
    }

    function getTokenIdsbyBusiness(address businessAddr) public view returns (uint256[] memory) {
        return tokenIdsbyBusiness[businessAddr];
    }
    function getTokenTypeCampaignAddreses(bytes32 tokenType) public view returns (address[] memory) {
        return tokenTypeCampaignAddreses[tokenType];
    }
    function getTypeofToken(uint256 tokenId) external view returns (bytes32) {
        return typeofToken[tokenId];
    }
    function getAllBalanceof() public view returns (uint256[] memory) {
        //require(hasRole(ADMIN,msg.sender), "Caller is not a ADMIN");
        address[] memory accounts = new address[](_tokenIds.current() + 1);
        uint256[] memory alltokenids = new uint256[](_tokenIds.current() + 1);
        for (uint256 i = 0; i <= _tokenIds.current(); i++) {
            accounts[i] = msg.sender;
            alltokenids[i] = i;
        }
        return balanceOfBatch(accounts, alltokenids);
    }

}
