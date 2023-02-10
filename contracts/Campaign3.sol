// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IThreeFourteenN.sol";

// Campaign contract to earn random token
contract campaign3 is ERC1155Holder {

    IThreeFourteenN MAIN;

    mapping(address => uint256[]) public mintableTokens;
    uint256 initialNumber;
    
    event onERC1155ReceivedEvent(address indexed operator, address indexed from, uint256 id , uint256 value);
    event onERC1155BatchReceivedEvent(address indexed operator, address indexed from, uint256[] id, uint256[] value);

    constructor(IThreeFourteenN main){
        MAIN=main;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory
    ) public virtual override returns (bytes4) {
        emit onERC1155ReceivedEvent(operator, from, id, value);
        mintableTokens[from].push(id);
        return this.onERC1155Received.selector;
    }

    // Receive multiple ERC1155 tokens representing a cocoa batch
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory
    ) public virtual override returns (bytes4) {
        emit onERC1155BatchReceivedEvent(operator, from, ids, values);
        for (uint256 i = 0; i < ids.length; i++) {
            mintableTokens[from].push(ids[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    event RunEvent(address indexed business, address indexed customer, uint256 indexed selected);
    
    // Run by admin, selects a random token from mintable collection and sends it to the customer
    function run(address business, address customer, uint256[] calldata tokenIds, uint256[] calldata tokenAmounts) external{
        require(MAIN.hasRole(keccak256("ADMIN"),msg.sender) || msg.sender==customer, "not authorized");
        uint256 randomindex = random(mintableTokens[business].length);
        uint256 selected = mintableTokens[business][randomindex];
        for (uint i = 0; i<mintableTokens[business].length-1; i++){
            if(i>=randomindex){
                mintableTokens[business][i] = mintableTokens[business][i+1];
            }
        }
        mintableTokens[business].pop();
        MAIN.safeTransferFrom(address(this), customer, selected, 1, "");

        emit RunEvent(business, customer, selected);
    }

    function getMintableTokens(address business) external view returns (uint256[] memory){
        return mintableTokens[business];
    }

    function random(uint256 number) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(initialNumber++))) % number;
    }

}
