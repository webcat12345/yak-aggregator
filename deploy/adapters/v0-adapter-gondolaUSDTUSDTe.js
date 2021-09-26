const { ethers } = require("hardhat");
const { expect } = require("chai");

async function checkTokenCountValidity(poolAddress, expectedTknCount) {
	let curvelikePool = await ethers.getContractAt('ICurveLikePool', poolAddress)
	try {
		// Check that max of expected-token-count is valid
		await expect(curvelikePool.getToken(expectedTknCount-1)).to.not.reverted
		// Check that there are not tokens after the expected-token-count
		await expect(curvelikePool.getToken(expectedTknCount)).to.reverted
	} catch (e) {
		throw new Error(`Invalid token-count for pool ${poolAddress}`)
	}
}

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    const NAME = 'GondolaUSDTUSDTeYakAdapterV0';
    const POOL = '0xAE5a60BB105e38A4986017A711c6A6CC1D1a0f36';  // Gondola USDT-USDT.e pool
    const GAS_ESTIMATE = 280000

    log(NAME)
    const deployResult = await deploy(NAME, {
      from: deployer,
      contract: "CurveLikeAdapter",
      gas: 4000000,
      args: [
          NAME,
          POOL, 
          GAS_ESTIMATE
      ],
      skipIfAlreadyDeployed: true
    });
  
    if (deployResult.newlyDeployed) {
      log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
    } else {
      log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
    }
  };

  module.exports.tags = ['V0', 'adapter', 'gondolaUSDTUSDTe'];