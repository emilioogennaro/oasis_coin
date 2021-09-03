import 'package:oasis_coin/networking/network-manager.dart';
import 'package:oasis_coin/wallet/miner.dart';
import 'package:oasis_coin/blockchain/blockchain.dart';
import 'package:oasis_coin/wallet/transaction-pool.dart';
import 'package:oasis_coin/wallet/wallet.dart';

main() async {
  Blockchain blockchain = new Blockchain();
  TransactionPool transactionPool = new TransactionPool();
  Wallet wallet = new Wallet();
  Miner miner = new  Miner(blockchain, transactionPool, wallet);
  NetworkManager networkManager5 = new NetworkManager(5000);
  
  NetworkManager networkManager6 = new NetworkManager(6000);
  
  NetworkManager networkManager4 = new NetworkManager(4000);
  
  NetworkManager networkManager3 = new NetworkManager(3000);
  

  miner.mineTransactions();
  await Future.delayed(Duration(seconds: 5));
  networkManager5.broadcast(blockchain: blockchain);
}