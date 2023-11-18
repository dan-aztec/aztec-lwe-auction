contract Main {
    use dep::std::option::Option;
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        state_vars::{map::Map, public_state::PublicState, set::Set},
    };
    use dep::lwe::{encrypt_lwe, decrypt_lwe};

    struct Storage {
        bid1: Field,
        bid2: Field,
        outcome: Field,
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Storage {
                bid1: PublicState::new(
                    context,
                    1,
                    FieldSerializationMethods,
                ),
                bid2: PublicState::new(
                                    context,
                                    2,
                                    FieldSerializationMethods,
                                ),
                outcome: PublicState::new(
                                    context,
                                    3,
                                    FieldSerializationMethods,
                                ),

            }
        }
    }
    // fn encrypt_lwe<N, M>(a_samples: [u32; N], sk: [u32; N], e: u32, plaintext: u32) -> [u32; M] {
    fn bid1(context: Context, storage: Storage, amount: Field) -> pub () {
        storage.bid1.set(context, bid1);
    }

}
