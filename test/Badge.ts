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
  let signer2: SignerWithAddress;

  const badgeName = "TwitterBadge";
  const badgeSymbol = "iTWITT";

  before(async function () {
    [admin, signer1, signer2] = await hre.ethers.getSigners();
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

  it("should let the admin pause", async () => {
    await badge.connect(admin).pause();

    expect(await badge.paused()).to.be.true;
  });

  it("should let the admin unpause", async () => {
    await badge.connect(admin).pause();

    await badge.connect(admin).unpause();

    expect(await badge.paused()).to.be.false;
  });

  it("should not let another signer pause", async () => {
    await expect(badge.connect(signer1).pause()).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("should let the admin mint a token", async () => {
    await badge.connect(admin).safeMint(signer1.address, 1);

    expect(await badge.balanceOf(signer1.address)).to.eq(1);
    expect(await badge.ownerOf(1)).to.eq(signer1.address);
  });

  it("should not let mint twice with the same id", async () => {
    const tokenId = 5555;
    await badge.connect(admin).safeMint(signer1.address, tokenId);

    expect(await badge.balanceOf(signer1.address)).to.eq(1);

    await expect(badge.connect(admin).safeMint(signer2.address, tokenId)).to.be.revertedWith(
      "ERC721: token already minted",
    );
  });

  it("should let tokens be burned by their owner", async () => {
    const tokenId = 5645324387978;
    await badge.connect(admin).safeMint(signer1.address, tokenId);

    expect(await badge.balanceOf(signer1.address)).to.eq(1);

    await badge.connect(signer1).burn(tokenId);

    expect(await badge.balanceOf(signer1.address)).to.eq(0);
  });

  it("should not let tokens be burned if not approved or owner", async () => {
    const tokenId = 3333;
    await badge.connect(admin).safeMint(signer1.address, tokenId);

    expect(await badge.balanceOf(signer1.address)).to.eq(1);

    await expect(badge.connect(signer2).burn(tokenId)).to.be.revertedWith(
      "ERC721Burnable: caller is not owner nor approved",
    );
    expect(await badge.balanceOf(signer1.address)).to.eq(1);
  });

  it("should let approved accounts burn tokens on behalf", async () => {
    const tokenId = 44;
    await badge.connect(admin).safeMint(signer1.address, tokenId);

    expect(await badge.balanceOf(signer1.address)).to.eq(1);

    await badge.connect(signer1).approve(signer2.address, tokenId);

    await expect(badge.connect(signer2).burn(tokenId)).to.not.be.reverted;
    expect(await badge.balanceOf(signer1.address)).to.eq(0);
  });

  it("should set the base URI", async () => {
    const baseURI = "https://interrep.link/tokens/";
    const tokenId = 1;

    await badge.connect(admin).changeBaseURI(baseURI);

    await badge.connect(admin).safeMint(signer1.address, tokenId);

    expect(await badge.tokenURI(1)).to.eq(baseURI + tokenId.toString());
  });

  it("should only let the admin change the base URI", async () => {
    await expect(badge.connect(signer1).changeBaseURI("https://opensea.io/")).to.be.revertedWith(
      "Ownable: caller is not the owner",
    );
  });

  it("should let token holder transfer their token", async () => {
    const tokenId = 6;
    await badge.connect(admin).safeMint(signer1.address, tokenId);

    await expect(() =>
      badge.connect(signer1)["safeTransferFrom(address,address,uint256)"](signer1.address, signer2.address, tokenId),
    ).to.changeTokenBalances(badge, [signer1, signer2], [-1, 1]);
  });

  it("should let approved accounts transfer", async () => {
    const tokenId = 77;
    await badge.connect(admin).safeMint(signer1.address, tokenId);

    await badge.connect(signer1).approve(signer2.address, tokenId);

    await badge.connect(signer2)["safeTransferFrom(address,address,uint256)"](signer1.address, admin.address, tokenId);

    expect(await badge.ownerOf(tokenId)).to.eq(admin.address);
  });

  it("should not let unapproved transfers happen", async () => {
    const tokenId = 77;
    await badge.connect(admin).safeMint(signer1.address, tokenId);

    await expect(
      badge.connect(signer2)["safeTransferFrom(address,address,uint256)"](signer1.address, signer2.address, tokenId),
    ).to.be.revertedWith("ERC721: transfer caller is not owner nor approved");
  });
});
