import 'package:oasis_coin/blockchain/blockchain.dart';
import 'package:oasis_coin/wallet/transaction-pool.dart';
import 'package:oasis_coin/wallet/transaction.dart';
import 'package:oasis_coin/wallet/wallet.dart';

/*
Miner class
class built to abstract the concept of mining and
to further facilitate programming of the chain and the network
*/
class Miner {
  final Blockchain blockchain;
  final TransactionPool transactionPool;
  final Wallet wallet;

  const Miner(Blockchain blockchain, TransactionPool transactionPool, Wallet wallet)
    : blockchain = blockchain,
    transactionPool = transactionPool,
    wallet = wallet;

  void mineTransactions() {
    // gets only valid transactions from the transaction pool
    List<Transaction> validTransactions = this.transactionPool.getValidTransactions();

    // adds the reward transaction to himself to the valid transactions
    validTransactions.add(Transaction.rewardTransaction(this.wallet));

    // mine and add the block to the chain
    this.blockchain.addBlock(validTransactions);

    // Broadcast chain TO_UPGRADE

    // clears his transaction pool
    this.transactionPool.clear();
  }
}
