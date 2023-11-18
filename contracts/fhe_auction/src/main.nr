struct EncryptedBid{

}

contract Main {
    use dep::std::option::Option;
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        state_vars::{map::Map, public_state::PublicState},
        types::type_serialization::{
            field_serialization::{FieldSerializationMethods, FIELD_SERIALIZED_LEN},
            aztec_address_serialization::{AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
        }
    };
    use dep::lwe::{encrypt_lwe, decrypt_lwe};

    struct Storage {
        // bids: Map<PublicState<[u32; 10]>>,
        // note this is compressing a bunch of bitwise u32s into a single field
        encrypted_bids: Map<PublicState<[Field; 8]>>,
        outcome: Field,
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Storage {
                bids: Map::new(
                    context,
                    1,
                    |context, slot| {
                        PublicState::new(
                            context,
                            slot,
                            FieldSerializationMethods,
                        )
                    },
                ),
                outcome: PublicState::new(
                                    context,
                                    2,
                                    FieldSerializationMethods,
                                ),

            }
        }
    }

    // fn encrypt_lwe<N, M>(a_samples: [u32; N], sk: [u32; N], e: u32, plaintext: u32) -> [u32; M] {
    // note M = N+1.  Right now amount should be a u8, but we leave as Field
    // so we can use the build in to_le_bit method
    #[aztec(private)]
    fn bid(context: Context, storage: Storage, amount: Field, 
        // fhe encrypt params below, ripped from the lwe signature
        a_samples: [u32; 6], sk: [u32; 6], e: u32, plaintext: u32 
    ) {
        assert(amount < 2**8, "amount must be less than 2**8");
        let mut encrypted_bid: [u32; 7] = [0; 7];

        // we are encrypting the bits individually
        let bits = amount.to_le_bits(8);
        for i in 0..8 {
            let bit = bits[i]
            // should we generate a new e for each bit?
            let encrypted_bid_bit: [u32; 7] = encrypt_lwe(a_samples, sk, e, bit);
        }
        // let encrypted_bid: [u32; 11] = encrypt_lwe(a_samples, sk, e, amount);
        postBid(encrypted_bid);
    }

    #[aztec(public)]
    pub fn postBid(encrypted_bid: [Field, 8]) {
        storage.encrypted_bids.at(AztecAddress::new(context.msg_sender())).write(encrypted_bid);
    }

}
