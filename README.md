<img align="right" width="130" height="130" top="100" mt="" src="./assets/heth.svg">

# HETH • ![solidity](https://img.shields.io/badge/solidity-^0.8.15-lightgrey)

hETH — gas optimised WETH implementation in Huff. ⛽

## ❗ Important differences with the original WETH contract:
- All functions are **payable** to make the contract as gas-optimized as possible.
- *balanceOf(address)* is stored at storage slot **address**. E. g. if your address is 0x1234...., the slot with your balance is **0x1234...**. This optimizes the contract, as we don't have to calculate the mapping slot. Storage collisions are unlikely to happen.
- *allowance(address from, address to)* is stored at storage slot **keccak256(to . from)** where **.** is concatenation. That makes so we avoid using 2D mappings and calculate the hash only once. Storage collisions are unlikely to happen.

## 🔧 Test the contracts
1. Make sure you have the [Huff Compiler](https://docs.huff.sh/get-started/installing/) installed.
2. Then clone this repository, enter it and run:
```shell
forge install
```
This will install all the necessary dependencies.

3. When you're set, test the contracts by running:

```shell
forge test
```

*Note: use WSL if you're using Windows system.*


## Blueprint

```ml
lib/
├── forge-std — https://github.com/foundry-rs/forge-std
└── foundry-huff — https://github.com/huff-language/foundry-huff
script/
└── Deploy.s.sol — Deployment Script (not yet implemented)
src/
├── interfaces/
│   ├── IWETH.sol — WETH interface
│   └── IWETHEvents.sol — All of the events WETH contract emits
└── HuffWETH.huff — WETH implementation in Huff
test/
├── handlers/
│   └── Handler.sol — WETH handler for invariant testing
├── HuffWETH.t.sol — hETH unit tests
└── HuffWETHInvariant.t.sol — hETH invariant tests
```



## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._

## 𐤇