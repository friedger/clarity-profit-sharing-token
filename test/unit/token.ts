import { assert } from "chai";
import {
  Provider,
  ProviderRegistry,
  Client,
  Receipt,
} from "@blockstack/clarity";
import { FeeStructureClient } from "../../src/client/fee-structure";

const creator = "S1G2081040G2081040G2081040G208105NK8PE5";
const buyerAndReseller = "S02J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKPVKG2CE";
const partBuyer = "ST2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKQYAC0RQ";
class TokenProvider extends Client {
  constructor(provider: Provider) {
    super(
      "S1G2081040G2081040G2081040G208105NK8PE5.token",
      "token.clar",
      provider
    );
  }

  async createAsset(hash: String, value: Number) {
    const tx = this.createTransaction({
      method: {
        name: "create-asset",
        args: [`"${hash}"`, `u${value}`],
      },
    });
    tx.sign(creator);
    return this.submitTransaction(tx);
  }

  async eiBuying(hash: String, price: Number) {
    const tx = this.createTransaction({
      method: {
        name: "ei-buying",
        args: [`"${hash}"`, `u${price}`],
      },
    });
    tx.sign(buyerAndReseller);
    return this.submitTransaction(tx);
  }

  async sell(hash: String) {
    const tx = this.createTransaction({
      method: {
        name: "sell",
        args: [`"${hash}"`],
      },
    });
    tx.sign(creator);
    return this.submitTransaction(tx);
  }

  async eiPartBuying(hash: String, value: Number, price: Number) {
    const tx = this.createTransaction({
      method: {
        name: "ei-part-buying",
        args: [`"${hash}"`, `u${value}`, `u${price}`],
      },
    });
    tx.sign(partBuyer);
    return this.submitTransaction(tx);
  }

  async reSell(hash: String, valueAsBuf: String) {
    const tx = this.createTransaction({
      method: {
        name: "re-sell",
        args: [`"${hash}"`, `"${valueAsBuf}"`],
      },
    });
    tx.sign(buyerAndReseller);
    return this.submitTransaction(tx);
  }

  async getBalance(address: String) {
    const q = this.createQuery({
      method: {
        name: "get-balance",
        args: [`'${address}`],
      },
    });
    return this.submitQuery(q);
  }
}

describe("token contract test suite", () => {
  let provider: Provider;
  let client: TokenProvider;
  let feeStructureClient: FeeStructureClient;

  describe("syntax tests", () => {
    before(async () => {
      provider = await ProviderRegistry.createProvider();
      client = new TokenProvider(provider);
      new FeeStructureClient(provider).deployContract();
    });

    it("should have a valid syntax", async () => {
      await client.checkContract();
    });

    after(async () => {
      await provider.close();
    });
  });

  describe("flow of sale and re-sale", () => {
    const tokenHash = "12345678901234567890123456789012";

    before(async () => {
      provider = await ProviderRegistry.createProvider();
      client = new TokenProvider(provider);
      feeStructureClient = new FeeStructureClient(provider);
      await feeStructureClient.deployContract();
      await client.deployContract();
      await feeStructureClient.sellTo(creator);
      await feeStructureClient.sellTo(buyerAndReseller);
      await feeStructureClient.sellTo(partBuyer);
    });

    it("should create an asset", async () => {
      const response = await client.createAsset(tokenHash, 100);
      assert(response.success, `failed with ${JSON.stringify(response)}`);
    });

    it("should create a call", async () => {
      const response = await client.eiBuying(tokenHash, 2000);
      assert(response.success, `failed with ${JSON.stringify(response)}`);
    });

    it("should sell", async () => {
      const response = await client.sell(tokenHash);
      assert(response.success, `failed with ${JSON.stringify(response)}`);
    });

    it("should create a call for a value part", async () => {
      const response = await client.eiPartBuying(tokenHash, 50, 1500);
      assert(response.success, `failed with ${JSON.stringify(response)}`);
    });

    it("should re-sell", async () => {
      const response = await client.reSell(tokenHash, "50");
      assert(response.success, `failed with ${JSON.stringify(response)}`);
    });

    it("should send profit to original owner", async () => {
      const creatorResponse = await client.getBalance(creator);
      var buyerAndResellerResponse = await client.getBalance(buyerAndReseller);
      var partBuyerResponse = await client.getBalance(partBuyer);
      var response = await feeStructureClient.getBalance();
      assert(
        creatorResponse.result === "u2250",
        JSON.stringify(creatorResponse)
      );
      assert(
        buyerAndResellerResponse.result === "u1250",
        JSON.stringify(buyerAndResellerResponse)
      );
      assert(
        partBuyerResponse.result === "u0",
        JSON.stringify(partBuyerResponse)
      );
      assert(response.result === "u575", JSON.stringify(response)); // 100 + 200 + 100 + 75 + 100
    });
    after(async () => {
      await provider.close();
    });
  });
});
