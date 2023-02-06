// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IThreeFourteenN {

    function getTypeofToken(uint256 tokenId) external view returns(bytes32);

    function hasRole(bytes32 role, address account) external view returns(bool);
    
    function externalBurn(address business, address customer, uint256[] calldata usedTokenIds, uint256[] calldata tokenAmounts) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}