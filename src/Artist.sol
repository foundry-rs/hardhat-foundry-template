// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {LibUintToString} from "./LibUintToString.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {ArtistCreator} from "./ArtistCreator.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
    @title Artist
    @notice This contract is used to create & sell song NFTs for the artist who owns the contract.
    @dev Started as a fork of Mirror's Editions.sol https://github.com/mirror-xyz/editions-v1/blob/main/contracts/Editions.sol
*/
contract Artist is ERC721Upgradeable, IERC2981Upgradeable, OwnableUpgradeable {
    // ================================
    // TYPES
    // ================================

    using LibUintToString for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ECDSA for bytes32;

    enum TimeType {
        START,
        END
    }

    // ============ Structs ============

    struct Edition {
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The price at which each token will be sold, in MATIC.
        uint256 price;
        // The number of tokens sold so far.
        uint32 numSold;
        // Time-Bound Unlimited Number of Editions
        bool isUnlimited;
        // The maximum number of tokens that can be sold.
        uint32 quantity;
        // Royalty amount in bps
        uint32 royaltyBPS;
        // start timestamp of auction (in seconds since unix epoch)
        uint32 startTime;
        // end timestamp of auction (in seconds since unix epoch)
        uint32 endTime;
        // quantity of permissioned tokens
        uint32 permissionedQuantity;
        // whitelist signer address
        address signerAddress;
    }

    // ================================
    // STORAGE
    // ================================

    string internal baseURI;

    CountersUpgradeable.Counter private atTokenId; // DEPRECATED IN V3
    CountersUpgradeable.Counter private atEditionId;

    // Mapping of edition id to descriptive data.
    mapping(uint256 => Edition) public editions;
    // <DEPRECATED IN V3> Mapping of token id to edition id.
    mapping(uint256 => uint256) private _tokenToEdition;
    // The amount of funds that have been deposited for a given edition.
    mapping(uint256 => uint256) public depositedForEdition;
    // The amount of funds that have already been withdrawn for a given edition.
    mapping(uint256 => uint256) public withdrawnForEdition;
    // The permissioned typehash (used for checking signature validity)
    bytes32 private constant PERMISSIONED_SALE_TYPEHASH =
        keccak256(
            "EditionInfo(address contractAddress,address buyerAddress,uint256 editionId)"
        );
    bytes32 private immutable DOMAIN_SEPARATOR;

    // ================================
    // EVENTS
    // ================================

    event EditionCreated(
        uint256 indexed editionId,
        address fundingRecipient,
        uint256 price,
        bool isUnlimited,
        uint32 quantity,
        uint32 royaltyBPS,
        uint32 startTime,
        uint32 endTime,
        uint32 permissionedQuantity,
        address signerAddress
    );

    /*
        numSold: `numSold` at time of purchase represents the "serial number" of the NFT.
        buyer: The account that paid for and received the NFT.
    */
    event EditionPurchased(
        uint256 indexed editionId,
        uint256 indexed tokenId,
        uint32 numSold,
        address indexed buyer
    );

    event MultipleEditionsPurchased(
        uint256[] indexed editionIds,
        uint256[] indexed tokenIds,
        uint256[] numSold,
        address indexed buyer
    );

    event AuctionTimeSet(
        TimeType timeType,
        uint256 editionId,
        uint32 indexed newTime
    );

    event SignerAddressSet(uint256 editionId, address indexed signerAddress);

    event PermissionedQuantitySet(
        uint256 editionId,
        uint32 permissionedQuantity
    );

    // ================================
    // PUBLIC & EXTERNAL WRITABLE FUNCTIONS
    // ================================

    /*
        @notice Contract constructor
    */
    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(uint256 chainId)"),
                block.chainid
            )
        );
    }

    /*
        @notice Initializes the contract
        @param _owner Owner of edition
        @param _name Name of artist
    */
    function initialize(
        address _owner,
        uint256 _artistId,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        // Set ownership to original sender of contract call
        transferOwnership(_owner);

        // E.g. https://.../api/metadata/[artistId]/
        baseURI = string(abi.encodePacked(_baseURI, _artistId.toString(), "/"));

        // Set edition id start to be 1 not 0
        atEditionId.increment();
    }

    /*
        @notice Creates a new edition.
        @param _fundingRecipient The account that will receive sales revenue.
        @param _price The price at which each token will be sold, in ETH or MATIC.
        @param _isUnlimited Checks that collectors can purchase an unlimited number of editions
        @param _quantity The maximum number of tokens that can be sold.
        @param _royaltyBPS The royalty amount in bps.
        @param _startTime The start time of the auction, in seconds since unix epoch.
        @param _endTime The end time of the auction, in seconds since unix epoch.
        @param _permissionedQuantity The quantity of tokens that require a signature to buy.
        @param _signerAddress signer address.
    */
    function createEdition(
        address payable _fundingRecipient,
        uint256 _price,
        bool _isUnlimited,
        uint32 _quantity,
        uint32 _royaltyBPS,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _permissionedQuantity,
        address _signerAddress
    ) external onlyOwner {
        if (!_isUnlimited) {
            require(
                _permissionedQuantity < _quantity + 1,
                "Permissioned quantity too big"
            );
            require(_quantity > 0, "Must set quantity");
        }
        require(_fundingRecipient != address(0), "Must set fundingRecipient");
        if (_isUnlimited) {
            require(
                _endTime > _startTime,
                "End time must be greater than start time"
            );
        }

        if (_permissionedQuantity > 0) {
            require(_signerAddress != address(0), "Signer address cannot be 0");
        }

        editions[atEditionId.current()] = Edition({
            fundingRecipient: _fundingRecipient,
            price: _price,
            numSold: 0,
            isUnlimited: _isUnlimited,
            quantity: _quantity,
            royaltyBPS: _royaltyBPS,
            startTime: _startTime,
            endTime: _endTime,
            permissionedQuantity: _permissionedQuantity,
            signerAddress: _signerAddress
        });

        emit EditionCreated(
            atEditionId.current(),
            _fundingRecipient,
            _price,
            _isUnlimited,
            _quantity,
            _royaltyBPS,
            _startTime,
            _endTime,
            _permissionedQuantity,
            _signerAddress
        );

        atEditionId.increment();
    }

    /*
        @notice Creates a new token for the given edition, and assigns it to the buyer
        @param _editionId The id of the edition to purchase
        @param _signature A signed message for authorizing permissioned purchases
    */
    function buyEdition(uint256 _editionId) external payable {
        // Caching variables locally to reduce reads
        uint256 price = editions[_editionId].price;
        bool isUnlimited = editions[_editionId].isUnlimited;
        uint32 quantity = editions[_editionId].quantity;
        uint32 numSold = editions[_editionId].numSold;
        uint32 startTime = editions[_editionId].startTime;
        uint32 endTime = editions[_editionId].endTime;
        uint32 permissionedQuantity = editions[_editionId].permissionedQuantity;

        if (!isUnlimited) {
            // Check that the edition exists. Note: this is redundant
            // with the next check, but it is useful for clearer error messaging.
            require(quantity > 0, "Edition does not exist");
            // Check that there are still tokens available to purchase.
            require(numSold < quantity, "This edition is already sold out.");
        }

        // Check that the sender is paying the correct amount.
        require(
            msg.value >= price,
            "Must send enough to purchase the edition."
        );

        if (isUnlimited) {
            // If the open auction hasn't started...
            if (startTime > block.timestamp) {
                // Check that permissioned tokens are still available
                require(
                    permissionedQuantity > 0 && numSold < permissionedQuantity,
                    "No permissioned tokens available & open auction not started"
                );
            }

            // Don't allow purchases after the end time
            require(endTime > block.timestamp, "Auction has ended");
        }

        // Create the token id by packing editionId in the top bits
        uint256 tokenId;
        unchecked {
            tokenId = (_editionId << 128) | (numSold + 1);
            // Increment the number of tokens sold for this edition.
            editions[_editionId].numSold = numSold + 1;
        }

        // If fundingRecipient is the owner (artist's wallet), update the edition's balance & don't send the funds
        if (editions[_editionId].fundingRecipient == owner()) {
            // Update the deposited total for the edition
            depositedForEdition[_editionId] += msg.value;
        } else {
            // Send funds to the funding recipient.
            _sendFunds(editions[_editionId].fundingRecipient, msg.value);
        }

        // Mint a new token for the sender, using the `tokenId`.
        _mint(msg.sender, tokenId);

        emit EditionPurchased(_editionId, tokenId, numSold + 1, msg.sender);
    }

    /*
        @notice Ability for 1 user wallet to batch mint/purchase multiple editions in one go.
        @param _editionId The id of the edition to purchase
        @param _signature A signed message for authorizing permissioned purchases
    */
    function buyMultipleEditions(uint256[] memory _editionIds)
        external
        payable
    {
        // uint256 len = _editionIds.length;
        require(_editionIds.length > 0, "Should be greater than zero.");

        uint256[] memory tokenIds = _editionIds;
        uint256[] memory numSolds = _editionIds;

        for (uint256 i = 0; i < _editionIds.length; i++) {
            // Caching variables locally to reduce reads
            uint256 editionId = _editionIds[i];
            uint256 price = editions[editionId].price;
            bool isUnlimited = editions[editionId].isUnlimited;
            uint32 quantity = editions[editionId].quantity;
            uint32 numSold = editions[editionId].numSold;
            uint32 startTime = editions[editionId].startTime;
            uint32 endTime = editions[editionId].endTime;
            uint32 permissionedQuantity = editions[editionId]
                .permissionedQuantity;

            if (!isUnlimited) {
                // Check that the edition exists. Note: this is redundant
                // with the next check, but it is useful for clearer error messaging.
                require(quantity > 0, "Edition does not exist");
                // Check that there are still tokens available to purchase.
                require(
                    numSold < quantity,
                    "This edition is already sold out."
                );
            }

            // Check that the sender is paying the correct amount.
            require(
                msg.value >= price,
                "Must send enough to purchase the edition."
            );

            if (isUnlimited) {
                // If the open auction hasn't started...
                if (startTime > block.timestamp) {
                    // Check that permissioned tokens are still available
                    require(
                        permissionedQuantity > 0 &&
                            numSold < permissionedQuantity,
                        "No permissioned tokens available & open auction not started"
                    );
                }

                // Don't allow purchases after the end time
                require(endTime > block.timestamp, "Auction has ended");
            }

            // Create the token id by packing editionId in the top bits
            uint256 newTokenId;
            unchecked {
                newTokenId = (editionId << 128) | (numSold + 1);
                // Increment the number of tokens sold for this edition.
                editions[editionId].numSold = numSold + 1;
            }

            // If fundingRecipient is the owner (artist's wallet), update the edition's balance & don't send the funds
            if (editions[editionId].fundingRecipient == owner()) {
                // Update the deposited total for the edition
                depositedForEdition[editionId] += msg.value;
            } else {
                // Send funds to the funding recipient.
                _sendFunds(editions[editionId].fundingRecipient, msg.value);
            }

            tokenIds[i] = newTokenId;
            numSolds[i] = numSold + 1;

            // Mint a new token for the sender, using the `tokenId`.
            _mint(msg.sender, newTokenId);
        }

        emit MultipleEditionsPurchased(
            _editionIds,
            tokenIds,
            numSolds,
            msg.sender
        );
    }

    function withdrawFunds(uint256 _editionId) external {
        // Compute the amount available for withdrawing from this edition.
        uint256 remainingForEdition = depositedForEdition[_editionId] -
            withdrawnForEdition[_editionId];

        // Set the amount withdrawn to the amount deposited.
        withdrawnForEdition[_editionId] = depositedForEdition[_editionId];

        // Send the amount that was remaining for the edition, to the funding recipient.
        _sendFunds(editions[_editionId].fundingRecipient, remainingForEdition);
    }

    /*
        @notice Sets the start time for an edition
    */
    function setStartTime(uint256 _editionId, uint32 _startTime)
        external
        onlyOwner
    {
        editions[_editionId].startTime = _startTime;
        emit AuctionTimeSet(TimeType.START, _editionId, _startTime);
    }

    /*
        @notice Sets the end time for an edition
    */
    function setEndTime(uint256 _editionId, uint32 _endTime)
        external
        onlyOwner
    {
        editions[_editionId].endTime = _endTime;
        emit AuctionTimeSet(TimeType.END, _editionId, _endTime);
    }

    /*
        @notice Sets the signature address of an edition
    */
    function setSignerAddress(uint256 _editionId, address _newSignerAddress)
        external
        onlyOwner
    {
        require(_newSignerAddress != address(0), "Signer address cannot be 0");

        editions[_editionId].signerAddress = _newSignerAddress;
        emit SignerAddressSet(_editionId, _newSignerAddress);
    }

    /*
        @notice Sets the permissioned quantity for an edition
    */
    function setPermissionedQuantity(
        uint256 _editionId,
        uint32 _permissionedQuantity
    ) external onlyOwner {
        // Check that the permissioned quantity is less than the total quantity
        require(
            _permissionedQuantity < editions[_editionId].quantity + 1,
            "Must not exceed quantity"
        );
        // Prevent setting to permissioned quantity when there is no signer address
        require(
            editions[_editionId].signerAddress != address(0),
            "Edition must have a signer"
        );

        editions[_editionId].permissionedQuantity = _permissionedQuantity;
        emit PermissionedQuantitySet(_editionId, _permissionedQuantity);
    }

    // ================================
    // VIEW FUNCTIONS
    // ================================

    /*
        @notice Returns token URI (metadata URL). e.g. https://sound.xyz/api/metadata/[artistId]/[editionId]/[tokenId]
        @dev Concatenate the baseURI, editionId and tokenId, to create URI.
    */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 editionId = tokenToEdition(_tokenId);

        return
            string(
                abi.encodePacked(
                    baseURI,
                    editionId.toString(),
                    "/",
                    _tokenId.toString()
                )
            );
    }

    /* 
        @notice Returns contract URI used by Opensea. e.g. https://sound.xyz/api/metadata/[artistId]/storefront
    */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "storefront"));
    }

    /*
        @notice Get royalty information for token
        @param _tokenId token id
        @param _salePrice Sale price for the token
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address fundingRecipient, uint256 royaltyAmount)
    {
        uint256 editionId = tokenToEdition(_tokenId);
        Edition memory edition = editions[editionId];

        if (edition.fundingRecipient == address(0x0)) {
            return (edition.fundingRecipient, 0);
        }

        uint256 royaltyBPS = uint256(edition.royaltyBPS);

        return (edition.fundingRecipient, (_salePrice * royaltyBPS) / 10_000);
    }

    /*
        @notice The total number of tokens created by this contract
    */
    function totalSupply() external view returns (uint256) {
        uint256 total = 0;
        for (uint256 id = 1; id < atEditionId.current(); id++) {
            total += editions[id].numSold;
        }
        return total;
    }

    /*
        @notice Informs other contracts which interfaces this contract supports
        @dev https://eips.ethereum.org/EIPS/eip-165
    */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == _interfaceId ||
            ERC721Upgradeable.supportsInterface(_interfaceId);
    }

    /*
        @notice returns the number of editions for this artist
    */
    function editionCount() external view returns (uint256) {
        return atEditionId.current() - 1; // because atEditionId is incremented after each edition is created
    }

    function tokenToEdition(uint256 _tokenId) public view returns (uint256) {
        // Check the top bits to see if the edition id is there
        uint256 editionId = _tokenId >> 128;

        // If edition ID is 0, then this edition was created before the V3 upgrade
        if (editionId == 0) {
            // get edition ID from storage
            return _tokenToEdition[_tokenId];
        }

        return editionId;
    }

    function ownersOfTokenIds(uint256[] calldata _tokenIds)
        external
        view
        returns (address[] memory)
    {
        address[] memory owners = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            owners[i] = ownerOf(_tokenIds[i]);
        }
        return owners;
    }

    // ================================
    // FUNCTIONS - PRIVATE
    // ================================

    /*
        @notice Sends funds to an address
        @param _recipient The address to send funds to
        @param _amount The amount of funds to send
    */
    function _sendFunds(address payable _recipient, uint256 _amount) private {
        require(
            address(this).balance >= _amount,
            "Insufficient balance for send"
        );

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Unable to send value: recipient may have reverted");
    }
}
