import {
    AztecAddress,
    AztecNode,
    CompleteAddress,
    EthAddress,
    ExtendedNote,
    Fr,
    GrumpkinScalar,
    Note,
    PXE,
    TxStatus,
    Wallet,
    computeMessageSecretHash,
    createPXEClient,
    getSandboxAccountsWallets,
    getUnsafeSchnorrAccount,
    retryUntil,
    waitForSandbox,
} from '@aztec/aztec.js';

import { jest } from '@jest/globals';
import { AuctionContract } from './types/Auction';

const { PXE_URL = 'http://localhost:8080', AZTEC_NODE_URL = 'http://localhost:8079' } = process.env;

const TIMEOUT = 60_000;

describe('auction', () => {
    jest.setTimeout(TIMEOUT);

    let aztecNode: AztecNode | undefined;
    let pxe: PXE;
    let walletA: Wallet;
    let walletB: Wallet;
    let userA: AztecAddress;
    let userB: AztecAddress;

    let auction: AuctionContract;

    beforeAll(async () => {
        pxe = createPXEClient(PXE_URL);

        console.log(`Waiting for PXE to be ready on ${PXE_URL}...`)
        await waitForSandbox(pxe);
    
        console.log(`PXE is ready on ${PXE_URL}!`);

        const accounts = await getSandboxAccountsWallets(pxe);
        walletA = accounts[0];
        walletB = accounts[1];
        userA = walletA.getCompleteAddress().address;
        userB = walletB.getCompleteAddress().address;
    }, 100_000);

    const awaitServerSynchronized = async (server: PXE) => {
        const isServerSynchronized = async () => {
            return await server.isGlobalStateSynchronized();
        };
        await retryUntil(isServerSynchronized, 'server sync', 10);
    };

    it('deploy', async () => {
        auction = await AuctionContract.deploy(walletA, 1000n, userA).send().deployed();
        console.log("Deployed auction contract at ", auction.address.toString());
    });
});
