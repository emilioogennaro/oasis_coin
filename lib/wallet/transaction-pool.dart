import 'package:oasis_coin/blockchain/block.dart';
import 'package:oasis_coin/wallet/transaction.dart';

class TransactionPool {
  Map<String, Transaction> transactionPoolMap = {};

  String toJson() {
    return Transaction.listToJson(transactionPoolMap.values.toList());
  }

  void addTransaction(Transaction transaction) {
    this.transactionPoolMap[transaction.id.toString()] = transaction;
  }

  void setMap(Map<String, Transaction> newTransactionPoolMap) {
    this.transactionPoolMap = newTransactionPoolMap;
  }

  exist(String inputAddress) {
    List<Transaction> transactionsList = this.transactionPoolMap.values.toList();
    try {
      return transactionsList.firstWhere((Transaction transaction) => transaction.input["address"] == inputAddress);
    } catch (StateError) {
      return false;
    }
  }

  List<Transaction> getValidTransactions() {
    List<Transaction> transactionsList = this.transactionPoolMap.values.toList();
    return transactionsList.where((Transaction transaction) =>
            Transaction.verifyTransaction(transaction)).toList();
  }

  void clear() {
    this.transactionPoolMap = {};
  }

  void clearCompletedTransactions(List<Block> chain) {
    for (int i = 1; i < chain.length; i++) {
      Block block = chain[i];

      for (Transaction transaction in block.transactions) {
        if (this.transactionPoolMap.containsKey(transaction.id.toString())) {
          this.transactionPoolMap.remove(transaction.id.toString());
        }
      }
    }
  }
}
