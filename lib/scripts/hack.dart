import 'package:oasis_coin/blockchain/block.dart';
import 'package:oasis_coin/blockchain/blockchain.dart';
import 'package:oasis_coin/wallet/transaction.dart';
import 'package:oasis_coin/wallet/wallet.dart';

main(List<String> args) {
    Blockchain blockchain = Blockchain();
    Wallet myWallet = Wallet();

    // Initial Transaction
    blockchain.addBlock([myWallet.createTransaction(1, "foo", blockchain.chain)]);

    late int prevTimestamp, nextTimestamp, timeDiff;
    late double average;
    late Block nextBlock;

    List<int> times = [];
    for(int i = 0; i < 100; i++) {
        prevTimestamp = blockchain.chain.last.timestamp;

        Transaction newTransaction = myWallet.createTransaction(1, "foo", blockchain.chain);
        blockchain.addBlock([newTransaction]);
        nextBlock = blockchain.chain.last;
        nextTimestamp = nextBlock.timestamp;
        timeDiff = nextTimestamp - prevTimestamp;
        times.add(timeDiff);

        average = times.reduce((value, element) => value+element) / times.length;
        //print(blockchain.toJson());
        print("Total blocks: ${blockchain.chain.length}. Time to mine block: ${timeDiff}ms. Difficulty: ${nextBlock.difficulty}. Average time: ${average}ms");
    }

    Blockchain newBlockchain = Blockchain();

    List<Block> corruptedchain = blockchain.chain;
    corruptedchain[4].transactions[0] = myWallet.createTransaction(100, "hacked ;)", corruptedchain);

    blockchain.chain = corruptedchain;
    newBlockchain.replaceChain(blockchain.chain);
}