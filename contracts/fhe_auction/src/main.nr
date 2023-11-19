use dep::aztec::types::type_serialization::TypeSerializationInterface;

global ENCRYPTED_BID_LENGTH = 4;
struct EncryptedBid{
    // note for this example the bid is stored as 4 elements, which represents the 4 bytes 
    bid: [Field; 4]
}

fn serialize_bid(encrypted_bid: EncryptedBid) -> [Field; ENCRYPTED_BID_LENGTH] {
    [
        encrypted_bid.bid[0],
        encrypted_bid.bid[1],
        encrypted_bid.bid[2],
        encrypted_bid.bid[3],
    ]
}

fn deseriliaze_bid(serialized_bid: [Field; ENCRYPTED_BID_LENGTH]) -> EncryptedBid {
    EncryptedBid {
        bid: [
            serialized_bid[0],
            serialized_bid[1],
            serialized_bid[2],
            serialized_bid[3],
        ]
    }
}

impl EncryptedBid {
    pub fn new(bid: [Field; ENCRYPTED_BID_LENGTH]) -> Self {
        EncryptedBid {
            bid: bid
        }
    }

    pub fn empty() -> Self {
        EncryptedBid {
            bid: [0, 0, 0, 0]
        }
    }

    pub fn serialize(self: Self) -> [Field; ENCRYPTED_BID_LENGTH] {
        serialize_bid(self)
    }

    pub fn deserialize(serialized_bid: [Field; ENCRYPTED_BID_LENGTH]) -> Self {
        deseriliaze_bid(serialized_bid)
    }
}

global EncryptedBidSerializationMethods = TypeSerializationInterface {
    serialize: serialize_bid,
    deserialize: deseriliaze_bid,
};




contract Auction {
    // Encrypted bid
    use crate::EncryptedBid;
    use crate::EncryptedBidSerializationMethods;
    use crate::ENCRYPTED_BID_LENGTH;
    
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
                    5,
                    EncryptedBidSerializationMethods,
                ),
                outcome: PublicState::new(
                    context,
                    9,
                    FieldSerializationMethods,
                ),
            }
        }
    }

    #[aztec(private)]
    fn constructor() {}
    // fn encrypt_lwe<N, M>(a_samples: [u32; N], sk: [u32; N], e: u32, plaintext: u32) -> [u32; M] {

    // note M = N+1.  Right now amount should be a u8, but we leave as Field
    // so we can use the build in to_le_bit method
    #[aztec(private)]
    fn bid(
        amount: Field,
        bidder: Field, // hack for demo can be 0 or 1
        // fhe encrypt params below, ripped from the lwe signature
        a_samples: [u32; 10], sk: [u32; 10], e: u32
    ) {
        // TODO: shift the amount by the error bits

        // assert(amount < 2**8, "amount must be less than 2**8");
        // we are encrypting the bits individually
        let mut encrypted_bits: [Field; ENCRYPTED_BID_LENGTH] = [0; ENCRYPTED_BID_LENGTH];

        let bits = amount.to_be_bits(ENCRYPTED_BID_LENGTH);
        for i in 0..ENCRYPTED_BID_LENGTH {
            let mut bit: u32 = bits[i] as u32;
            // Note, in our encryption scheme we do not actually use 0 or 1, we use 1 for falsey and 2 for truthy
            if bit == 0 {
                bit = 1;
            } else {
                bit = 2;
            };
            
            let message = ((bit as u64 << 32) / 3 as u64) as u32; 
            // are we supposed to change `a_samples` and/or `e` for each bit?
            // ans: yes, we loose security if we dont, however this is just a demonstration, samples of a and e can be fetched from the oracle
            let encryption: [u32; 11] = encrypt_lwe(a_samples, sk, e, message);
            encrypted_bits[i] = encryption[10] as Field;
        }

    // public function call to write output
        let _void = context.call_public_function(
            context.this_address(), 
            // compute_selector("postBid([Field; 4],Field)"), 
            1530848631,
            [encrypted_bits[0], encrypted_bits[1], encrypted_bits[2], encrypted_bits[3], bidder]
        );
        // postBid(encrypted_bid);
    }

    #[aztec(public)]
    pub internal fn postBid(encrypted_bid: [Field; ENCRYPTED_BID_LENGTH], bidder: Field) {
        let bidder_slot = if bidder == 0 { storage.bid_0 } else { storage.bid_1 };
        
        let bid = EncryptedBid::new(encrypted_bid);
        bidder_slot.write(bid);
    }

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
