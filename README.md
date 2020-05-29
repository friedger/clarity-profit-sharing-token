# Profit-Sharing Token

## Description

Profit-sharing token is a non-fungible token that represents some value and can be transferred for a price. The price is determined by the owner, however, profits from reselling a token are shared with the previous owner.

## Testing

Tests include unit test for a flow of creating a token of 100 value parts, selling it at $2000 and reselling 50 value parts at $1500.

```
yarn
yarn test
```

At the end

- the creator has \$2250 and no token.
- the buyer/esller has \$1250 and the original token with 50 value parts of 100.
- the value part buyer has \$0 and new token with 50 value parts of 50.
- the platform earned 575 hodlng in fees.

## Support

[Hodlng](http://www.hodl.ng) is supporting the development of this smart contract.

![Token](images/token.png)
