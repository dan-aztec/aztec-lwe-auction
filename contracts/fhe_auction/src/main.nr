contract Main {
    use dep::std::option::Option;
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        state_vars::{map::Map, public_state::PublicState},
        types::type_serialization::{
                        aztec_address_serialization::{AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
            }
    };
    use dep::lwe::{encrypt_lwe, decrypt_lwe};

    struct Storage {
        bids: Map<PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>>,
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
                            AztecAddressSerializationMethods,
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
    fn bid(context: Context, storage: Storage, amount: u32, 
        // fhe encrypt params below, ripped from the lwe signature
        a_samples: [u32; N], sk: [u32; N], e: u32, plaintext: u32 
    ) {
        let encrypted_bid = encrypt_lwe(a_samples, sk, e, amount);
        // storage.bids.at(AztecAddress::new(context.msg_sender())).write(encrypted_bid);
        postBid(encrypted_bid);

    }

    pub fn postBid(context: PublicContext, storage: Storage, encrypted_bid: u32) {
        storage.bids.at(AztecAddress::new(context.msg_sender())).write(encrypted_bid);
    }

}
