// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IThreeFourteenN.sol";

// Campaign contract to earn spesific gift by spending n Coffeepins
contract Campaign1 {

    IThreeFourteenN MAIN;

    // Possible amounts of Coffeepins set by business to get a free product
    mapping(address => uint256[]) public amountsForCampaignByBusiness;

    event RunEvent(address indexed business, address indexed who, uint256 indexed percentage);

    constructor(IThreeFourteenN main){
        MAIN=main;
    }

    // Run by admin, burns specified tokens by specified amounts
    function run(address business, address customer, uint256[] calldata tokenIds, uint256[] calldata tokenAmounts) external{
        require(MAIN.hasRole(keccak256("ADMIN"),msg.sender) || msg.sender==customer, "not authorized");
        uint256 totalAmounts = 0;
        for(uint256 i=0;i<tokenIds.length;i++){
            totalAmounts += tokenAmounts[i];
            require(MAIN.getTypeofToken(tokenIds[i])==0xa1be525b079adeb3ff24cad3eb788ce6273b715deddb3398452f8c30d4d61579,"is not coffeepin");
        }
        bool amountExists;
        for (uint i; i< amountsForCampaignByBusiness[business].length;i++){
          // Tokens to be spend should match a campaign amount set by business
          if (amountsForCampaignByBusiness[business][i]==totalAmounts){
            amountExists=true;
          }
        }
        require(amountExists,"No such campaign amount");

        emit RunEvent(business, customer, totalAmounts);
        MAIN.externalBurn(business,customer,tokenIds,tokenAmounts);
    }

    function setAmountsForCampaignByBusiness(uint256[] calldata amounts) external {
        amountsForCampaignByBusiness[msg.sender]=amounts;
    }

    function getAmountsForCampaignByBusiness(address businessAddr) external view returns (uint256[] memory) {
        return amountsForCampaignByBusiness[businessAddr];
    }

}
