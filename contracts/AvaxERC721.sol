pragma solidity ^0.6.0;

import "./lib/presets/ERC721PresetMinterPauserAutoId.sol";
import "./lib/access/Ownable.sol";
import "./lib/utils/Strings.sol";
import "./lib/utils/Counters.sol";

contract AvaxERC721 is ERC721PresetMinterPauserAutoId, Ownable {
    
    constructor(string memory _name, string memory _ticker, string memory _prefix) public ERC721PresetMinterPauserAutoId(_name, _ticker, _prefix) {
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
}