const NFT = artifacts.require("ERC721Full");

module.exports = function (deployer) {
  deployer.deploy(NFT, "CryptoBandits", "CBS");
};
