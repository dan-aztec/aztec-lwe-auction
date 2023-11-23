<img align="right" width="150" height="150" top="100" src="./assets/readme.png">

# Aztec x FHE Auction

## What is this?

Aztec is a privacy first fully programmable permission-less execution environment. Each user of Aztec owns their own state; it is encrypted.

Aztec gets it programmability by leveraging Zero Knowledge Proofs, this allows users to make claims about encrypted state, however to make claims about other user's encrypted state is another matter. This is where we can leverage Fully Homomorphic Encryption ( FHE ).

This repo contains the Aztec Contracts required to create a fully private auction. There is an `auction.test.ts` file that contains the 

This project was created by in the DevConnect co-working space in Istanbul and is not in anyway shape or form ready for production use.


## Caveats
- A real world implementation of would have the FHE Oracle part as its own service, for demo purposes we are just using a cli.
- There would also be a distributed key gen process to create the FHE keys, we just generate them here ( there are many unanswered questions ).
- In this implementation our encryption and decryption blowup constants are terrible and are NOT secure in any way shape or form ( this is a proof of concept ).

## Blueprint

```ml
├── contracts                   // Noir contracts
│   ├── fhe_auction
│   │   ├── Nargo.toml
│   │   ├── src
│   │   │   ├── encrypted_bid.nr
│   │   │   └── main.nr
├── src                         // Test
│   ├── auction.test.ts
│   └── types
│       └── Auction.ts
├── package.json
├── tsconfig.json
└── yarn.lock
```

## Development

**Setup**
Installation instructions for external tooling can be found below in the "First time" sections.  

You will need to install the FHE auction client ( it is just called in a subprocess by the tests ).  

run `cargo install --path .` in from this repo https://github.com/Maddiaa0/fhe-auction  

```
yarn
```


**Building**

```bash
yarn build
```

**Testing**

In one terminal run anvil:
```
anvil
```

In another run the aztec sandbox
```bash
yarn start:sandbox
```

Then finally;
```bash
yarn test
```

### First time with Noir?

See the official Noir installation [instructions](https://noir-lang.org/getting_started/nargo_installation).

Then, install the [Noir](https://github.com/noir-lang/noir) toolchain installer (`noirup`) with:

```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
```

Now that you've installed the `noirup` binary,

So, simply execute:

```bash
noirup
```

🎉 Noir is installed! 🎉

### First time with the Aztec Sandbox?

You'll need to install the `aztec-cli`!

See the official installation [instructions](https://docs.aztec.network/dev_docs/cli/sandbox-reference#with-npm) if you get stuck, but its super easy!

```
npm i -g @aztec/aztec-sandbox @aztec/aztec-cli
```

This should do the trick!  

🎉 Aztec-cli and sandbox is installed! 🎉

You can run the anvil in docker by following the instructions linked above; however i often prefer running it locally.

### First time with Anvil?

See the official Foundry installation [instructions](https://github.com/foundry-rs/foundry/blob/master/README.md#installation).

Then, install the [foundry](https://github.com/foundry-rs/foundry) toolchain installer (`foundryup`) with:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Now that you've installed the `foundryup` binary,
anytime you need to get the latest `forge` or `cast` binaries,
you can run `foundryup`.

So, simply execute:

```bash
foundryup
```

🎉 Foundry is installed! 🎉

## Acknowledgements

- [femplate](https://github.com/refcell/femplate)
- [aztec](https://github.com/AztecProtocol/aztec-packages)
- [noir](https://github.com/noir-lang/noir)
- [zama-tfhe](https://github.com/zama-ai/tfhe-rs)

## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._