mod encrypted_bid;

// ____ ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
//||F |||h |||e |||       |||A |||u |||c |||t |||i |||o |||n ||
//||__|||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
//|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|

// FHE Auction
//
// This is a demonstration of a fully homomorphic auction contract.
// Participants encrypt their bid into the fhe scheme
// 
// An FHE coprocessor determines the winner of the auction
// The winner's index is posted to the contract
// The winner can then privately claim their prize
contract Auction {
    // Encrypted bid
    use crate::encrypted_bid::EncryptedBid;
    use crate::encrypted_bid::EncryptedBidSerializationMethods;
    use crate::encrypted_bid::ENCRYPTED_BID_LENGTH;
    
    // stdlib
    use dep::std::option::Option;
    use dep::std::field;
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        state_vars::{map::Map, public_state::PublicState},
        types::address::{AztecAddress},
        types::type_serialization::{
            field_serialization::{FieldSerializationMethods, FIELD_SERIALIZED_LEN},
            aztec_address_serialization::{AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
        },
        selector::compute_selector,
    };
    
    // learning with errors encryption
    use dep::lwe::{encrypt_lwe, decrypt_lwe};
    use dep::aztec::oracle::debug_log::debug_log_field;

    // Constant determined by fhe scheme over boolean circuits
    global PLAINTEXT_MODULUS: u64 = 3;

    ///////////////////////////////////////////////////////////////
    //                  STORAGE DECLARATION                       /
    ///////////////////////////////////////////////////////////////
    struct Storage {
        // note this is compressing a bunch of bitwise u32s coming from encrypt_lwe() into a single field
        bid_0: PublicState<EncryptedBid, ENCRYPTED_BID_LENGTH>,
        bid_1: PublicState<EncryptedBid, ENCRYPTED_BID_LENGTH>,
        outcome: PublicState<Field, 1>,
    }

    impl Storage {
        fn init(context: Context) -> Self {
            Storage {
                bid_0: PublicState::new(
                    context,
                    1,
                    EncryptedBidSerializationMethods,
                ),
                bid_1: PublicState::new(
                    context,
                    1 + ENCRYPTED_BID_LENGTH as Field,
                    EncryptedBidSerializationMethods,
                ),
                outcome: PublicState::new(
                    context,
                    1 + ENCRYPTED_BID_LENGTH as Field * 2,
                    FieldSerializationMethods,
                ),
            }
        }
    }

    ///////////////////////////////////////////////////////////////
    //                      PRIVATE METHODS                      //
    ///////////////////////////////////////////////////////////////
    #[aztec(private)]
    fn constructor() {}
    // fn encrypt_lwe<N, M>(a_samples: [u32; N], sk: [u32; N], e: u32, plaintext: u32) -> [u32; M] {

    #[aztec(private)]
    fn bid(
        // The bid amount; only the least significant bits are used
        amount: Field,
        // The bidder
        bidder: Field, // hack for demo can be 0 or 1
        a_samples: [u32; 10], sk: [u32; 10], e: u32
    ) {
        let mut encrypted_bits: [Field; ENCRYPTED_BID_LENGTH] = [0; ENCRYPTED_BID_LENGTH];

        let bits = amount.to_be_bits(ENCRYPTED_BID_LENGTH);
        for i in 0..ENCRYPTED_BID_LENGTH {
            // Note, in our encryption scheme we do not actually use 0 or 1, we use 1 for falsey and 2 for truthy
            // We also shift the plaintext up to make room for the error
            let bit: u32 = if bits[i] == 0 { 1 } else { 2 };
            let message = ((bit as u64 << 32) / PLAINTEXT_MODULUS) as u32; 

            // Encrypt each bit with LWE
            let encryption: [u32; 11] = encrypt_lwe(a_samples, sk, e, message);
            encrypted_bits[i] = encryption[10] as Field;
        }

        // public function call to write output, TODO: interface wrapper for this
        let _void = context.call_public_function(
            context.this_address(), 
            // compute_selector("postBid([Field; 4],Field)"), 
            1530848631,
            [encrypted_bits[0], encrypted_bits[1], encrypted_bits[2], encrypted_bits[3], bidder]
        );
    }

    ///////////////////////////////////////////////////////////////
    //                      PUBLIC METHODS                       //
    ///////////////////////////////////////////////////////////////
    #[aztec(public)]
    pub internal fn postBid(encrypted_bid: [Field; ENCRYPTED_BID_LENGTH], bidder: Field) {
        let bidder_slot = if bidder == 0 { storage.bid_0 } else { storage.bid_1 };
        
        let bid = EncryptedBid::new(encrypted_bid);
        bidder_slot.write(bid);
    }


    ///////////////////////////////////////////////////////////////
    //                      VIEW METHODS                         //
    ///////////////////////////////////////////////////////////////
    unconstrained fn readBid0() -> [Field; ENCRYPTED_BID_LENGTH] {
        storage.bid_0.read().serialize()
    }

    unconstrained fn readBid1() -> [Field; ENCRYPTED_BID_LENGTH] {
        storage.bid_1.read().serialize()
    }

    unconstrained fn compute_note_hash_and_nullifier(_contract_address: Field, _nonce: Field, _storage_slot: Field, _serialized_note: [Field; 4]) -> [Field; 4] {
        [0, 0, 0, 0]
    }
}
