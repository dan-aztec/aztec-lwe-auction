import {
    AztecAddress,
    AztecNode,
    PXE,
    Wallet,
    createPXEClient,
    getSandboxAccountsWallets,
    retryUntil,
    waitForSandbox,
} from '@aztec/aztec.js';
import {execSync} from "child_process";
import {readFileSync} from "fs";

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

    // Note in order to run this test you must run cargo install over at https://github.com/Maddiaa0/fhe-auction
    it('Perform auction', async () => {
        // TODO: reenable
        auction = await AuctionContract.deploy(walletA).send().deployed();
        console.log("Deployed auction contract at ", auction.address.toString());

        // We use a fixed a value to simplify debugging
        let fixed_a = [0,1,2,3,4,5,6,7,8,9];
        let fixed_error = 1;
        
        // Generate the fhe key we will use (written to fs)
        writeClientKey();
        const clientKey = await readClientKey();

        console.log("Client key: ", clientKey);
        console.log("sel: ", auction.methods.postBid.selector);

        // Use the fhe process to write the client key to the fs
        // The first user will bid with a bid of 1
        {
            const bid0 = 2;
            const bidder0Number = 0;
            console.log("Sending bid 0");
            auction.methods.bid(bid0, bidder0Number, fixed_a, clientKey, fixed_error).send();
            console.log("Sent bid 0");
        }

        // Bid for user 2
        {
            const bid1 = 1;
            const bidder0Number1 = 1;
            console.log("Sending bid 1");
            await auction.methods.bid(bid1, bidder0Number1, fixed_a, clientKey, fixed_error).send().wait();
            console.log("Sent bid 1");
        }

        // Get the encrypted bids from the public storage
        const [encryptedBid0, encryptedBid1] = await getEncryptedBidsFromPublicStorage(auction);
        console.log("Encrypted bid 0: ", encryptedBid0);
        console.log("Encrypted bid 1: ", encryptedBid1);

        // Run the FHE process to find the winner
        performFheAuction(encryptedBid0, encryptedBid1);

    });
});


async function getEncryptedBidsFromPublicStorage(auction: AuctionContract) {
    const bid0 = await auction.methods.readBid0().view();
    const bid1 = await auction.methods.readBid1().view();
    return [bid0, bid1];
}


async function performFheAuction(encryptedBid0: number[], encryptedBid1: number[]) {
    let all_bits: number[] = [];
    for (const bit of encryptedBid0) {
        all_bits.push(bit);
    }
    for (const bit of encryptedBid1) {
        all_bits.push(bit);
    }

    // -r = read the client key for decryption
    // -e = the encrypted bits
    // -l = the number of bits in each encrypted bid
    const command = `fhe-auctions -e ${all_bits.join(" -e ")} -l 4 -r`;
    const result = execSync(command);
    console.log(result);
}


function writeClientKey() {
    // run key-gen with the --store flag to write the key to the fs
    // it will be stored in ./store/client_key
    execSync("fhe-auctions key-gen -s");
}
async function readClientKey() {
    const filePath = "./store/client_key";
    const fileString = readFileSync(filePath, "utf8");
    const json = JSON.parse(fileString);
    return json.lwe_secret_key.data;
}