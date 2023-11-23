
use dep::aztec::types::type_serialization::TypeSerializationInterface;

global ENCRYPTED_BID_LENGTH = 8;
struct EncryptedBid{
    // note for this example the bid is stored as 4 elements, which represents the 4 bytes 
    bid: [Field; ENCRYPTED_BID_LENGTH]
}

fn serialize_bid(encrypted_bid: EncryptedBid) -> [Field; ENCRYPTED_BID_LENGTH] {
    // slices get optimized away
    let mut ret = [0; ENCRYPTED_BID_LENGTH];
    for i in 0..ENCRYPTED_BID_LENGTH {
        ret[i] = encrypted_bid.bid[i];
    }
    ret
}

fn deseriliaze_bid(serialized_bid: [Field; ENCRYPTED_BID_LENGTH]) -> EncryptedBid {
    EncryptedBid {
        bid: [
            serialized_bid[0],
            serialized_bid[1],
            serialized_bid[2],
            serialized_bid[3],
            serialized_bid[4],
            serialized_bid[5],
            serialized_bid[6],
            serialized_bid[7],
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
            bid: [0; ENCRYPTED_BID_LENGTH]
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
