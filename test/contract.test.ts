import { expect } from "chai";
import { ethers } from "hardhat";

describe("Contract", function () {
  it("Should return true", async function () {
    const Contract = await ethers.getContractFactory("BasicContract");
    const contract = await Contract.deploy();
    await contract.deployed();

    expect(await contract.returnsTrue()).to.equal(true);
  });
});
