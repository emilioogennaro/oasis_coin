import 'dart:convert';
import 'package:oasis_coin/blockchain/block.dart';
import 'package:oasis_coin/util/util.dart';
import 'package:oasis_coin/wallet/transaction.dart';
import 'package:oasis_coin/wallet/wallet.dart';

/*
Blockchain class
The blockchain class keeps a chronological record of the blocks.
It also is the main center of the security features of the blockchain such as
transaction verification or chain verification.
*/
class Blockchain {
  // every block will be added here
  List<Block> chain = [];

  Blockchain() {
    // genesis block is added at declaration
    this.chain.add(Block.genesis());
  }

  // Blockchain.addBlock(): mine first then add a block containing the transaction list
  // return last block for debug purposes
  Block addBlock(List<Transaction> transactions) {
    Block newBlock = Block.mine(this.chain.last, transactions);
    this.chain.add(newBlock);
    return this.chain.last;
  }

  // Blockchain.toJson(): return a full JSON representation of the entire chain including blocks and transactions
  String toJson() {
    List<String> jsonChain = [];
    for (int i = 0; i < this.chain.length; i++) {
      jsonChain.add('"$i": ' + this.chain[i].toJson());
    }
    String json = jsonChain.toString();
    json = json.substring(1, json.length - 1);
    json = "{ " + json + " }";
    return json;
  }

  // Blockchain.replaceFromJson(): replace the current state of the chain with a new one in JSON String form
  replaceFromJson(String jsonChain) {
    Map chainMap = jsonDecode(jsonChain);

    // convert the JSON to an actual chain
    List<Block> tempChain = [];
    for (var key in chainMap.keys) {
      tempChain.add(Block.fromMap(chainMap[key]));
    }
    // call the actual replaceChain method
    replaceChain(tempChain);
  }

  // Blockchain.replaceChain(): replace the current state of the chain with a new one
  // checking the validity of the chain
  bool replaceChain(List<Block> chain, {onSuccess}) {
    // incoming chain must be longer
    if (chain.length <= this.chain.length) {
      print("[replaceChain] Shorter incoming chain.");
      return false;
    }

    // incoming chain must be valid
    if (!Blockchain.verifyChain(chain)) {
      print("[replaceChain] Invalid incoming chain");
      return false;
    }

    // incoming chain transactions must be valid
    if (!Blockchain.verifyTransactionData(chain)) {
      print("[replaceChain] Invalid transaction data");
      return false;
    }

    print("[replaceChain] Replacing chain");
    this.chain = chain;

    // optional onSuccess function to run when successfully replaced the chain
    if (onSuccess.runtimeType == Function) {
      onSuccess();
    }

    return true;
  }

  // Blockchain.verifyTransactionData(): iterate through all the transactions in a chain
  // checking if every transaction meets the if requirements
  // if even one transaction is marked as invalid the whole chain is considered tampered
  static bool verifyTransactionData(List<Block> chain) {
    for (int i = 1; i < chain.length; i++) {
      // var to keep track of the number of reward transaction in one block
      int rewardTransactionCount = 0;
      // set of transaction to avoid duplicate transaction (same id)
      Set<Transaction> transactionSet = Set<Transaction>();

      for (Transaction transaction in chain[i].transactions) {
        // if the transaction is a reward
        if (transaction.input["address"] == REWARD_INPUT["address"]) {
          rewardTransactionCount++;
          
          // max number of rewards 1, if more found invalid
          if (rewardTransactionCount > 1) {
            print("[verifyTransactionData] Too many miner reward:\nexpected: 1 found: $rewardTransactionCount.");
            return false;
          }
          // if reward amount is different from the actual reward amount, invalid
          if (transaction.outputMap[REWARD_INPUT["address"]] != MINER_REWARD) {
            print("[verifyTransactionData] Invalid miner reward:\nexpected: $MINER_REWARD found: ${transaction.outputMap[REWARD_INPUT['address']]}.");
            return false;
          }
        // if the transaction is not a reward
        } else {
          // if transaction is marked as a invalid, invalid
          if (!Transaction.verifyTransaction(transaction)) {
            print("[verifyTransactionData] Invalid transaction.");
            return false;
          }

          // trueBalance: balance of sender calculated on the whole chain (cannot be tampered)
          double trueBalance = Wallet.calculateBalance(chain, transaction.input["address"], ceil: chain.length - (chain.length - i));
          // check if sender balance == to trueBalance, if not, invalid
          if (transaction.outputMap[transaction.input["address"]] != trueBalance) {
            print('[verifyTransactionData] Invalid input amount:\nexpected: $trueBalance found: ${transaction.input["amount"]}.');
            return false;
          }

          // if two identical transaction are found the chain is marked as invalid
          if (transactionSet.contains(transaction)) {
            print('[verifyTransactionData] Identical transactions appear more than once in the block');
            return false;
          } else {
            // if everything is correct the transaction is added to the set
            // and the loop continue
            transactionSet.add(transaction);
          }
        }
      }
    }
    // return true if no transaction was tampered
    return true;
  }

  // Blockchain.verifyChain(): function that verifies the integrity of the chain
  // meanining no block was modified
  static verifyChain(List<Block> chain) {
    // When the first block is not the genesis block, invalid
    if (chain[0].toJson() != Block.genesis().toJson()) {
      return false;
    }

    for (int i = 1; i < chain.length; i++) {
      // hash of the last block
      String actualLastHash = chain[i - 1].hash;
      // difficulty of the last block
      int lastDifficulty = chain[i - 1].difficulty;

      // When the lastHash is not the hash of the last block, invalid
      if (chain[i].lastHash != actualLastHash) {
        print("[verifyChain] actual last hash not corresponding to lastHash:\nexpected:$actualLastHash found: ${chain[i].lastHash}");
        return false;
      }
      // hash calculated using the values of the block (cannot be tampered)
      String actualHash = sha512(Block(chain[i].timestamp, chain[i].lastHash,"", chain[i].transactions, chain[i].nonce, chain[i].difficulty).toJson(includeHash: false));

      // When the hash of the block is corrupted or data have been modified, invalid
      if (chain[i].hash != actualHash) {
        print(
            "[verifyChain] Block hash not corresponding to data (corrupted or maliciously modified):\nexpected:$actualHash found: ${chain[i].hash}");
        return false;
      }
      // [Know issue] simple difficulty tampering check TO_UPGRADE
      if ((lastDifficulty - chain[i].difficulty).abs() > 1) return false;
    }

    return true;
  }
}
