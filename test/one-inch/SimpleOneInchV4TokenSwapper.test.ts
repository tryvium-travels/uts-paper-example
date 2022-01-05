import { expect, use } from "chai";
import hre, { ethers, waffle } from "hardhat";

import {
    OneInchV4RouterMock,
    SimpleOneInchV4TokenSwapper,
    ERC20,
} from "@/typechain";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, Wallet } from "ethers";

const { utils } = ethers;
const { provider: mock_provider, solidity } = waffle;

use(solidity);

describe("dex-implementations/one-inch/SimpleOneInchV4TokenSwapper tests", () => {
    const max_supply = utils.parseEther("1000000000");

    const [
        test_wallet,
        wallet2,
    ] = mock_provider.getWallets();

    let test_swap_token_base: ERC20;
    let test_swap_token_quote: ERC20;

    const real_one_inch_router_eth_address = "0x11111112542D85B3EF69AE05771c2dCCff4fAa26";
    let one_inch_router_mock: OneInchV4RouterMock;
    let mocked_dex_swapper: SimpleOneInchV4TokenSwapper;
    let real_dex_swapper: SimpleOneInchV4TokenSwapper;

    const usdt_eth_address = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
    const usdc_eth_address = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

    let usdt_eth_token: ERC20;
    let usdc_eth_token: ERC20;

    before(async () => {
        // impersonating the 0xdead address to be sure it has the tokens to swap in the tests.
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0x000000000000000000000000000000000000dEaD"],
        });

        const test_token_factory = await ethers.getContractFactory("TestToken");
        const dex_swapper_factory = await ethers.getContractFactory("SimpleOneInchV4TokenSwapper");
        const ERC20_factory = await ethers.getContractFactory("ERC20");

        test_swap_token_base = await test_token_factory.deploy(
            max_supply,
        );

        test_swap_token_quote = await test_token_factory.deploy(
            max_supply,
        );

        usdt_eth_token = ERC20_factory.attach(usdt_eth_address);
        usdc_eth_token = ERC20_factory.attach(usdc_eth_address);

        real_dex_swapper = await dex_swapper_factory.deploy(
            real_one_inch_router_eth_address,
            usdt_eth_token.address,
        );
    });

    beforeEach(async () => {
        const one_inch_router_mock_factory = await ethers.getContractFactory("OneInchV4RouterMock");
        const dex_swapper_factory = await ethers.getContractFactory("SimpleOneInchV4TokenSwapper");

        one_inch_router_mock = await one_inch_router_mock_factory.deploy(
            test_swap_token_base.address,
            test_swap_token_quote.address,
            1,
        );

        mocked_dex_swapper = await dex_swapper_factory.deploy(
            one_inch_router_mock.address,
            test_swap_token_quote.address
        );

        await test_swap_token_base.transfer(one_inch_router_mock.address, utils.parseEther("1000"));
        await test_swap_token_quote.transfer(one_inch_router_mock.address, utils.parseEther("1000"));
    });

    it("(Mocked 1Inch Router) Should swap correctly the test tokens when not paused", async () => {
        await test_swap(test_wallet, mocked_dex_swapper, test_swap_token_base, test_swap_token_quote);
    });

    it("(Real 1Inch Router) Should swap correctly the test tokens when not paused", async () => {
        const wallet_0xdead = await ethers.getSigner("0x000000000000000000000000000000000000dEaD");
        await test_swap(wallet_0xdead, real_dex_swapper, usdc_eth_token, usdt_eth_token, true);
    });

    it("Should fail to swap the test tokens when paused", async () => {
        let tx = await mocked_dex_swapper.pause();
        await tx.wait();
        expect(await mocked_dex_swapper.paused(), "Must be paused after pause()").to.be.true;

        await expect(test_swap(test_wallet, mocked_dex_swapper, test_swap_token_base, test_swap_token_quote)).to.be.revertedWith("Pausable: paused");
    });

    it("Should not fail to swap when from paused state goes unpaused again", async () => {
        expect(await mocked_dex_swapper.paused(), "Must be working when not paused").to.be.false;

        let tx = await mocked_dex_swapper.pause();
        await tx.wait();
        expect(await mocked_dex_swapper.paused(), "Must be paused after pause()").to.be.true;

        tx = await mocked_dex_swapper.unpause();
        await tx.wait();
        expect(await mocked_dex_swapper.paused(), "Must be working again after unpause()").to.be.false;

        await test_swap(test_wallet, mocked_dex_swapper, test_swap_token_base, test_swap_token_quote);
    });

    async function test_swap(
        wallet: Wallet | SignerWithAddress,
        dex_swapper: SimpleOneInchV4TokenSwapper,
        token_base: ERC20,
        token_quote: ERC20,
        data_from_api: boolean = false,
    ) {
        const base_decimals = await token_base.decimals();
        const quote_decimals = await token_base.decimals();

        const test_amount_base = utils.parseUnits("10", base_decimals);
        const test_amount_quote = utils.parseUnits("10", quote_decimals);

        let swap_data;
        if (data_from_api) {
            swap_data = "0x2e95b6c8000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000000000000000098968000000000000000000000000000000000000000000000000000000000009704060000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000100000000000000003b6d03403041cbd36888becc7bbcbc0045e3b1f144466f5f";
        } else {
            swap_data = one_inch_router_mock.interface.encodeFunctionData(
                "swap",
                [
                    dex_swapper.address,
                    {
                        srcToken: token_base.address,
                        dstToken: token_quote.address,
                        srcReceiver: dex_swapper.address,
                        dstReceiver: dex_swapper.address,
                        amount: test_amount_base,
                        minReturnAmount: test_amount_quote,
                        flags: "0",
                        permit: utils.formatBytes32String("test"),
                    },
                    utils.formatBytes32String("test"),
                ],
            );
        }

        const before_balance_base_token : BigNumber = await token_base.balanceOf(wallet.address);
        const before_balance_quote_token : BigNumber = await token_quote.balanceOf(wallet.address);

        const token_base_for_wallet = token_base.connect(wallet);
        let tx = await token_base_for_wallet.approve(dex_swapper.address, test_amount_base);
        await tx.wait();

        const dex_swapper_for_wallet = await dex_swapper.connect(wallet);

        tx = await dex_swapper_for_wallet.swap(swap_data);
        await tx.wait();

        const after_balance_base_token : BigNumber = await token_base.balanceOf(wallet.address);
        const after_balance_quote_token : BigNumber = await token_quote.balanceOf(wallet.address);

        expect(after_balance_base_token.add(test_amount_base).eq(before_balance_base_token), "Must have less base tokens after the swap");
        expect(after_balance_quote_token.sub(test_amount_quote).eq(before_balance_quote_token), "Must have more quote tokens after the swap");

        const dex_swapper_quote_balance = await token_quote.balanceOf(dex_swapper.address);
        expect(dex_swapper_quote_balance.gt("0"), "The swapper contract must keep the change from the swap");
    }
});