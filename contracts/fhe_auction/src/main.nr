struct EncryptedBid{

}

contract Main {
    use dep::std::option::Option;
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
    use dep::lwe::{encrypt_lwe, decrypt_lwe};

    struct Storage {
        // note this is compressing a bunch of bitwise u32s coming from encrypt_lwe() into a single field
        encrypted_bids: Map<PublicState<[Field; 8], 8>>,
        outcome: Field,
    }


    impl Storage {
        fn init(context: Context) -> pub Self {
            Storage {
                encrypted_bids: Map::new(
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

    #[aztec(private)]
    fn constructor() {}
    // fn encrypt_lwe<N, M>(a_samples: [u32; N], sk: [u32; N], e: u32, plaintext: u32) -> [u32; M] {

    // note M = N+1.  Right now amount should be a u8, but we leave as Field
    // so we can use the build in to_le_bit method
    #[aztec(private)]
    fn bid(amount: Field, 
        // fhe encrypt params below, ripped from the lwe signature
        a_samples: [u32; 6], sk: [u32; 6], e: u32, plaintext: u32 
    ) {
        // assert(amount < 2**8, "amount must be less than 2**8");
        // we are encrypting the bits individually
        let mut encrypted_bid: [Field; 8] = [0; 8];

        // only look at smaller 8 bits of the "amount" bid, and use that as the bid
        let bits: [u1; 8] = amount.to_le_bits(8);
        for i in 0..8 {
            let bit: u32 = bits[i] as u32;
            // are we supposed to change `a_samples` and/or `e` for each bit?
            let encrypted_bid_bit: [u32; 7] = encrypt_lwe(a_samples, sk, e, bit);
            encrypted_bid[i] = Field::bytes32_to_field(encrypted_bid_bit);
        }

    // public function call to write output
        let _void = context.call_public_function(
            context.this_address(), 
            compute_selector("postBid([Field; 8])"), 
            [encrypted_bid],
        );
        // postBid(encrypted_bid);
    }

    #[aztec(public)]
    pub fn postBid(encrypted_bid: [Field; 8]) {
        storage.encrypted_bids.at(AztecAddress::new(context.msg_sender())).write(encrypted_bid);
    }

}
