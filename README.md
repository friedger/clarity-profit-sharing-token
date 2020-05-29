# Profit-Sharing Token

![Token](images/token.png)

## Description

Profit-sharing token (`pst`) as defined in contract [`token.clar`](contracts/token.clar) is a non-fungible token that represents some dividable value into a number of given parts. The token can be transferred for a price. The price is proposed by a buyer when expressing interest of buying (i.e. creating a call). Then the owner can sell the token to the buyer. When the new owner is re-selling parts of the token the profit will be shared with the previous owner.

Price of tokens or parts of a token, as well as the profit is represented in the contract through the fungible token `usdt`. The token is minted when creating a call. The amount of tokens show how much many was generated through the sale of the profit-sharing token.

The contract currently only supports the flow of creating a token, selling it and re-selling it. Limitations are that

- the new owner can't sell the whole token
- the new owner can sell parts of a token only once (per token)

Each function call of the `token` contract comes with a fee that is taken by the platform maintainers. Fees are paid in `holdng` tokens, these tokens are sold by the platform maintainers. Creating and selling tokens costs a fixed fee, while creating a call costs a variable fee depending on price and value parts.
The functions to sell tokens and to pay fees are described in contract [`fee-structure`](contracts/fee-structure.clar). The functions are called by the `token` contract.

## Testing

Tests include unit tests for a flow of creating a token of 100 value parts, selling it at $2000 and reselling 50 value parts at $1500.

```
yarn
yarn test
```

At the end

- the creator has \$2250 and no token.
- the buyer/esller has \$1250 and the original token with 50 value parts of 100.
- the value part buyer has \$0 and new token with 50 value parts of 50.
- the platform earned 575 hodlng in fees.

## Application

The contract was developed with the liquid natural gas (LNG) trade market in mind. The concept for these contracts was developed in a project by [HODLNG](http://www.hodl.ng/) to build a more secure, more flexible, fair, transparent and balanced LNG trade system.

A `pst` token represents a cargo ship loaded with gas that an exporter sells to an importer. The importer, however, sometimes redirects the ship and sells parts of the gas to another country at a better price without participation of the exporter. With the token contract the process is transparent and profit sharing is built-in.

Note, that the incentives to participate in the platform, the platform management and other details are not represented here. Furthermore, the fee structure is given only exemplary.

## Support

[Hodlng](http://www.hodl.ng) is supporting the development of this smart contract.
