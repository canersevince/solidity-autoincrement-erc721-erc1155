pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import "./lib/presets/ERC1155PresetMinterPauser.sol";
import "./lib/access/Ownable.sol";


contract AvaxERC1155 is ERC1155PresetMinterPauser, Ownable {
    constructor(string memory uri) public ERC1155PresetMinterPauser(uri) {
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
}
