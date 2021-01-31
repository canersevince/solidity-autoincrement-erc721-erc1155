pragma solidity ^0.6.0;

import "./lib/presets/ERC721PresetMinterPauserAutoId.sol";
import "./lib/access/Ownable.sol";
import "./lib/utils/Strings.sol";
import "./lib/utils/Counters.sol";
import "./lib/access/OnlyMinter.sol";

contract AvaxERC721 is ERC721PresetMinterPauserAutoId, Ownable, MinterRole {
    using SafeMath for uint256;
    using Strings for string;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => Price) public Bazaar;

    event ErrorOut(string error, uint256 tokenId);
    event BatchTransfered(string metaId, address[] recipients, uint256[] ids);
    event Minted(address indexed from, address indexed to, uint256 indexed tokenId);
    event BatchBurned(string metaId, uint256[] ids);
    event BatchForSale(uint256[] ids, string metaId);
    event ForSale(uint256 id, string metaId);
    event Bought(uint256 tokenId, string metaId, uint256 value);
    event Destroy();

    address payable public maker;
    address payable feeAddress;



    constructor(string memory _name, string memory _ticker, string memory _prefix, address payable fee,
        address payable creator) public ERC721PresetMinterPauserAutoId(_name, _ticker, _prefix) {
        maker = creator;
        feeAddress = fee;
    }


    enum TokenState {Pending, ForSale, Sold, Transferred, Neutral}

    struct Price {
        uint256 tokenId;
        uint256 price;
        string metaId;
        TokenState state;
    }

    function mint(string memory _tokenURI, bool _onSale, uint256 price) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 current = _tokenIdTracker.current();
        _internal_mint(_tokenURI, _tokenIdTracker.current());
        if (_onSale == true) {
            mintAndSell(_tokenIdTracker.current());
            Bazaar[_tokenIdTracker.current()].price = price;
            Bazaar[_tokenIdTracker.current()].state = TokenState.ForSale;
        }
        _tokenIdTracker.increment();
        emit Minted(address(0), tx.origin, current);
    }

    function mintAndSell(uint256 id) internal onlyMinter {
        Bazaar[id].state = TokenState.ForSale;
        emit ForSale(id, Bazaar[id].metaId);
    }

    function setTokenState(uint256[] memory ids, bool isEnabled) public onlyMinter {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ownerOf(ids[i]) == _msgSender(), "Only token owner can call this.");
            if (isEnabled == true) {
                Bazaar[ids[i]].state = TokenState.ForSale;
            } else {
                Bazaar[ids[i]].state = TokenState.Pending;
            }
        }
        emit BatchForSale(ids, Bazaar[ids[0]].metaId);
    }


    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf(_tokenId), "ERC721: only owner can call this.");
        _;
    }

    function setTokenPrice(uint256 id, uint256 setPrice) public onlyTokenOwner(id) {
        Bazaar[id].price = setPrice;
        Bazaar[id].state = TokenState.ForSale;
    }

    function cancelTokenSale(uint256 id) public onlyTokenOwner(id) {
        delete Bazaar[id].price;
        Bazaar[id].state = TokenState.Neutral;
    }

    function serviceFee(uint256 amount) internal pure returns (uint256) {
        uint256 toOwner = SafeMath.mul(amount, 2);

        return SafeMath.div(toOwner, 100);
    }


    function buy(uint256 _tokenId) public payable {
        address tokenOwner = ownerOf(_tokenId);
        address payable seller = payable(address(tokenOwner));

        require(msg.value >= Bazaar[_tokenId].price, "Price issue");
        require(TokenState.ForSale == Bazaar[_tokenId].state, "No Sale");

        if (Bazaar[_tokenId].price >= 0) {
            uint256 fee = serviceFee(msg.value);
            uint256 withFee = SafeMath.sub(msg.value, fee);

            seller.transfer(withFee);
            feeAddress.transfer(fee);
        }

        _moveERC721(ownerOf(_tokenId), msg.sender, _tokenId);
        Bazaar[_tokenId].state = TokenState.Sold;

        emit Bought(_tokenId, Bazaar[_tokenId].metaId, msg.value);
    }
}