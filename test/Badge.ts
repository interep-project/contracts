import hre from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import { Badge } from "../typechain/Badge";
import { Badge__factory } from "../typechain";
import { expect } from "chai";

const { ethers } = hre;

describe("Badge", function () {
  let badge: Badge;
  let admin: SignerWithAddress;
  let signer1: SignerWithAddress;

  const badgeName = "TwitterBadge";
  const badgeSymbol = "iTWITT";

  before(async function () {
    [admin, signer1] = await hre.ethers.getSigners();
  });

  beforeEach(async function () {
    const BadgeFactory: Badge__factory = await ethers.getContractFactory("Badge");
    badge = await BadgeFactory.connect(admin).deploy(badgeName, badgeSymbol);
  });

  it("should return the badge name", async () => {
    expect(await badge.name()).to.eq(badgeName);
  });

  it("should return the badge symbol", async () => {
    expect(await badge.symbol()).to.eq(badgeSymbol);
  });

  it("should let the owner pause", async () => {
    await badge.connect(admin).pause();

    expect(await badge.paused()).to.be.true;
  });

  it("should let the owner unpause", async () => {
    await badge.connect(admin).pause();

    await badge.connect(admin).unpause();

    expect(await badge.paused()).to.be.false;
  });

  it("should not let another signer pause", async () => {
    await expect(badge.connect(signer1).pause()).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("should let the owner mint a token", async () => {
    await badge.connect(admin).safeMint(signer1.address, 1);

    expect(await badge.balanceOf(signer1.address)).to.eq(1);
    expect(await badge.ownerOf(1)).to.eq(signer1.address);
  });

  it("should set the base URI", async () => {
    const baseURI = "https://interrep.link/tokens/";
    const tokenId = 1;

    await badge.connect(admin).changeBaseURI(baseURI);

    await badge.connect(admin).safeMint(signer1.address, tokenId);

    expect(await badge.tokenURI(1)).to.eq(baseURI + tokenId.toString());
  });

  it("should only let the owner change the base URI", async () => {
    await expect(badge.connect(signer1).changeBaseURI("https://opensea.io/")).to.be.revertedWith(
      "Ownable: caller is not the owner",
    );
  });
});
