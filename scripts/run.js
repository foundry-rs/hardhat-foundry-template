const main = async () => {
  const [deployer] = await hre.ethers.getSigners();
  const accountBalance = await deployer.getBalance();

  console.log("Deploying contracts with account: ", deployer.address);
  console.log("Account balance: ", accountBalance.toString());

  const tokenManagerContractFactory = await hre.ethers.getContractFactory("TokenManagerETH");
  const tokenManagerContract = await tokenManagerContractFactory.deploy();
  await tokenManagerContract.deployed();

  console.log("TokenManager address: ", tokenManagerContract.address);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();