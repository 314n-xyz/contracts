// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IThreeFourteenN.sol";

//discountable nft
contract Campaign2 {

    IThreeFourteenN MAIN;
    mapping(uint256 => uint256) public discountPercentage;
    mapping(uint256 => uint256) public expireTime;
    mapping(uint256 => uint256) public maxUseCount;

    //userAddr=>tokenId=>count
    mapping(address => mapping(uint256 => uint256)) public useCount;

    event RunEvent(address indexed business, address indexed customer, uint256 indexed percentage);

    constructor(IThreeFourteenN main){
        MAIN=main;
    }
    
    // Run by admin, burns single NFT
    function run(address business, address customer, uint256[] calldata tokenIds, uint256[] calldata tokenAmounts) external{
        require(MAIN.hasRole(keccak256("ADMIN"),msg.sender) || msg.sender==customer, "not authorized");
        require(tokenAmounts.length==1 && tokenIds.length==1,"is not one");
        require(tokenAmounts[0]==1,"is must one");
        require(MAIN.getTypeofToken(tokenIds[0])==0x374baf8d7a7686abbdfdb086b0ed6cc03591bb82f4d4a04e2e3e336f01512ece,"is not coffeenft");
        require(expireTime[tokenIds[0]]>=block.timestamp,"expired");
        require(useCount[customer][tokenIds[0]]<=maxUseCount[tokenIds[0]],"max use");
        require(discountPercentage[tokenIds[0]]<=100,"invalid percentage");

        useCount[customer][tokenIds[0]]++;

        emit RunEvent(business, customer, discountPercentage[tokenIds[0]]);

        if(useCount[customer][tokenIds[0]]>=maxUseCount[tokenIds[0]]){
            useCount[customer][tokenIds[0]]=0;
            MAIN.externalBurn(business,customer,tokenIds,tokenAmounts);
        }
    }

    function setCampaignData(uint256 tokenId, uint256 percentage, uint256 expiretime, uint256 maxusecount) external {
        discountPercentage[tokenId]=percentage;
        expireTime[tokenId]=expiretime;
        maxUseCount[tokenId]=maxusecount;
    }

    function getPercentage(uint256 tokenId) external view returns (uint256) {
        return discountPercentage[tokenId];
    }

    function getExpireTime(uint256 tokenId) external view returns (uint256) {
        return expireTime[tokenId];
    }

    function getMaxUseCount(uint256 tokenId) external view returns (uint256) {
        return maxUseCount[tokenId];
    }

    function getUsingCount(address customerAddr, uint256 tokenId) external view returns (uint256) {
        return useCount[customerAddr][tokenId];
    }

}
