// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./slib.sol";

contract FundRasingShareToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint => SLib.ProjectShare) projectShareMap;
    mapping(address => uint[]) ownedTokensId;

    constructor() ERC721("FundRasingShareToken", "MTK") {
        _tokenIdCounter.increment();
    }

    function safeMintProjectShareNFT(address to, uint _projectId, uint _share) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        // save metadata
        SLib.ProjectShare memory newProjectShare = SLib.ProjectShare({
            projectId:_projectId,
            share: _share
        });
        projectShareMap[tokenId] = newProjectShare;

        ownedTokensId[to].push(tokenId);
    }

    function getMetadataByTokenId(uint tokenId) public view returns (SLib.ProjectShare memory) {
        require(tokenId > 0 && tokenId < _tokenIdCounter.current(), "token Id not exist");
        return projectShareMap[tokenId];
    }

    function getOwnedToken(address _address) public view returns ( uint[] memory ){
        return ownedTokensId[_address];
    }

    function getAddressTokensWithMetadata (address _address) public view returns (SLib.ProjectShare[] memory)  {

        uint [] memory tokenIds = ownedTokensId[_address];
        SLib.ProjectShare [] memory results = new SLib.ProjectShare[](tokenIds.length);
        for(uint i = 0; i < tokenIds.length; i++){
            results[i] = projectShareMap[tokenIds[i]];
        }
        return results;
    }
    
}