const FundRasingShareToken = artifacts.require('FundRasingShareToken')
const PlatformToken = artifacts.require('PlatformToken')
const ArtistMembers = artifacts.require('ArtistMembers')
const ArtProjects = artifacts.require('ArtProjects')
const MainGame = artifacts.require('MainGame')


module.exports = async function(deployer) {
  await deployer.deploy(FundRasingShareToken)
  await deployer.deploy(PlatformToken)
  await deployer.deploy(ArtistMembers)
  await deployer.deploy(ArtProjects)

  // address tokenAddress, address _artProjectsAddress, address _artistMembersAddress, address _fundRasingShareTokenAddress
  await deployer.deploy(MainGame, PlatformToken.address, ArtProjects.address, ArtistMembers.address, FundRasingShareToken.address)

  console.log("FundRasingShareToken", FundRasingShareToken.address)
  console.log("PlatformToken", PlatformToken.address)
  console.log("ArtistMembers", ArtistMembers.address)
  console.log("ArtProjects", ArtProjects.address)
  console.log("MainGame", MainGame.address)
} as Truffle.Migration

// because of https://stackoverflow.com/questions/40900791/cannot-redeclare-block-scoped-variable-in-unrelated-files
export {}