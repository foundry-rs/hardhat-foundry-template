const main = async () => {
  const [deployer] = await hre.ethers.getSigners();
  const accountBalance = await deployer.getBalance();

  console.log("Deploying contracts with account: ", deployer.address);
  console.log("Account balance: ", accountBalance.toString());

  const creditContractFactory = await hre.ethers.getContractFactory("ETHCredit");
  const creditContract = await creditContractFactory.deploy();
  await creditContract.deployed();

  console.log("creditContractFactory address: ", creditContract.address);

  const credsContractFactory = await hre.ethers.getContractFactory("ECreds");
  const credsContract = await credsContractFactory.deploy();
  await credsContract.deployed();

  console.log("credsContractFactory address: ", credsContract.address);

  const tokenManagerContractFactory = await hre.ethers.getContractFactory("TokenManagerETH");
  const tokenManagerContract = await tokenManagerContractFactory.deploy(credsContract.address, creditContract.address);
  await tokenManagerContract.deployed();

  console.log("TokenManager address: ", tokenManagerContract.address);
}

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