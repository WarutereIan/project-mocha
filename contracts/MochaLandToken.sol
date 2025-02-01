// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MochaLandToken is ERC721URIStorage, Ownable {
    using Strings for uint256;

    struct LandMetadata {
        string name;
        string description;
        string location;
        string gpsCoordinates;
        string area;
        string soilType;
        string ownership;
        string waterSource;
        uint256 yieldPotential; // in kg per year
        uint256 lastSurveyDate; // Unix timestamp
        string imageURI;
        string externalURL;
    }

    // Event for metadata updates
    event MetadataUpdated(
        uint256 indexed tokenId,
        string location,
        string gpsCoordinates,
        string area,
        string soilType,
        string ownership,
        string waterSource,
        uint256 yieldPotential,
        uint256 lastSurveyDate
    );

    event tokenCreated(
        uint256 indexed tokenId,
        LandMetadata metadata
    );

    // Mapping from token ID to land metadata
    mapping(uint256 => LandMetadata) private _landMetadata;

     // Registry address for ERC-6551
    address public immutable registry;
    
    // Implementation address for token bound accounts
    address public immutable implementation;

      constructor(
        address _registry,
        address _implementation
    ) ERC721("Mocha Land Token", "MLT") Ownable(msg.sender) {
        registry = _registry;
        implementation = _implementation;
    }

    function mint(
        address to,
        uint256 tokenId,
        LandMetadata memory metadata
    ) public onlyOwner {
        _mint(to, tokenId);
        _landMetadata[tokenId] = metadata;
        
        // Generate and set token URI
        string memory tokenURI = generateTokenURI(tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        // Create token bound account through ERC-6551 registry
        bytes memory data = "";
        (bool success,) = registry.call(
            abi.encodeWithSignature(
                "createAccount(address,uint256,address,uint256,uint96,bytes)",
                address(this),
                tokenId,
                implementation,
                block.chainid,
                0,
                data
            )
        );
        require(success, "Failed to create token bound account");

        //emit token created event
        emit tokenCreated(
            tokenId,
            metadata
        );
    }

    function generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        LandMetadata memory metadata = _landMetadata[tokenId];
        
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "', metadata.name, '",',
            '"description": "', metadata.description, '",',
            '"image": "', metadata.imageURI, '",',
            '"attributes": [',
                '{"trait_type": "Location", "value": "', metadata.location, '"},',
                '{"trait_type": "GPS Coordinates", "value": "', metadata.gpsCoordinates, '"},',
                '{"trait_type": "Area", "value": "', metadata.area, '"},',
                '{"trait_type": "Soil Type", "value": "', metadata.soilType, '"},',
                '{"trait_type": "Ownership", "value": "', metadata.ownership, '"},',
                '{"trait_type": "Water Source", "value": "', metadata.waterSource, '"},',
                '{"trait_type": "Yield Potential", "value": "', uint256(metadata.yieldPotential).toString(), ' kg per year"},',
                '{"trait_type": "Last Survey Date", "value": "', formatDate(metadata.lastSurveyDate), '"}',
            '],',
            '"external_url": "', metadata.externalURL, '"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function formatDate(uint256 timestamp) internal pure returns (string memory) {
        // Simplified date formatting
        return uint256(timestamp).toString();
    }

    function updateMetadata(
        uint256 tokenId,
        LandMetadata memory newMetadata
    ) public onlyOwner {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        _landMetadata[tokenId] = newMetadata;
        
        // Update token URI
        string memory tokenURI = generateTokenURI(tokenId);
        _setTokenURI(tokenId, tokenURI);

        // Emit metadata update event
        emit MetadataUpdated(
            tokenId,
            newMetadata.location,
            newMetadata.gpsCoordinates,
            newMetadata.area,
            newMetadata.soilType,
            newMetadata.ownership,
            newMetadata.waterSource,
            newMetadata.yieldPotential,
            newMetadata.lastSurveyDate
        );
    }

    function getLandMetadata(uint256 tokenId) public view returns (LandMetadata memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return _landMetadata[tokenId];
    }

    // Helper function to create metadata struct
    function createMetadata(
        string memory name,
        string memory description,
        string memory location,
        string memory gpsCoordinates,
        string memory area,
        string memory soilType,
        string memory ownership,
        string memory waterSource,
        uint256 yieldPotential,
        uint256 lastSurveyDate,
        string memory imageURI,
        string memory externalURL
    ) public pure returns (LandMetadata memory) {
        return LandMetadata({
            name: name,
            description: description,
            location: location,
            gpsCoordinates: gpsCoordinates,
            area: area,
            soilType: soilType,
            ownership: ownership,
            waterSource: waterSource,
            yieldPotential: yieldPotential,
            lastSurveyDate: lastSurveyDate,
            imageURI: imageURI,
            externalURL: externalURL
        });
    }
}