pragma solidity ^0.6.0;


import "./lib/presets/ERC1155PresetMinterPauser.sol";
import "./lib/access/Ownable.sol";


contract AvaxERC1155 is ERC1155PresetMinterPauser {
    constructor(string memory uri) public ERC1155PresetMinterPauser(uri) {
    }
}
