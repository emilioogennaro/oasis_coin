import 'dart:convert';

import 'package:oasis_coin/blockchain/blockchain.dart';
import 'package:oasis_coin/wallet/wallet.dart';

main(){
    Blockchain blockchain = Blockchain();
    Wallet wallet = Wallet();
    for(int i = 0; i < 3; i++){
        blockchain.addBlock([wallet.createTransaction(0.5, "foo", blockchain.chain)]);
    }
    
    Blockchain newBlockchain = Blockchain();
    var jsonChain = blockchain.toJson();

    newBlockchain.replaceFromJson(jsonChain);

}