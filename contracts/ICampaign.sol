// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICampaign {

   function run(address business, address customer, uint256[] calldata tokenIds, uint256[] calldata tokenAmounts) external;

}