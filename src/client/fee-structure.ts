import { Client, Provider } from "@blockstack/clarity";

export class FeeStructureClient extends Client {
  constructor(provider: Provider) {
    super(
      "S1G2081040G2081040G2081040G208105NK8PE5.fee-structure",
      "fee-structure.clar",
      provider
    );
  }

  async sellTo(address: String) {
    const tx = this.createTransaction({
      method: {
        name: "sell",
        args: [`'${address}`],
      },
    });
    tx.sign("S1G2081040G2081040G2081040G208105NK8PE5");
    return this.submitTransaction(tx);
  }

  async getBalance() {
    const q = this.createQuery({
      method: {
        name: "get-balance",
        args: [],
      },
    });
    return this.submitQuery(q);
  }
}
