// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./slib.sol";
import "./fundRasingShareToken.sol";
import "./platformToken.sol";

contract ArtistMembers is Ownable{

    mapping(address => bool) private artistExist; //check projectId return bool
    mapping(address => uint) private artistIdIndex; //check projectId return bool
    SLib.Artist[] private artistList;
    uint private artistCount;

    modifier isArtistIdExist(uint id) {
        require(id > 0 && id <= artistCount, "artist Id must less than artistCount");
        _;
    }

    modifier isArtistAddressExist(address _address) {
        require(artistExist[_address], "artist Id must less than artistCount");
        _;
    }

    event ArtistAdd(address indexed artistAddress);

    constructor (){
        artistCount = 0;
    }

    function addArtist (address _address, string memory _name, string memory _iconURL) external  returns (SLib.Artist memory artist){
        require(!artistExist[_address], "Caller is artist already");
        artistCount ++;
        artistExist[_address] = true;
        SLib.Artist memory newArtist = SLib.Artist({
            id:artistCount,
            artistAddress:_address,
            name:_name,
            iconURL:_iconURL
        });
        artistList.push(newArtist);
        artistIdIndex[_address] = artistCount - 1;

        // omit event

        return newArtist;
    }

    function checkIsArtistExist(address _address) public view returns (bool) {
        return artistExist[_address];
    }

    function getArtistSize() public view returns (uint) {
        return artistCount;
    }

    function getArtistById(uint id) isArtistIdExist(id) public view returns (SLib.Artist memory artist){
        return artistList[id - 1];
    }

    function getArtistByAddress(address _address) isArtistAddressExist(_address) public view returns (SLib.Artist memory artist){
        uint artistIndex = artistIdIndex[_address];
        return artistList[artistIndex];
    }
}



contract ArtProjects is Ownable{

    mapping(uint => bool) private projectExist; //check projectId return bool
    SLib.Project[] private projectList;
    uint private projectCount = 0;
    mapping(address => uint[]) artistProjectList;

    // projectId -> investor address -> invest amount
    mapping(uint => mapping(address => uint)) projectAddressFundAmount;
    mapping(uint => address[] ) projectFunderList;
    mapping(address => uint[]) investerFundedProjectList;
    mapping(uint => mapping(address => bool)) projectShareNFTClaimed;

    modifier isProjectIdExist(uint id) {
        require(id > 0 && id <= projectCount, "project Id must less than projectCount");
        _;
    }

    constructor(){

    }

    function addProject(address _artistAddress, string memory _name, string memory _description, uint _targetFundingAmount) external {
        
        projectCount ++;
        SLib.Project memory newProject = SLib.Project({
            id:projectCount,
            artistAddress: _artistAddress,
            name:_name,
            description:_description,
            targetFundingAmount:_targetFundingAmount,
            currentFundingAmount: 0,
            totalFunder:0,
            isOpen:true,
            dataURL:""
        });
        projectList.push(newProject);
        artistProjectList[_artistAddress].push(newProject.id);
        projectExist[projectCount] = true;
    }

    function addFunderAmount(uint projectId, address _investorAddress, uint amount) isProjectIdExist(projectId) external {
        SLib.Project storage project = projectList[projectId - 1];

        // block if not open
        require(project.isOpen, "Project fund rasing is closed") ;

        project.currentFundingAmount += amount;

        // add new investor record
        if(projectAddressFundAmount[projectId][_investorAddress] == 0){
            // if no invest record, add to project list/ investor list
            project.totalFunder += 1; //add a new funder
            projectFunderList[projectId].push(_investorAddress);
            investerFundedProjectList[_investorAddress].push(projectId);
        }
        // add fund amount
        projectAddressFundAmount[projectId][_investorAddress] += amount;
    }

    function endProject(address _address, uint projectId, string memory dataURL)isProjectIdExist(projectId) external {
        SLib.Project storage project = projectList[projectId - 1];
        require(project.isOpen, "Project fund rasing is closed") ;
        require(project.artistAddress == _address, "Only project owner can close") ;
        project.isOpen = false;
        project.dataURL = dataURL;
    }

    function checkIsAddressAbleToMint(uint projectId, address _address) isProjectIdExist(projectId) public view  returns (bool){
        SLib.Project memory project = getProjectById(projectId);
        uint fundAmount = projectAddressFundAmount[projectId][_address];
        if(fundAmount <= 0){
            return false;
        }
        if(project.isOpen){
            return false;
        }
        if(projectShareNFTClaimed[projectId][_address]){
            return false;
        }
        return true;
    }

    function getAddressShareInProject(uint projectId, address _address) isProjectIdExist(projectId) public view  returns (uint){
        SLib.Project memory project = getProjectById(projectId);
        uint fundAmount = projectAddressFundAmount[projectId][_address];
        if(fundAmount <= 0){
            return 0;
        }
        uint share = fundAmount / project.currentFundingAmount;
        return share;
    }

    function setProjectShareNFTClaimed (uint projectId, address _address) isProjectIdExist(projectId) public {
        require(checkIsAddressAbleToMint(projectId, _address), "Address Not able to claim share NFT");
        projectShareNFTClaimed[projectId][_address] = true;
    }

    function getProjectFunderListByProjectId (uint projectId) isProjectIdExist(projectId) public view returns (address [] memory){
        return projectFunderList[projectId];
    }

    function getFundedProjectByAddress (address _address)public view returns (uint [] memory){
        return investerFundedProjectList[_address];
    }

    function getFundAmountsByProjectId (uint projectId)isProjectIdExist(projectId) public view returns (SLib.ProjectAddressFund [] memory) {
        address [] memory funderList = projectFunderList[projectId];
        SLib.ProjectAddressFund [] memory results = new SLib.ProjectAddressFund[](funderList.length);
        for(uint i = 0; i < funderList.length; i++){
            uint fundAmount = projectAddressFundAmount[projectId][ funderList[i] ];
            results[i] = SLib.ProjectAddressFund({
                funderAddress: funderList[i],
                amount:fundAmount
            });
        }
        return results;
    }

    function getAllProjects ()public view returns (SLib.Project [] memory){
        return projectList;
    }

    function checkIsProjectExist(uint id) public view returns (bool) {
        return projectExist[id];
    }

    function getProjectSize() public view returns (uint) {
        return projectCount;
    }

    function getProjectById(uint id) isProjectIdExist(id) public view returns (SLib.Project memory project){
        return projectList[id - 1];
    }
}


contract MainGame is Ownable{

    ArtProjects artProjects;
    ArtistMembers artistMembers;
    PlatformToken platformToken;
    FundRasingShareToken fundRasingShareToken;

    constructor(address tokenAddress, address _artProjectsAddress, address _artistMembersAddress, address _fundRasingShareTokenAddress){
        artProjects = ArtProjects(_artProjectsAddress);
        artistMembers = ArtistMembers(_artistMembersAddress);
        platformToken = PlatformToken(tokenAddress);
        fundRasingShareToken = FundRasingShareToken(_fundRasingShareTokenAddress);
    }

    function registerAsArtist(string memory _name, string memory _iconURL) public {
        artistMembers.addArtist(msg.sender, _name, _iconURL);
        // address _address, string memory _name, string memory _iconURL
    }

    function kickStartProject(string memory _name, string memory _description, uint _targetFundingAmount) public{
        require(artistMembers.checkIsArtistExist(msg.sender));
        // address _artistAddress, string memory _name, string memory _description, uint _targetFundingAmount
        artProjects.addProject(msg.sender, _name, _description, _targetFundingAmount);
    }

    function addFundToProject (uint projectId, uint amount) public {
        artProjects.addFunderAmount(projectId, msg.sender, amount);
        // address sender,
        // address recipient,
        // uint256 amount
        platformToken.transferFrom (msg.sender, address(this), amount);
    }

    function endProject (uint projectId, string memory dataURL) public {
        artProjects.endProject(msg.sender, projectId, dataURL);
    }

    function claimProjectShareNFT(uint projectId) public{
        artProjects.setProjectShareNFTClaimed(projectId, msg.sender);
        uint share = artProjects.getAddressShareInProject(projectId, msg.sender);
        fundRasingShareToken.safeMintProjectShareNFT(msg.sender, projectId, share);
    }


}
