import 'package:any_base/any_base.dart';
import 'package:oasis_coin/util/util.dart';
import 'package:oasis_coin/wallet/transaction.dart';

// Mine rate: expressed in millisecond, is an approximation of the time a miner should
// invest in mining a new block
const double MINE_RATE = 5 * 1000;
const int SHA_BYTE_LENGTH = 256;

/*
Block class
The block is the fundamental structure of the blockchain.
The Block class is responsible for the organizing of the data stored chronologically
in the blockchain.
 */
class Block {
  // Block properties

  // timestamp given by DateTime.now().millisecondSinceEpoch() (1970)
  final int timestamp;
  // hash of the previous block
  final String lastHash;
  // hash of block.toJson()
  final String hash;
  // list of transaction recorded in the block
  final List<Transaction> transactions;
  // nonce alias number only used once (used for PoW brute-forcing)
  final int nonce;
  // number of leading zeros to look for (used for PoW brute-forcing)
  final int difficulty;

  // Block constructor: sets local class variables
  const Block(int timestamp, String lastHash, String hash, List<Transaction> transactions, int nonce, int difficulty)
      : timestamp = timestamp,
        lastHash = lastHash,
        hash = hash,
        transactions = transactions,
        nonce = nonce,
        difficulty = difficulty;

  // Block.toJson(): exports a String representation of the block and the transactions
  String toJson({bool includeHash = true}) {
    if (includeHash) {
      return '{ "timestamp": ${this.timestamp}, "lastHash": "${this.lastHash}", "hash": "${this.hash}", "transactions": ${Transaction.listToJson(this.transactions)}, "nonce": ${this.nonce}, "difficulty": ${this.difficulty} }';
    }
    return '{ "timestamp": ${this.timestamp}, "lastHash": "${this.lastHash}", "transactions": ${Transaction.listToJson(this.transactions)}, "nonce": ${this.nonce}, "difficulty": ${this.difficulty} }';
  }

  // Block.fromMap(): return a Block object (including transaction list) from a given map previously json
  static Block fromMap(Map blockMap) {
    return new Block(
        blockMap["timestamp"],
        blockMap["lastHash"],
        blockMap["hash"],
        Transaction.listFromMap(blockMap["transactions"]),
        blockMap["nonce"],
        blockMap["difficulty"]);
  }

  // Block.genesis(): return the Block object for the genesis Block
  static Block genesis() {
    return Block(0, "0", "0", [], 0, 1);
  }

  // Block.mine(): return a Block object, Non-optimized mine algorithm with PoW
  static Block mine(Block lastBlock, List<Transaction> transactions) {
    String hash;
    String binaryHash;
    // String to compare to when checking for leading zeros
    String zeros = "".padLeft(lastBlock.difficulty, "0");

    // incrementing nonce
    int nonce = 0;
    // number of leading zeros to look for
    int difficulty = lastBlock.difficulty;
    int timestamp;

    do {
      nonce++;
      // update difficulty and timestamp to keep the block valid
      timestamp = DateTime.now().millisecondsSinceEpoch;
      difficulty = adjustDifficulty(lastBlock, timestamp);

      zeros = "".padLeft(difficulty, "0");
      // compute the hash of the given parameters
      hash = sha512(Block(timestamp, lastBlock.hash, "", transactions, nonce, difficulty).toJson(includeHash: false));

      // convert hash to binary representation to have more accurate difficulty control
      binaryHash = AnyBase(AnyBase.hex, AnyBase.bin).convert(hash);
      binaryHash = binaryHash.padLeft(SHA_BYTE_LENGTH, '0');
    } while ((binaryHash.substring(0, difficulty) != zeros));

    return Block(timestamp, lastBlock.hash, hash, transactions, nonce, difficulty);
  }

  // Block.adjustDifficulty(): adjust the difficulty according to the MINE_RATE to keep the network at a steady pace
  static adjustDifficulty(Block lastBlock, int timestamp) {
    if (lastBlock.difficulty < 1) {
      return 1;
    }
    if ((timestamp - lastBlock.timestamp) > MINE_RATE) {
      return lastBlock.difficulty - 1;
    }
    return lastBlock.difficulty + 1;
  }
}
