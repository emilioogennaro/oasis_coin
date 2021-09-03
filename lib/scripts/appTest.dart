import 'dart:io';
import 'package:oasis_coin/blockchain/blockchain.dart';
import 'package:oasis_coin/networking/network-manager.dart';
import 'package:oasis_coin/wallet/miner.dart';
import 'package:oasis_coin/wallet/transaction-pool.dart';
import 'package:oasis_coin/wallet/wallet.dart';

main() async {
    Blockchain blockchain = Blockchain();
    TransactionPool transactionPool = TransactionPool();
    Wallet wallet = Wallet();
    Miner miner = Miner(blockchain, transactionPool, wallet);
    print("PORT:");
    NetworkManager networkManager = NetworkManager(int.parse(stdin.readLineSync()!));
    
    await Future.delayed(Duration(seconds: 1));
    while(true) {
        print("1: Show full blockchain");
        print("2: Show full transaction pool");
        print("3: Show your public address");
        print("4: Show current balance");
        print("5: Add a transaction to the pool");
        print("6: Mine Transactions");

        int res = int.parse(stdin.readLineSync()!);

        switch(res) {
            case 1:
                print(blockchain.toJson());
                break;
            case 2:
                print(transactionPool.toJson());
                break;
            case 3:
                print(wallet.address);
                break;
            case 4:
                print(wallet.balance);
                break;
            case 5:
                print("Input recipient: ");
                String recipient = stdin.readLineSync().toString();

                print("Input amount: ");
                double amount = double.parse(stdin.readLineSync()!);

                dynamic transaction = transactionPool.exist(wallet.address);

                if(transaction.runtimeType == bool && !transaction){
                    transaction = wallet.createTransaction(amount, recipient, blockchain.chain);
                } else {
                    transaction.update(wallet, recipient, amount);
                }
                print(transaction.toJson());
                transactionPool.addTransaction(transaction);
                networkManager.broadcast(transaction: transaction);
                
                break;
            case 6:
                miner.mineTransactions();
                wallet.updateBalance(blockchain.chain);
                print("pippocase");
                networkManager.broadcast(blockchain: blockchain);
                print("pippoandre");
                break;
        }
    }    
}